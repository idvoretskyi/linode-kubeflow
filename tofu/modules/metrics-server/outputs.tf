output "release_name" {
  description = "Helm release name for metrics-server"
  value       = helm_release.metrics_server.name
}

output "namespace" {
  description = "Namespace where metrics-server is deployed"
  value       = helm_release.metrics_server.namespace
}

output "version" {
  description = "Metrics Server chart version"
  value       = helm_release.metrics_server.version
}

output "status" {
  description = "Status of the Metrics Server Helm release"
  value       = helm_release.metrics_server.status
}

output "validation_commands" {
  description = "Commands to validate Metrics Server functionality"
  value       = <<-EOT
    # Check metrics-server pods
    kubectl get pods -n ${helm_release.metrics_server.namespace} -l app.kubernetes.io/name=metrics-server

    # Test resource metrics API
    kubectl top nodes
    kubectl top pods -A

    # Verify metrics-server API availability
    kubectl get apiservices v1beta1.metrics.k8s.io -o yaml
  EOT
}
