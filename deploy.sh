#!/bin/bash

# Deployment script for Linode GPU Kubernetes cluster with OpenTofu
# This script can run the full deployment or execute individual commands
#
# Usage:
#   ./deploy.sh              - Run full deployment
#   ./deploy.sh init         - Initialize OpenTofu
#   ./deploy.sh plan         - Show OpenTofu plan
#   ./deploy.sh apply        - Apply OpenTofu configuration
#   ./deploy.sh destroy      - Destroy infrastructure
#   ./deploy.sh validate     - Validate OpenTofu configuration
#   ./deploy.sh fmt          - Format OpenTofu files
#   ./deploy.sh status       - Show cluster status
#   ./deploy.sh gpu-check    - Check GPU availability
#   ./deploy.sh install-nvidia - Install NVIDIA GPU operator
#   ./deploy.sh clean        - Clean temporary files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v tofu &> /dev/null; then
        missing_tools+=("tofu (OpenTofu)")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if ! command -v linode-cli &> /dev/null; then
        missing_tools+=("linode-cli")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Install missing tools and try again"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            print_info "On macOS, you can install with Homebrew:"
            echo "  brew install opentofu kubectl jq"
            echo "  pip3 install linode-cli"
        fi
        
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Check Linode API token
check_linode_token() {
    print_info "Checking for Linode API token..."

    # If token is already set in environment, use it
    if [ -n "$LINODE_TOKEN" ]; then
        print_success "Linode API token found in environment variable"
        return 0
    fi

    # Try to read token directly from linode-cli config file
    if [ -f "$HOME/.config/linode-cli" ]; then
        # Get the default user from config
        local default_user=$(awk -F' = ' '/^default-user/ {print $2}' "$HOME/.config/linode-cli")

        if [ -n "$default_user" ]; then
            # Extract token from the user's section
            LINODE_TOKEN=$(awk -v user="$default_user" '
                /^\[/ {section=$0; gsub(/[\[\]]/, "", section)}
                section == user && /^token/ {print $3; exit}
            ' "$HOME/.config/linode-cli")
        else
            # Fallback: try to get any token from the file
            LINODE_TOKEN=$(awk '/^token/ {print $3; exit}' "$HOME/.config/linode-cli")
        fi

        if [ -n "$LINODE_TOKEN" ]; then
            export LINODE_TOKEN
            print_success "Linode API token loaded from linode-cli configuration"
            return 0
        fi
    fi

    # Fallback: try linode-cli command (may not work in all cases)
    if command -v linode-cli &> /dev/null; then
        LINODE_TOKEN=$(linode-cli configure get token 2>/dev/null || echo "")

        if [ -n "$LINODE_TOKEN" ]; then
            export LINODE_TOKEN
            print_success "Linode API token loaded from linode-cli command"
            return 0
        fi
    fi

    # No token found
    print_error "No Linode API token found"
    print_info "Please either:"
    echo "  1. Configure linode-cli: linode-cli configure"
    echo "  2. Set LINODE_TOKEN environment variable: export LINODE_TOKEN=your-token"
    exit 1
    
    # Create tofu.tfvars from example if it doesn't exist
    if [ ! -f "tofu/tofu.tfvars" ]; then
        print_info "Creating tofu.tfvars from example..."
        cp tofu/tofu.tfvars.example tofu/tofu.tfvars
    fi
}

# Initialize OpenTofu
init_tofu() {
    print_info "Initializing OpenTofu..."
    cd tofu
    tofu init
    cd ..
    print_success "OpenTofu initialized successfully"
}

# Validate OpenTofu configuration
validate_tofu() {
    print_info "Validating OpenTofu configuration..."
    cd tofu
    tofu validate
    cd ..
    print_success "OpenTofu configuration is valid"
}

# Show OpenTofu plan
show_plan() {
    print_info "Generating OpenTofu plan..."
    print_warning "Review the plan carefully before applying"
    cd tofu
    tofu plan
    cd ..
}

# Apply OpenTofu configuration
apply_tofu() {
    print_info "Applying OpenTofu configuration..."
    print_warning "This will create real resources and incur costs"

    read -p "Do you want to proceed? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Deployment cancelled"
        exit 0
    fi

    cd tofu
    tofu apply
    cd ..
    print_success "Infrastructure deployed successfully"
}

# Configure kubectl
configure_kubectl() {
    print_info "Configuring kubectl..."

    cd tofu
    KUBECONFIG_PATH=$(tofu output -raw kubeconfig_path)
    cd ..

    export KUBECONFIG="$KUBECONFIG_PATH"
    print_success "kubectl configured"

    print_info "Testing cluster connection..."
    kubectl get nodes

    print_success "Cluster is accessible"
}

# Check GPU availability
check_gpu() {
    print_info "Checking GPU availability..."

    cd tofu
    KUBECONFIG_PATH=$(tofu output -raw kubeconfig_path)
    cd ..

    export KUBECONFIG="$KUBECONFIG_PATH"

    print_info "GPU capacity on nodes:"
    kubectl get nodes -o json | jq -r '.items[] | "\(.metadata.name): \(.status.capacity."nvidia.com/gpu" // "0") GPUs"'

    print_success "GPU check complete"
}

# Format OpenTofu files
format_tofu() {
    print_info "Formatting OpenTofu files..."
    cd tofu
    tofu fmt -recursive
    cd ..
    print_success "OpenTofu files formatted"
}

# Show cluster status
show_status() {
    print_info "Cluster Status:"
    cd tofu
    KUBECONFIG_PATH=$(tofu output -raw kubeconfig_path)
    export KUBECONFIG="$KUBECONFIG_PATH"

    echo ""
    echo "Nodes:"
    kubectl get nodes -o wide

    echo ""
    echo "Pods:"
    kubectl get pods --all-namespaces
    cd ..
}

# Install NVIDIA GPU operator
install_nvidia() {
    print_info "Installing NVIDIA GPU operator..."

    cd tofu
    KUBECONFIG_PATH=$(tofu output -raw kubeconfig_path)
    cd ..

    export KUBECONFIG="$KUBECONFIG_PATH"

    kubectl create namespace gpu-operator --dry-run=client -o yaml | kubectl apply -f -
    helm repo add nvidia https://helm.ngc.nvidia.com/nvidia || true
    helm repo update
    helm install --wait gpu-operator nvidia/gpu-operator -n gpu-operator

    print_success "NVIDIA GPU operator installed"
}

# Destroy infrastructure
destroy_tofu() {
    print_info "Destroying infrastructure..."
    print_warning "This will destroy all resources"

    read -p "Are you sure you want to destroy the infrastructure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Destroy cancelled"
        exit 0
    fi

    cd tofu
    tofu destroy
    cd ..
    print_success "Infrastructure destroyed"
}

# Clean temporary files
clean_files() {
    print_info "Cleaning temporary files..."
    cd tofu
    rm -f kubeconfig*.yaml
    rm -rf .terraform .tofu
    rm -f .terraform.lock.hcl .terraform.lock.json
    cd ..
    print_success "Temporary files cleaned"
}

# Show help
show_help() {
    echo ""
    echo "Linode GPU Kubernetes Cluster Deployment (OpenTofu)"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (no args)       - Run full deployment"
    echo "  init            - Initialize OpenTofu"
    echo "  plan            - Show OpenTofu plan"
    echo "  apply           - Apply OpenTofu configuration"
    echo "  destroy         - Destroy infrastructure"
    echo "  validate        - Validate OpenTofu configuration"
    echo "  fmt             - Format OpenTofu files"
    echo "  status          - Show cluster status"
    echo "  gpu-check       - Check GPU availability"
    echo "  install-nvidia  - Install NVIDIA GPU operator"
    echo "  clean           - Clean temporary files"
    echo "  help            - Show this help message"
    echo ""
}

# Main deployment flow (full deployment)
main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║  Linode GPU Kubernetes Cluster Deployment Script         ║"
    echo "║  Cluster: <username>-lke-gpu-kubeflow                     ║"
    echo "║  Region: Chicago, US (us-ord)                             ║"
    echo "║  GPU: NVIDIA RTX 4000 Ada                                 ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    # Step 1: Check prerequisites
    check_prerequisites

    # Step 2: Check Linode token
    check_linode_token

    # Step 3: Initialize OpenTofu
    init_tofu

    # Step 4: Validate configuration
    validate_tofu

    # Step 5: Show plan
    show_plan

    # Step 6: Apply (with confirmation)
    apply_tofu

    # Step 7: Configure kubectl
    configure_kubectl

    # Step 8: Check GPU availability
    check_gpu

    echo ""
    print_success "Deployment complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Export kubeconfig: export KUBECONFIG=\$(cd tofu && tofu output -raw kubeconfig_path)"
    echo "  2. Verify cluster: kubectl get nodes"
    echo "  3. Install NVIDIA GPU operator: ./deploy.sh install-nvidia"
    echo "  4. Deploy Kubeflow (coming in next phase)"
    echo ""
    print_info "Cluster dashboard: \$(cd tofu && tofu output -raw cluster_dashboard_url)"
    echo ""
}

# Parse command-line arguments
case "${1:-}" in
    init)
        check_prerequisites
        check_linode_token
        init_tofu
        ;;
    plan)
        check_prerequisites
        check_linode_token
        show_plan
        ;;
    apply)
        check_prerequisites
        check_linode_token
        apply_tofu
        ;;
    destroy)
        check_prerequisites
        check_linode_token
        destroy_tofu
        ;;
    validate)
        check_prerequisites
        validate_tofu
        ;;
    fmt)
        check_prerequisites
        format_tofu
        ;;
    status)
        check_prerequisites
        show_status
        ;;
    gpu-check)
        check_prerequisites
        check_gpu
        ;;
    install-nvidia)
        check_prerequisites
        install_nvidia
        ;;
    clean)
        clean_files
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        # No arguments - run full deployment
        main
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
