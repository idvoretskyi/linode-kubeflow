# Configuration

## Overview

The deployment uses sensible defaults suitable for GPU-accelerated ML workloads. All configuration is managed through OpenTofu variables.

## API Token Configuration

The Linode API token is automatically loaded from `linode-cli` configuration:

```bash
# Configure linode-cli
linode-cli configure

# Verify configuration
linode-cli configure get token
```

The deployment scripts automatically use the configured token via environment variable.

## Custom Configuration

Create `tofu/tofu.tfvars` to customize deployment parameters:

```hcl
# cluster_name_prefix      = "my-cluster"  # Optional: defaults to your username
region                   = "us-ord"
kubernetes_version       = "1.34"
gpu_node_type            = "g1-gpu-rtx6000-1"
gpu_node_count           = 2
autoscaler_min           = 1
autoscaler_max           = 5
ha_control_plane         = true
allowed_kubectl_ips      = ["0.0.0.0/0"]
allowed_kubeflow_ui_ips  = ["0.0.0.0/0"]
tags                     = ["kubeflow", "gpu", "ml"]
```

## Configuration Variables

### Cluster Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `cluster_name_prefix` | string | Prefix for cluster name | `""` (uses username) |
| `region` | string | Linode region code | `us-ord` |
| `kubernetes_version` | string | Kubernetes version | `1.34` |
| `ha_control_plane` | bool | Enable HA control plane | `true` |
| `tags` | list(string) | Resource tags | `["kubeflow", "gpu"]` |

### Node Pool Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `gpu_node_type` | string | Linode instance type | `g1-gpu-rtx6000-1` |
| `gpu_node_count` | number | Initial node count | `2` |
| `autoscaler_min` | number | Minimum nodes | `1` |
| `autoscaler_max` | number | Maximum nodes | `5` |

### Security Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `allowed_kubectl_ips` | list(string) | IPs allowed for kubectl access | `["0.0.0.0/0"]` |
| `allowed_kubeflow_ui_ips` | list(string) | IPs allowed for UI access | `["0.0.0.0/0"]` |

**Security Note**: The default `0.0.0.0/0` allows access from any IP. For production deployments, restrict to specific IP ranges:

```hcl
allowed_kubectl_ips     = ["YOUR_IP/32"]
allowed_kubeflow_ui_ips = ["YOUR_IP/32"]
```

## Available Linode Regions

Common Linode regions for GPU instances:

| Region Code | Location | Notes |
|------------|----------|-------|
| `us-ord` | Chicago, IL | Default, good latency for North America |
| `us-east` | Newark, NJ | East coast US |
| `us-west` | Fremont, CA | West coast US |
| `eu-central` | Frankfurt, Germany | European deployments |
| `ap-south` | Singapore | Asia-Pacific deployments |

Check current GPU availability: `linode-cli linodes types --format "id,label,gpus,price.hourly" --json`

## GPU Instance Types

| Instance Type | GPU | vCPU | Memory | Storage | Hourly Cost |
|--------------|-----|------|--------|---------|-------------|
| `g1-gpu-rtx6000-1` | 1x RTX 4000 Ada | 4 | 16 GB | 512 GB | ~$1.50-2.00 |

Note: Pricing may vary by region. Check [Linode Pricing](https://www.linode.com/pricing/) for current rates.

## Updating Configuration

After modifying `tofu/tofu.tfvars`:

```bash
# Review changes
./deploy.sh plan

# Apply changes
./deploy.sh apply
```

OpenTofu will show exactly what changes will be made before applying them.

## Environment Variables

The deployment scripts support these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `LINODE_TOKEN` | Linode API token | From `linode-cli` config |
| `KUBECONFIG` | Kubernetes config path | From OpenTofu output |

Example:

```bash
# Override token
export LINODE_TOKEN="your-token-here"
./deploy.sh apply

# Use custom kubeconfig location
export KUBECONFIG="$HOME/.kube/lke-kubeflow"
kubectl get nodes
```
