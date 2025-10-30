variable "namespace" {
  description = "Kubernetes namespace for Kubeflow"
  type        = string
  default     = "kubeflow"
}

variable "kubeflow_version" {
  description = "Kubeflow version to install (git branch/tag)"
  type        = string
  default     = "v1.9.0"
}

variable "kubeflow_manifest_url" {
  description = "URL to Kubeflow manifests for kustomize"
  type        = string
  default     = "github.com/kubeflow/manifests/example?ref=v1.9.0"
}

variable "install_method" {
  description = "Installation method: 'manifests' (component-by-component) or 'quick' (all-in-one)"
  type        = string
  default     = "manifests"
  validation {
    condition     = contains(["manifests", "quick"], var.install_method)
    error_message = "install_method must be either 'manifests' or 'quick'"
  }
}

variable "default_user_profile" {
  description = "Default user profile name"
  type        = string
  default     = "kubeflow-user"
}

variable "default_user_email" {
  description = "Default user email for Kubeflow"
  type        = string
  default     = "user@example.com"
}

variable "gpu_quota" {
  description = "GPU quota for default user profile"
  type        = string
  default     = "4"
}

variable "cpu_quota" {
  description = "CPU quota for default user profile"
  type        = string
  default     = "16"
}

variable "memory_quota" {
  description = "Memory quota for default user profile"
  type        = string
  default     = "64Gi"
}

variable "expose_via_nodeport" {
  description = "Expose Kubeflow UI via NodePort (useful for development)"
  type        = bool
  default     = false
}

variable "nodeport_http" {
  description = "NodePort for HTTP access (30000-32767)"
  type        = number
  default     = 30080
}

variable "nodeport_https" {
  description = "NodePort for HTTPS access (30000-32767)"
  type        = number
  default     = 30443
}
