# Linode Kubeflow Terraform Modules

This directory contains reusable Terraform modules for deploying GPU workloads and Kubeflow on Linode Kubernetes Engine (LKE).

## Module Overview

### 1. GPU Operator Module (`gpu-operator/`)

Installs the NVIDIA GPU Operator, which provides:
- NVIDIA GPU drivers
- CUDA runtime
- GPU device plugin for Kubernetes
- GPU monitoring (DCGM exporter)
- GPU Feature Discovery

**Key Features:**
- Automatic driver installation
- GPU metrics for Prometheus
- Validation workloads
- Node status monitoring

**Usage:**
```hcl
module "gpu_operator" {
  source = "./modules/gpu-operator"

  namespace                    = "gpu-operator"
  gpu_operator_version         = "v24.9.0"
  install_driver               = true
  enable_dcgm_exporter         = true
  enable_node_status_exporter  = true
}
```

**Outputs:**
- `namespace` - GPU operator namespace
- `gpu_operator_version` - Installed version
- `gpu_operator_status` - Helm release status
- `validation_commands` - Commands to test GPU functionality

### 2. Kubeflow Module (`kubeflow/`)

Installs the Kubeflow ML platform with all core components:
- Central Dashboard
- Jupyter Notebooks with GPU support
- Kubeflow Pipelines
- Katib (hyperparameter tuning)
- KServe (model serving)
- Training Operator (distributed training)
- Istio (service mesh)
- Dex (authentication)

**Key Features:**
- Full ML platform deployment
- GPU-accelerated notebooks
- Pipeline orchestration
- Model serving infrastructure
- User profile management with resource quotas

**Usage:**
```hcl
module "kubeflow" {
  source = "./modules/kubeflow"

  namespace               = "kubeflow"
  kubeflow_version        = "v1.9.0"
  install_method          = "manifests"
  default_user_email      = "user@example.com"
  gpu_quota               = "4"
  cpu_quota               = "16"
  memory_quota            = "64Gi"
  expose_via_nodeport     = false
}
```

**Outputs:**
- `namespace` - Kubeflow namespace
- `kubeflow_version` - Installed version
- `default_user_profile` - Default user profile name
- `access_commands` - Commands to access Kubeflow UI
- `validation_commands` - Commands to test Kubeflow

## Deployment Phases

### Phase 1: Infrastructure (Required)
Deploy the base LKE cluster with GPU nodes:
```bash
tofu apply
```

### Phase 2: GPU Operator (Recommended)
Enable GPU support:
```bash
tofu apply -var="install_gpu_operator=true"
```

Wait for GPU operator to be ready (~5-10 minutes), then verify:
```bash
kubectl get pods -n gpu-operator
kubectl get nodes -o json | jq '.items[].status.capacity."nvidia.com/gpu"'
```

### Phase 3: Kubeflow (Optional)
Deploy the full ML platform:
```bash
tofu apply -var="install_gpu_operator=true" -var="install_kubeflow=true"
```

**Warning:** Kubeflow installation takes 15-30 minutes and requires:
- GPU operator already installed
- Stable cluster with sufficient resources
- Patience during component initialization

## Installation Methods

### Manifests Method (Recommended)
Installs Kubeflow components one by one:
- More reliable
- Better error handling
- Easier troubleshooting
- Longer installation time (~20-30 minutes)

```hcl
kubeflow_install_method = "manifests"
```

### Quick Method
Installs all components at once:
- Faster installation (~10-15 minutes)
- Less granular control
- May require retries

```hcl
kubeflow_install_method = "quick"
```

## Resource Quotas

Default user profile quotas:
- **GPUs:** 4
- **CPUs:** 16
- **Memory:** 64Gi

Customize in module call:
```hcl
module "kubeflow" {
  # ...
  gpu_quota    = "8"
  cpu_quota    = "32"
  memory_quota = "128Gi"
}
```

## Accessing Kubeflow

### Method 1: Port Forward (Recommended for Development)
```bash
kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80
# Visit: http://localhost:8080
```

### Method 2: NodePort (Testing)
Enable in configuration:
```hcl
kubeflow_expose_nodeport = true
nodeport_http            = 30080
nodeport_https           = 30443
```

Access via: `http://<node-ip>:30080`

### Method 3: LoadBalancer (Production)
Get external IP:
```bash
kubectl get svc istio-ingressgateway -n istio-system
```

## Default Credentials

When using Dex authentication:
- **Email:** `user@example.com` (or your configured email)
- **Password:** `12341234`

## Monitoring

GPU metrics are exposed via DCGM exporter when enabled:
```bash
kubectl get pods -n gpu-operator -l app=nvidia-dcgm-exporter
kubectl port-forward -n gpu-operator svc/nvidia-dcgm-exporter 9400:9400
# Metrics at: http://localhost:9400/metrics
```

## Troubleshooting

### GPU Not Detected
```bash
# Check GPU operator pods
kubectl get pods -n gpu-operator

# Check driver installation
kubectl logs -n gpu-operator -l app=nvidia-driver-daemonset

# Verify GPU on nodes
kubectl describe nodes | grep -A 5 Capacity
```

### Kubeflow Installation Stuck
```bash
# Check component status
kubectl get pods -A | grep -E "kubeflow|istio|cert-manager"

# Check specific namespace
kubectl get pods -n kubeflow
kubectl describe pod <pod-name> -n kubeflow

# Re-run installation
tofu apply -replace="module.kubeflow[0].null_resource.install_kubeflow"
```

### Can't Access Kubeflow UI
```bash
# Check Istio gateway
kubectl get svc -n istio-system

# Check ingress gateway pods
kubectl get pods -n istio-system -l app=istio-ingressgateway

# Port forward troubleshooting
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
```

## Module Dependencies

```
linode_lke_cluster
    └─> local_file.kubeconfig
        └─> module.gpu_operator
            └─> module.kubeflow
```

**Important:**
- GPU Operator must be fully ready before installing Kubeflow
- Kubeflow depends on GPU operator for GPU-accelerated workloads
- Allow 5-10 minutes between GPU operator and Kubeflow installation

## Cost Considerations

Approximate monthly costs (us-ord region):
- **Base cluster:** $2,160-2,880 (2x RTX 4000 Ada nodes)
- **GPU Operator:** Free (software only)
- **Kubeflow:** Free (software only)
- **Additional storage:** Variable (PVCs for notebooks, models)

## References

- [NVIDIA GPU Operator Documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)
- [Kubeflow Documentation](https://www.kubeflow.org/docs/)
- [Linode Kubernetes Engine](https://www.linode.com/docs/products/compute/kubernetes/)
- [Kubeflow Manifests Repository](https://github.com/kubeflow/manifests)
