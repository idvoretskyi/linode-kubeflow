variable "namespace" {
  description = "Kubernetes namespace for GPU operator"
  type        = string
  default     = "gpu-operator"
}

variable "gpu_operator_version" {
  description = "Version of NVIDIA GPU Operator Helm chart"
  type        = string
  default     = "v24.9.0" # Latest stable version
}

variable "install_driver" {
  description = "Install NVIDIA driver (set to true for most cloud environments)"
  type        = bool
  default     = true
}

variable "enable_dcgm_exporter" {
  description = "Enable DCGM Exporter for GPU metrics in Prometheus"
  type        = bool
  default     = true
}

variable "enable_node_status_exporter" {
  description = "Enable Node Status Exporter"
  type        = bool
  default     = true
}
