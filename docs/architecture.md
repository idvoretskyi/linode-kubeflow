# Architecture

## Infrastructure Overview

The deployment creates a GPU-enabled Kubernetes cluster on Linode Kubernetes Engine (LKE) with high availability control plane and autoscaling GPU node pool.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                          Akamai/Linode Cloud                            │
│                         Chicago, IL (us-ord)                             │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                  LKE Cluster: <prefix>-lke-gpu-kubeflow         │   │
│  │                                                                   │   │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │         High Availability Control Plane         │  │  │
│  │  │         (Managed by Linode)                     │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │           GPU Node Pool (Auto-scaling)          │  │
│  │  │                                                   │  │
│  │  │  ┌─────────────┐  ┌─────────────┐               │  │
│  │  │  │   GPU Node  │  │   GPU Node  │    (1-5)      │  │
│  │  │  │  RTX 4000   │  │  RTX 4000   │               │  │
│  │  │  │  4 vCPU     │  │  4 vCPU     │               │  │
│  │  │  │  16 GB RAM  │  │  16 GB RAM  │               │  │
│  │  │  │  512 GB SSD │  │  512 GB SSD │               │  │
│  │  │  └─────────────┘  └─────────────┘               │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │              Kubeflow Platform                   │  │
│  │  │         (Phase 2 - Coming Soon)                  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   Firewall Rules                       │  │
│  │  • kubectl API access (443)                           │  │
│  │  • Kubeflow UI access (80, 443)                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Components

### LKE Cluster
- **Name**: `<username>-lke-gpu-kubeflow` (customizable via `cluster_name_prefix`)
- **Region**: Chicago, IL (us-ord)
- **Kubernetes Version**: 1.34 (configurable)
- **Control Plane**: High Availability enabled (managed by Linode)

### GPU Node Pool
- **Instance Type**: g1-gpu-rtx6000-1
- **GPU**: NVIDIA RTX 4000 Ada (1 GPU per node)
- **CPU**: 4 vCPU cores per node
- **Memory**: 16 GB RAM per node
- **Storage**: 512 GB SSD per node
- **Autoscaling**: 1-5 nodes (configurable)

### Networking
- **CNI**: Calico (default for LKE)
- **Load Balancer**: Linode NodeBalancer
- **Firewall**: Custom rules for API and UI access
- **Service CIDR**: Managed by LKE
- **Pod CIDR**: Managed by LKE

### Security
- **Firewall Rules**: Configurable IP allowlists
- **API Access**: Port 443 (kubectl)
- **UI Access**: Ports 80, 443 (Kubeflow)
- **Network Policies**: Available for pod-level security
- **RBAC**: Kubernetes Role-Based Access Control

## Deployment Phases

### Phase 1: Infrastructure (Current)
- LKE cluster provisioning
- GPU node pool with autoscaling
- High availability control plane
- Firewall configuration
- Automated deployment tooling

### Phase 2: Kubeflow (Planned)
- Kubeflow platform installation
- Jupyter notebook servers
- ML pipelines (Kubeflow Pipelines)
- Model serving (KServe)
- Hyperparameter tuning (Katib)
- Experiment tracking and metrics

## Infrastructure as Code

The infrastructure is defined using OpenTofu with the following structure:

- **main.tf**: Core infrastructure resources (cluster, firewall)
- **variables.tf**: Configurable parameters
- **outputs.tf**: Cluster connection details
- **tofu.tfvars**: User configuration (not in git)

All infrastructure state is managed by OpenTofu, enabling reproducible deployments and easy teardown.
