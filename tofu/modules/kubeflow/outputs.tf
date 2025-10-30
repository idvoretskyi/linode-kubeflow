output "namespace" {
  description = "The namespace where Kubeflow is installed"
  value       = kubernetes_namespace.kubeflow.metadata[0].name
}

output "kubeflow_version" {
  description = "The version of Kubeflow installed"
  value       = var.kubeflow_version
}

output "default_user_profile" {
  description = "The default user profile name"
  value       = var.default_user_profile
}

output "access_commands" {
  description = "Commands to access Kubeflow"
  value       = <<-EOT
    # Check Kubeflow pods status
    kubectl get pods -n ${var.namespace}

    # Get Istio Ingress Gateway service
    kubectl get svc istio-ingressgateway -n istio-system

    # Port-forward to access Kubeflow UI locally
    kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80

    # Then access: http://localhost:8080

    # Default credentials (if using Dex):
    # Email: user@example.com
    # Password: 12341234

    # Get external IP (if LoadBalancer):
    kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

    ${var.expose_via_nodeport ? "# NodePort access enabled on ports: ${var.nodeport_http} (HTTP), ${var.nodeport_https} (HTTPS)" : ""}
  EOT
}

output "nodeport_urls" {
  description = "NodePort URLs for Kubeflow access (if enabled)"
  value = var.expose_via_nodeport ? {
    http  = "http://<node-ip>:${var.nodeport_http}"
    https = "https://<node-ip>:${var.nodeport_https}"
  } : null
}

output "gpu_quota" {
  description = "GPU quota configured for default user"
  value       = var.gpu_quota
}

output "validation_commands" {
  description = "Commands to validate Kubeflow installation"
  value       = <<-EOT
    # Check all Kubeflow components
    kubectl get pods -A | grep kubeflow

    # Check Kubeflow pipelines
    kubectl get pods -n ${var.namespace} | grep ml-pipeline

    # Check notebook controller
    kubectl get pods -n ${var.namespace} | grep notebook-controller

    # Create a test notebook
    kubectl apply -f - <<EOF
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  name: test-notebook
  namespace: ${var.default_user_profile}
spec:
  template:
    spec:
      containers:
      - name: notebook
        image: public.ecr.aws/j1r0q0g6/notebooks/notebook-servers/jupyter-tensorflow-cuda-full:v1.9.0
        resources:
          limits:
            nvidia.com/gpu: "1"
          requests:
            cpu: "1"
            memory: "2Gi"
EOF

    # Check the notebook pod
    kubectl get pods -n ${var.default_user_profile}
  EOT
}
