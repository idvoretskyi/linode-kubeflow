terraform {
  required_version = ">= 1.6"

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

# Provider will automatically use LINODE_TOKEN environment variable
# Set via: export LINODE_TOKEN=$(linode-cli configure get token)
provider "linode" {
  # token is read from LINODE_TOKEN environment variable
}

# Kubernetes provider for managing K8s resources
# Uses the merged kubeconfig from ~/.kube/config
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Helm provider for installing charts
# Uses the merged kubeconfig from ~/.kube/config
# Note: Helm v2.x uses kubernetes block, v3.x+ just inherits from default kubeconfig
provider "helm" {}

# Determine cluster name prefix (use provided value or system username)
locals {
  cluster_prefix = var.cluster_name_prefix != "" ? var.cluster_name_prefix : replace(lower(data.external.username.result.username), "/[^a-z0-9-]/", "-")
}

# Get system username if cluster_name_prefix is not set
data "external" "username" {
  program = ["sh", "-c", "echo '{\"username\":\"'$(whoami)'\"}'"]
}

# LKE Cluster with GPU nodes
resource "linode_lke_cluster" "gpu_cluster" {
  label       = "${local.cluster_prefix}-lke-gpu-kubeflow"
  k8s_version = var.kubernetes_version
  region      = var.region
  tags        = var.tags

  pool {
    type  = var.gpu_node_type
    count = var.gpu_node_count

    autoscaler {
      min = var.autoscaler_min
      max = var.autoscaler_max
    }
  }

  control_plane {
    high_availability = var.ha_control_plane
  }
}

# Merge kubeconfig into ~/.kube/config (no local file storage)
resource "null_resource" "merge_kubeconfig" {
  triggers = {
    kubeconfig_content = base64decode(linode_lke_cluster.gpu_cluster.kubeconfig)
    cluster_id         = linode_lke_cluster.gpu_cluster.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create ~/.kube directory if it doesn't exist
      mkdir -p ~/.kube

      # Backup existing config if it exists
      if [ -f ~/.kube/config ]; then
        cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d-%H%M%S)
      fi

      # Write kubeconfig to temporary file
      TEMP_KUBECONFIG=$(mktemp)
      cat > $TEMP_KUBECONFIG << 'KUBECONFIGEOF'
${base64decode(linode_lke_cluster.gpu_cluster.kubeconfig)}
KUBECONFIGEOF
      chmod 600 $TEMP_KUBECONFIG

      # Merge the new kubeconfig
      KUBECONFIG=~/.kube/config:$TEMP_KUBECONFIG kubectl config view --flatten > ~/.kube/config.tmp
      mv ~/.kube/config.tmp ~/.kube/config
      chmod 600 ~/.kube/config

      # Clean up temporary file
      rm -f $TEMP_KUBECONFIG

      # Set the new context as active
      kubectl config use-context lke${linode_lke_cluster.gpu_cluster.id}-ctx

      echo "✓ Kubeconfig merged into ~/.kube/config"
      echo "✓ Context 'lke${linode_lke_cluster.gpu_cluster.id}-ctx' is now active"
      echo "✓ No local kubeconfig file created (stored in ~/.kube/config only)"
    EOT
  }
}

# Firewall for LKE cluster
resource "linode_firewall" "lke_firewall" {
  label = "${local.cluster_prefix}-lke-firewall"
  tags  = var.tags

  inbound {
    label    = "allow-kubectl"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = var.allowed_kubectl_ips
  }

  inbound {
    label    = "allow-kubeflow-ui"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80,443"
    ipv4     = var.allowed_kubeflow_ui_ips
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  linodes = [for node in linode_lke_cluster.gpu_cluster.pool[0].nodes : node.instance_id]

  depends_on = [linode_lke_cluster.gpu_cluster]
}

# GPU Operator Module (Phase 2)
module "gpu_operator" {
  count  = var.install_gpu_operator ? 1 : 0
  source = "./modules/gpu-operator"

  namespace                   = "gpu-operator"
  gpu_operator_version        = var.gpu_operator_version
  install_driver              = true
  enable_dcgm_exporter        = var.enable_gpu_monitoring
  enable_node_status_exporter = true

  depends_on = [
    linode_lke_cluster.gpu_cluster,
    null_resource.merge_kubeconfig
  ]
}

# Kubeflow Module (Phase 2)
module "kubeflow" {
  count  = var.install_kubeflow ? 1 : 0
  source = "./modules/kubeflow"

  namespace            = "kubeflow"
  kubeflow_version     = var.kubeflow_version
  install_method       = var.kubeflow_install_method
  default_user_email   = var.kubeflow_user_email
  default_user_profile = "kubeflow-user"
  gpu_quota            = "4"
  cpu_quota            = "16"
  memory_quota         = "64Gi"
  expose_via_nodeport  = var.kubeflow_expose_nodeport
  nodeport_http        = 30080
  nodeport_https       = 30443

  depends_on = [
    module.gpu_operator,
    linode_lke_cluster.gpu_cluster,
    null_resource.merge_kubeconfig
  ]
}
