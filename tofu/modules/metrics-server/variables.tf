variable "namespace" {
  description = "Kubernetes namespace for metrics-server"
  type        = string
  default     = "kube-system"
}

variable "metrics_server_version" {
  description = "Version of Metrics Server Helm chart"
  type        = string
  default     = "3.12.2"
}
