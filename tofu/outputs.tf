output "cluster_id" {
  description = "The ID of the LKE cluster"
  value       = linode_lke_cluster.gpu_cluster.id
}

output "cluster_label" {
  description = "The label of the LKE cluster"
  value       = linode_lke_cluster.gpu_cluster.label
}

output "cluster_region" {
  description = "The region where the cluster is deployed"
  value       = linode_lke_cluster.gpu_cluster.region
}

output "kubernetes_version" {
  description = "The Kubernetes version running on the cluster"
  value       = linode_lke_cluster.gpu_cluster.k8s_version
}

output "api_endpoints" {
  description = "The API endpoints for the cluster"
  value       = linode_lke_cluster.gpu_cluster.api_endpoints
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = "~/.kube/config (merged)"
}

output "cluster_dashboard_url" {
  description = "URL to the cluster dashboard"
  value       = linode_lke_cluster.gpu_cluster.dashboard_url
}

output "gpu_node_pool_id" {
  description = "The ID of the GPU node pool"
  value       = linode_lke_cluster.gpu_cluster.pool[0].id
}

output "gpu_node_pool_count" {
  description = "Number of nodes in the GPU pool"
  value       = linode_lke_cluster.gpu_cluster.pool[0].count
}

output "firewall_id" {
  description = "The ID of the firewall protecting the cluster"
  value       = linode_firewall.lke_firewall.id
}

output "kubectl_context" {
  description = "The kubectl context name for this cluster"
  value       = "lke${linode_lke_cluster.gpu_cluster.id}-ctx"
}

output "gpu_operator_namespace" {
  description = "GPU operator namespace (if installed)"
  value       = var.install_gpu_operator ? module.gpu_operator[0].namespace : null
}

output "gpu_operator_status" {
  description = "GPU operator status (if installed)"
  value       = var.install_gpu_operator ? module.gpu_operator[0].gpu_operator_status : null
}

output "kubeflow_namespace" {
  description = "Kubeflow namespace (if installed)"
  value       = var.install_kubeflow ? module.kubeflow[0].namespace : null
}

output "kubeflow_version_installed" {
  description = "Kubeflow version installed (if installed)"
  value       = var.install_kubeflow ? module.kubeflow[0].kubeflow_version : null
}

output "setup_commands" {
  description = "Commands to set up kubectl access"
  value       = <<-EOT
    # Kubeconfig has been automatically merged into ~/.kube/config
    # Context: lke${linode_lke_cluster.gpu_cluster.id}-ctx

    # Switch to this cluster context (if not already active)
    kubectl config use-context lke${linode_lke_cluster.gpu_cluster.id}-ctx

    # Verify cluster access
    kubectl get nodes

    ${var.install_gpu_operator ? "# GPU Operator installed - Check GPU availability\n    kubectl get nodes -o json | jq '.items[].status.capacity.\"nvidia.com/gpu\"'\n    kubectl get pods -n gpu-operator" : "# GPU Operator not installed - Run: tofu apply -var=\"install_gpu_operator=true\""}

    ${var.install_kubeflow ? "# Kubeflow installed - Access the dashboard\n    kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80\n    # Then visit: http://localhost:8080\n    # Default credentials: user@example.com / 12341234" : "# Kubeflow not installed - Run: tofu apply -var=\"install_kubeflow=true\""}
  EOT
}

output "gpu_validation_commands" {
  description = "Commands to validate GPU setup (if GPU operator installed)"
  value       = var.install_gpu_operator ? module.gpu_operator[0].validation_commands : "GPU Operator not installed"
}

output "kubeflow_access_commands" {
  description = "Commands to access Kubeflow (if installed)"
  value       = var.install_kubeflow ? module.kubeflow[0].access_commands : "Kubeflow not installed"
}
