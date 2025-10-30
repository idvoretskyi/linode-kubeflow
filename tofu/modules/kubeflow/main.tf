terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Create namespace for Kubeflow
resource "kubernetes_namespace" "kubeflow" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "kubeflow"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Install Kubeflow using kustomize
resource "null_resource" "install_kubeflow" {
  depends_on = [kubernetes_namespace.kubeflow]

  triggers = {
    kubeflow_version  = var.kubeflow_version
    kubeflow_manifest = var.kubeflow_manifest_url
    install_method    = var.install_method
    always_run        = timestamp() # Force updates
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Installing Kubeflow ${var.kubeflow_version}..."

      # Install based on method
      if [ "${var.install_method}" = "manifests" ]; then
        echo "Using Kubeflow manifests installation..."

        # Clone manifests if not exists
        if [ ! -d "/tmp/kubeflow-manifests" ]; then
          git clone --branch ${var.kubeflow_version} \
            https://github.com/kubeflow/manifests.git \
            /tmp/kubeflow-manifests
        fi

        cd /tmp/kubeflow-manifests

        # Install individual components
        echo "Installing Kubeflow components..."

        # Cert-manager (required)
        kustomize build common/cert-manager/cert-manager/base | kubectl apply -f -
        kubectl wait --for=condition=ready pod -l 'app in (cert-manager,webhook)' \
          --namespace cert-manager --timeout=300s || true

        # Istio (required for networking)
        kustomize build common/istio-1-22/istio-crds/base | kubectl apply -f -
        kustomize build common/istio-1-22/istio-namespace/base | kubectl apply -f -
        kustomize build common/istio-1-22/istio-install/overlays/oauth2-proxy | kubectl apply -f -

        # Dex (authentication)
        kustomize build common/dex/overlays/istio | kubectl apply -f -

        # OIDC AuthService
        kustomize build common/oidc-client/oidc-authservice/overlays/ibm-storage-config | kubectl apply -f -

        # Kubeflow namespace
        kustomize build common/kubeflow-namespace/base | kubectl apply -f -

        # Kubeflow Roles
        kustomize build common/kubeflow-roles/base | kubectl apply -f -

        # Kubeflow Istio Resources
        kustomize build common/istio-1-22/kubeflow-istio-resources/base | kubectl apply -f -

        # Kubeflow Pipelines
        kustomize build apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user | kubectl apply -f -

        # KServe (model serving)
        kustomize build contrib/kserve/kserve | kubectl apply -f -
        kustomize build contrib/kserve/models-web-app/overlays/kubeflow | kubectl apply -f -

        # Katib (hyperparameter tuning)
        kustomize build apps/katib/upstream/installs/katib-with-kubeflow | kubectl apply -f -

        # Central Dashboard
        kustomize build apps/centraldashboard/upstream/overlays/kserve | kubectl apply -f -

        # Admission Webhook
        kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -

        # Notebook Controller
        kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -

        # Jupyter Web App
        kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -

        # Profiles + KFAM
        kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl apply -f -

        # Volumes Web App
        kustomize build apps/volumes-web-app/upstream/overlays/istio | kubectl apply -f -

        # Tensorboards Controller
        kustomize build apps/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -
        kustomize build apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -

        # Training Operator (for distributed training)
        kustomize build apps/training-operator/upstream/overlays/kubeflow | kubectl apply -f -

        # User namespace
        kustomize build common/user-namespace/base | kubectl apply -f -

        echo "Kubeflow installation completed!"

      elif [ "${var.install_method}" = "quick" ]; then
        echo "Using quick installation method..."

        # Single-command installation (all components)
        while ! kustomize build ${var.kubeflow_manifest_url} | kubectl apply -f -; do
          echo "Retrying installation..."
          sleep 5
        done

        echo "Quick Kubeflow installation completed!"
      fi

      # Wait for key components
      echo "Waiting for Kubeflow components to be ready..."
      kubectl wait --for=condition=ready pod -l app=ml-pipeline \
        -n ${var.namespace} --timeout=600s || true

      echo "Kubeflow is ready!"
    EOT

    environment = {
      KUBECONFIG = pathexpand("~/.kube/config")
    }
  }
}

# Create default user profile
resource "null_resource" "create_default_profile" {
  depends_on = [null_resource.install_kubeflow]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait a bit for profiles controller to be ready
      sleep 30

      # Create default user profile
      cat <<EOF | kubectl apply -f -
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: ${var.default_user_profile}
spec:
  owner:
    kind: User
    name: ${var.default_user_email}
  resourceQuotaSpec:
    hard:
      requests.nvidia.com/gpu: "${var.gpu_quota}"
      requests.cpu: "${var.cpu_quota}"
      requests.memory: "${var.memory_quota}"
EOF

      echo "Default user profile '${var.default_user_profile}' created!"
    EOT

    environment = {
      KUBECONFIG = pathexpand("~/.kube/config")
    }
  }
}

# Expose Kubeflow dashboard
resource "kubernetes_service" "kubeflow_gateway_nodeport" {
  count = var.expose_via_nodeport ? 1 : 0

  metadata {
    name      = "istio-ingressgateway-nodeport"
    namespace = "istio-system"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    type = "NodePort"

    selector = {
      app   = "istio-ingressgateway"
      istio = "ingressgateway"
    }

    port {
      name        = "http2"
      port        = 80
      target_port = 8080
      node_port   = var.nodeport_http
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8443
      node_port   = var.nodeport_https
    }
  }
}
