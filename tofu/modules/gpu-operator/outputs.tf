output "namespace" {
  description = "The namespace where GPU operator is installed"
  value       = kubernetes_namespace.gpu_operator.metadata[0].name
}

output "gpu_operator_version" {
  description = "The version of GPU operator installed"
  value       = helm_release.gpu_operator.version
}

output "gpu_operator_status" {
  description = "The status of the GPU operator Helm release"
  value       = helm_release.gpu_operator.status
}

output "validation_commands" {
  description = "Commands to validate GPU availability"
  value       = <<-EOT
    # Check GPU operator pods
    kubectl get pods -n ${kubernetes_namespace.gpu_operator.metadata[0].name}

    # Verify GPU devices are detected
    kubectl get nodes -o json | jq '.items[].status.capacity."nvidia.com/gpu"'

    # Run GPU test workload
    kubectl run gpu-test --rm -it --restart=Never \
      --image=nvidia/cuda:12.2.0-base-ubuntu22.04 \
      --limits=nvidia.com/gpu=1 \
      -- nvidia-smi

    # Check DCGM metrics (if enabled)
    kubectl get pods -n ${kubernetes_namespace.gpu_operator.metadata[0].name} -l app=nvidia-dcgm-exporter
  EOT
}
