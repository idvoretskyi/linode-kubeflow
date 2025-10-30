# Akamai/Linode Kubeflow GPU Deployment

OpenTofu infrastructure code for deploying GPU-enabled Kubernetes clusters on Linode Kubernetes Engine (LKE) for machine learning workloads.

## Overview

This repository provides automated infrastructure deployment for a production-ready Kubernetes cluster with:

- **GPU Compute**: NVIDIA RTX 4000 Ada GPU nodes
- **High Availability**: Managed control plane with HA option
- **Autoscaling**: Automatic node scaling (1-5 nodes)
- **Security**: Configurable firewall rules and network policies
- **Automation**: One-command deployment and management

Designed for machine learning workloads and Kubeflow platform deployment.

## Quick Start

```bash
# Verify prerequisites
./setup.sh

# Deploy cluster
./deploy.sh

# Access cluster
export KUBECONFIG=$(cd tofu && tofu output -raw kubeconfig_path)
kubectl get nodes
```

Full deployment takes approximately 10-15 minutes.

## Prerequisites

- **OpenTofu** >= 1.6 - Infrastructure as code tool
- **linode-cli** - Linode API client (configured with token)
- **kubectl** - Kubernetes command-line tool
- **jq** - JSON processor
- **helm** - Kubernetes package manager (optional)

### macOS Installation

```bash
brew install opentofu kubectl jq helm
pip3 install linode-cli
linode-cli configure
```

Run `./setup.sh` to verify all prerequisites are met.

## Project Structure

```
.
├── README.md              # This file
├── CLAUDE.md              # AI assistant guidance
├── docs/                  # Detailed documentation
│   ├── architecture.md    # Infrastructure architecture
│   ├── configuration.md   # Configuration reference
│   ├── deployment.md      # Deployment procedures
│   ├── gpu-validation.md  # GPU testing
│   └── troubleshooting.md # Issue resolution
├── deploy.sh              # Main deployment script
├── setup.sh               # Prerequisites checker
└── tofu/                  # OpenTofu infrastructure code
    ├── main.tf            # Core resources
    ├── variables.tf       # Configuration variables
    ├── outputs.tf         # Output values
    └── tofu.tfvars.example # Configuration template
```

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[Architecture](docs/architecture.md)** - Infrastructure design and components
- **[Configuration](docs/configuration.md)** - Configuration options and variables
- **[Deployment](docs/deployment.md)** - Step-by-step deployment guide
- **[GPU Validation](docs/gpu-validation.md)** - GPU testing and verification
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## Deployment Commands

The `deploy.sh` script provides a unified interface for all operations:

```bash
./deploy.sh init          # Initialize OpenTofu
./deploy.sh plan          # Review changes
./deploy.sh apply         # Deploy infrastructure
./deploy.sh status        # Show cluster status
./deploy.sh gpu-check     # Verify GPU availability
./deploy.sh destroy       # Remove all resources
./deploy.sh help          # Show all commands
```

See [Deployment Guide](docs/deployment.md) for detailed procedures.

## Configuration

Default configuration deploys to Chicago (us-ord) with 2 GPU nodes. Customize by creating `tofu/tofu.tfvars`:

```hcl
Example `tofu.tfvars`:

```hcl
# cluster_name_prefix = "my-cluster"  # Optional: defaults to your username
region              = "us-ord"
kubernetes_version  = "1.34"
gpu_node_type       = "g1-gpu-rtx6000-1"
autoscaler_min      = 1
autoscaler_max      = 5
```

See [Configuration Reference](docs/configuration.md) for all available options.

## Cluster Specifications

| Component | Specification |
|-----------|--------------|
| Platform | Linode Kubernetes Engine (LKE) |
| Region | Chicago, IL (us-ord) |
| Kubernetes | v1.34 (configurable) |
| GPU | NVIDIA RTX 4000 Ada (1 per node) |
| CPU | 4 vCPU per node |
| Memory | 16 GB per node |
| Storage | 512 GB SSD per node |
| Nodes | 2 default, autoscaling 1-5 |

## Cost Estimation

**GPU Nodes**: ~$1.50-2.00/hour per node (~$1,080-1,440/month per node)

**Monthly Cost (2 nodes)**: ~$2,160-2,880

**Control Plane**: Free (standard) or additional charge (HA)

Costs are approximate. Check [Linode Pricing](https://www.linode.com/pricing/) for current rates.

## Security

- API token automatically loaded from `linode-cli` configuration
- Kubeconfig excluded from git tracking
- Configurable firewall rules for kubectl and UI access
- Support for Kubernetes RBAC and Network Policies

For production deployments, restrict access by IP:

```hcl
allowed_kubectl_ips     = ["YOUR_IP/32"]
allowed_kubeflow_ui_ips = ["YOUR_IP/32"]
```

## Cluster Management

**Scale nodes**:
```bash
# Edit tofu/tofu.tfvars: gpu_node_count = 3
./deploy.sh apply
```

**Update Kubernetes version**:
```bash
### Upgrade Kubernetes Version

```bash
# Edit tofu/tofu.tfvars: kubernetes_version = "1.35"
./deploy.sh apply
```
```

**Install NVIDIA GPU Operator**:
```bash
./deploy.sh install-nvidia
```

**Destroy cluster**:
```bash
./deploy.sh destroy
```

## Development Roadmap

### Phase 1: Infrastructure (Current)
- [x] LKE cluster with GPU nodes
- [x] High availability control plane
- [x] Autoscaling configuration
- [x] Firewall rules
- [x] Automated deployment

### Phase 2: Kubeflow (Planned)
- [ ] Kubeflow platform deployment
- [ ] Jupyter notebook servers
- [ ] ML pipelines
- [ ] Model serving (KServe)
- [ ] Experiment tracking (Katib)

## Resources

- [Linode Kubernetes Engine Documentation](https://www.linode.com/docs/products/compute/kubernetes/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubeflow Documentation](https://www.kubeflow.org/docs/)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)

## Support

For issues and questions:
- Review [Troubleshooting Guide](docs/troubleshooting.md)
- Check [Linode Community Forums](https://www.linode.com/community/)
- Consult [Kubernetes documentation](https://kubernetes.io/docs/)
- Open an issue on GitHub

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Ihor Dvoretskyi ([@idvoretskyi](https://github.com/idvoretskyi))

## Acknowledgments

- [Akamai/Linode](https://www.linode.com/) for the cloud platform
- [OpenTofu](https://opentofu.org/) community for infrastructure-as-code tooling
- [Kubernetes](https://kubernetes.io/) and [Kubeflow](https://www.kubeflow.org/) communities
- [NVIDIA](https://www.nvidia.com/) for GPU support and documentation
