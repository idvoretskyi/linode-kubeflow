# Deployment Guide

## Prerequisites

Ensure all required tools are installed:

- OpenTofu >= 1.6
- kubectl (Kubernetes CLI)
- linode-cli (configured with API token)
- jq (JSON processor)
- helm (optional, for GPU operator)

### Verify Prerequisites

```bash
./setup.sh
```

This script checks all dependencies and guides you through any missing configuration.

## Quick Deployment

For a standard deployment with default settings:

```bash
# 1. Check prerequisites
./setup.sh

# 2. Deploy cluster
./deploy.sh

# 3. Configure kubectl
export KUBECONFIG=$(cd tofu && tofu output -raw kubeconfig_path)

# 4. Verify cluster
kubectl get nodes
```

The full deployment takes approximately 10-15 minutes.

## Step-by-Step Deployment

### Step 1: Initialize OpenTofu

```bash
./deploy.sh init
```

This downloads required OpenTofu providers and initializes the working directory.

### Step 2: Review Configuration

Optionally customize settings:

```bash
cd tofu
cp tofu.tfvars.example tofu.tfvars
# Edit tofu.tfvars with your preferences
cd ..
```

See [Configuration Guide](configuration.md) for available options.

### Step 3: Review Deployment Plan

```bash
./deploy.sh plan
```

This shows what resources will be created without making any changes.

### Step 4: Apply Configuration

```bash
./deploy.sh apply
```

Confirm the deployment when prompted. This creates:
- LKE cluster with HA control plane
- GPU node pool with autoscaling
- Firewall rules
- Kubeconfig file

### Step 5: Configure kubectl

```bash
export KUBECONFIG=$(cd tofu && tofu output -raw kubeconfig_path)
kubectl get nodes
```

Nodes should show as `Ready` within a few minutes.

### Step 6: Verify GPU Availability

```bash
./deploy.sh gpu-check
```

This displays GPU capacity on each node.

## Deployment Commands Reference

The `deploy.sh` script supports individual operations:

```bash
./deploy.sh init          # Initialize OpenTofu
./deploy.sh validate      # Validate configuration
./deploy.sh plan          # Show execution plan
./deploy.sh apply         # Deploy infrastructure
./deploy.sh status        # Show cluster status
./deploy.sh gpu-check     # Verify GPU availability
./deploy.sh destroy       # Destroy infrastructure
./deploy.sh clean         # Clean temporary files
./deploy.sh help          # Show all commands
```

## Post-Deployment Steps

### Install NVIDIA GPU Operator

If GPUs are not automatically detected:

```bash
./deploy.sh install-nvidia
```

Verify installation:

```bash
kubectl get pods -n gpu-operator
kubectl describe nodes | grep nvidia.com/gpu
```

### Configure Persistent Storage

Check available storage classes:

```bash
kubectl get storageclass
```

LKE provides Linode Block Storage integration by default.

### Set Up Monitoring

Install monitoring stack (optional):

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus prometheus-community/kube-prometheus-stack
```

## Cluster Management

### Scale Node Pool

Edit `tofu/tofu.tfvars`:

```hcl
gpu_node_count = 3
```

Apply changes:

```bash
./deploy.sh apply
```

### Update Kubernetes Version

Edit `tofu/tofu.tfvars`:

```hcl
```bash
# Update Kubernetes version in tofu.tfvars
kubernetes_version = "1.35"

# Apply the update
```

Apply changes:

```bash
./deploy.sh apply
```

**Note**: Review Kubernetes upgrade notes before changing versions.

### Modify Firewall Rules

Edit `tofu/tofu.tfvars`:

```hcl
allowed_kubectl_ips = ["YOUR_IP/32"]
allowed_kubeflow_ui_ips = ["YOUR_IP/32"]
```

Apply changes:

```bash
./deploy.sh apply
```

## Destroying Infrastructure

To completely remove all resources:

```bash
./deploy.sh destroy
```

Confirm when prompted. This:
- Deletes the LKE cluster
- Removes all nodes
- Deletes firewall rules
- Preserves OpenTofu state for reference

Clean up local files:

```bash
./deploy.sh clean
```

## Troubleshooting Deployment

### Initialization Fails

```bash
# Clean and retry
./deploy.sh clean
./deploy.sh init
```

### Apply Fails with State Lock

```bash
# Check for stale locks
cd tofu
tofu force-unlock <lock-id>
```

### Node Pool Not Creating

Check Linode service status and GPU availability in your region:

```bash
linode-cli linodes types --format "id,label,gpus" | grep gpu
linode-cli regions list
```

### Firewall Access Issues

Verify your current IP:

```bash
curl -s https://api.ipify.org
```

Update firewall rules in `tofu/tofu.tfvars` and reapply.

### Kubeconfig Not Generated

```bash
cd tofu
tofu output kubeconfig_path
```

If output is empty, the cluster may still be provisioning. Wait and retry.

## Best Practices

1. **Version Control**: Commit `tofu.tfvars.example` but never `tofu.tfvars` (contains your configuration)
2. **State Management**: Keep OpenTofu state secure; consider remote state for teams
3. **Cost Monitoring**: GPU instances are expensive; destroy when not in use
4. **Security**: Always restrict firewall rules to specific IPs in production
5. **Backups**: Regularly backup critical cluster data and configurations
