terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Create namespace for GPU operator
resource "kubernetes_namespace" "gpu_operator" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "gpu-operator"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Install NVIDIA GPU Operator via Helm
resource "helm_release" "gpu_operator" {
  name       = "gpu-operator"
  repository = "https://helm.ngc.nvidia.com/nvidia"
  chart      = "gpu-operator"
  version    = var.gpu_operator_version
  namespace  = kubernetes_namespace.gpu_operator.metadata[0].name

  create_namespace = false # Namespace is created by kubernetes_namespace resource
  depends_on       = [kubernetes_namespace.gpu_operator]

  timeout = 600 # 10 minutes

  values = [
    yamlencode({
      operator = {
        defaultRuntime = "containerd"
      }
      driver = {
        enabled = var.install_driver
      }
      toolkit = {
        enabled = true
      }
      devicePlugin = {
        enabled = true
      }
      dcgmExporter = {
        enabled = var.enable_dcgm_exporter
      }
      gfd = {
        enabled = true
      }
      migManager = {
        enabled = false # Not needed for RTX 4000 Ada
      }
      nodeStatusExporter = {
        enabled = var.enable_node_status_exporter
      }
      validator = {
        plugin = {
          env = [
            {
              name  = "WITH_WORKLOAD"
              value = "true"
            }
          ]
        }
      }
    })
  ]

  wait          = true
  wait_for_jobs = true
}

# Wait for GPU operator to be fully ready
resource "null_resource" "wait_for_gpu_operator" {
  depends_on = [helm_release.gpu_operator]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for GPU operator pods to be ready..."
      kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/component=gpu-operator \
        -n ${kubernetes_namespace.gpu_operator.metadata[0].name} \
        --timeout=600s || true

      echo "Waiting for nvidia-driver-daemonset..."
      kubectl wait --for=condition=ready pod \
        -l app=nvidia-driver-daemonset \
        -n ${kubernetes_namespace.gpu_operator.metadata[0].name} \
        --timeout=600s || true

      echo "GPU Operator installation complete!"
    EOT
  }
}
