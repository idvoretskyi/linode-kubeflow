#!/bin/bash

# Quick setup script for Linode Kubeflow GPU deployment
# This script checks prerequisites and helps set up linode-cli

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Linode GPU Kubernetes Setup - Prerequisites Check        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check OpenTofu
echo -n "Checking OpenTofu... "
if command -v tofu &> /dev/null; then
    VERSION=$(tofu version | head -n1)
    echo -e "${GREEN}✓${NC} $VERSION"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo ""
    echo "Install OpenTofu:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install opentofu"
    else
        echo "  Visit: https://opentofu.org/docs/intro/install/"
    fi
    exit 1
fi

# Check kubectl
echo -n "Checking kubectl... "
if command -v kubectl &> /dev/null; then
    VERSION=$(kubectl version --client --short 2>/dev/null | head -n1 || kubectl version --client 2>/dev/null | grep "Client Version" | head -n1)
    echo -e "${GREEN}✓${NC} Installed"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo ""
    echo "Install kubectl:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install kubectl"
    else
        echo "  Visit: https://kubernetes.io/docs/tasks/tools/"
    fi
    exit 1
fi

# Check helm
echo -n "Checking Helm... "
if command -v helm &> /dev/null; then
    VERSION=$(helm version --short)
    echo -e "${GREEN}✓${NC} $VERSION"
else
    echo -e "${YELLOW}⚠${NC} Not installed (optional for Kubeflow)"
    echo "  Install: brew install helm"
fi

# Check jq
echo -n "Checking jq... "
if command -v jq &> /dev/null; then
    VERSION=$(jq --version)
    echo -e "${GREEN}✓${NC} $VERSION"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo ""
    echo "Install jq:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install jq"
    else
        echo "  Visit: https://stedolan.github.io/jq/download/"
    fi
    exit 1
fi

# Check linode-cli
echo -n "Checking linode-cli... "
if command -v linode-cli &> /dev/null; then
    VERSION=$(linode-cli --version 2>&1 || echo "installed")
    echo -e "${GREEN}✓${NC} Installed"
    
    # Check if configured
    echo -n "Checking linode-cli configuration... "
    TOKEN=$(linode-cli configure get token 2>/dev/null || echo "")
    
    if [ -z "$TOKEN" ]; then
        echo -e "${RED}✗ Not configured${NC}"
        echo ""
        echo -e "${YELLOW}linode-cli needs to be configured with your API token${NC}"
        echo ""
        read -p "Would you like to configure it now? (yes/no): " configure
        
        if [ "$configure" = "yes" ]; then
            echo ""
            echo "You'll need a Linode API token. Get one from:"
            echo "  https://cloud.linode.com/profile/tokens"
            echo ""
            echo "Running: linode-cli configure"
            echo ""
            linode-cli configure
            
            # Verify configuration
            TOKEN=$(linode-cli configure get token 2>/dev/null || echo "")
            if [ -z "$TOKEN" ]; then
                echo -e "${RED}Configuration failed. Please run 'linode-cli configure' manually.${NC}"
                exit 1
            else
                echo -e "${GREEN}✓ linode-cli configured successfully!${NC}"
            fi
        else
            echo ""
            echo "Please configure linode-cli manually:"
            echo "  linode-cli configure"
            echo ""
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Configured${NC}"
        
        # Verify the token works
        echo -n "Verifying API token... "
        if linode-cli regions list --json > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Valid${NC}"
            
            # Show account info
            ACCOUNT_EMAIL=$(linode-cli account view --format email --text 2>/dev/null | tail -n1 || echo "")
            if [ -n "$ACCOUNT_EMAIL" ]; then
                echo "  Account: $ACCOUNT_EMAIL"
            fi
        else
            echo -e "${RED}✗ Invalid or expired${NC}"
            echo ""
            echo "Please reconfigure linode-cli:"
            echo "  linode-cli configure"
            echo ""
            exit 1
        fi
    fi
else
    echo -e "${RED}✗ Not installed${NC}"
    echo ""
    echo "Install linode-cli:"
    echo "  pip3 install linode-cli"
    echo ""
    echo "Then configure it:"
    echo "  linode-cli configure"
    echo ""
    echo "You'll need a Linode API token from:"
    echo "  https://cloud.linode.com/profile/tokens"
    echo ""
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  All prerequisites are installed and configured! ✓         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Review configuration (optional):"
echo "   cd tofu"
echo "   cp tofu.tfvars.example tofu.tfvars"
echo "   # Edit tofu.tfvars if needed"
echo ""
echo "2. Deploy the cluster:"
echo "   ./deploy.sh              # Full deployment"
echo ""
echo "   OR use individual commands:"
echo "   ./deploy.sh init         # Initialize OpenTofu"
echo "   ./deploy.sh plan         # Review changes"
echo "   ./deploy.sh apply        # Deploy cluster"
echo "   ./deploy.sh help         # Show all commands"
echo ""
echo "3. Access your cluster:"
echo "   export KUBECONFIG=\$(cd tofu && tofu output -raw kubeconfig_path)"
echo "   kubectl get nodes"
echo ""
echo "For more information, see:"
echo "  - README.md - Project overview"
echo "  - QUICKSTART.md - Quick reference"
echo "  - DEPLOYMENT.md - Detailed deployment guide"
echo ""
