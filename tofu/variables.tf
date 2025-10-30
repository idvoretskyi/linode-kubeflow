variable "cluster_name_prefix" {
  description = "Prefix for the LKE cluster name (will use system username if not set)"
  type        = string
  default     = ""
}

variable "region" {
  description = "Linode region for the cluster"
  type        = string
  default     = "us-ord" # Chicago, US
}

variable "kubernetes_version" {
  description = "Kubernetes version for the LKE cluster"
  type        = string
  default     = "1.34" # Latest stable version, adjust as needed
}

variable "gpu_node_type" {
  description = "Linode instance type for GPU nodes (NVIDIA RTX 4000 Ada GPU x1 Small)"
  type        = string
  default     = "g2-gpu-rtx4000a1-s" # RTX4000 Ada x1 Small

  # Note: Check available GPU plans with: linode-cli linodes types --json | jq '.[] | select(.class=="gpu")'
}

variable "gpu_node_count" {
  description = "Number of GPU nodes in the cluster"
  type        = number
  default     = 1
}

variable "autoscaler_min" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 1
}

variable "autoscaler_max" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 5
}

variable "ha_control_plane" {
  description = "Enable high availability for the control plane"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = ["kubeflow", "gpu", "ml"]
}

variable "allowed_kubectl_ips" {
  description = "IP addresses allowed to access kubectl API"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Consider restricting this in production
}

variable "allowed_kubeflow_ui_ips" {
  description = "IP addresses allowed to access Kubeflow UI"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Consider restricting this in production
}

# GPU Operator Configuration
variable "install_gpu_operator" {
  description = "Install NVIDIA GPU Operator"
  type        = bool
  default     = true
}

variable "gpu_operator_version" {
  description = "Version of NVIDIA GPU Operator"
  type        = string
  default     = "v24.9.0"
}

variable "enable_gpu_monitoring" {
  description = "Enable GPU monitoring with DCGM exporter"
  type        = bool
  default     = true
}

# Kubeflow Configuration
variable "install_kubeflow" {
  description = "Install Kubeflow platform"
  type        = bool
  default     = false # Disabled by default, can be enabled when needed
}

variable "kubeflow_version" {
  description = "Kubeflow version to install"
  type        = string
  default     = "v1.9.0"
}

variable "kubeflow_install_method" {
  description = "Kubeflow installation method: 'manifests' or 'quick'"
  type        = string
  default     = "manifests"
}

variable "kubeflow_user_email" {
  description = "Default user email for Kubeflow"
  type        = string
  default     = "user@example.com"
}

variable "kubeflow_expose_nodeport" {
  description = "Expose Kubeflow UI via NodePort"
  type        = bool
  default     = false
}
