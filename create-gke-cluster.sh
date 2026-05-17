#!/bin/bash

################################################################################
# GKE Cluster Creation Script
# This script creates a GKE Standard cluster with E2 default nodes and Arm nodes
# Usage: ./create-gke-cluster.sh [REGION] [PROJECT_ID]
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
CLUSTER_NAME="devops-junction-cluster"
REGION="${1:-us-central1}"
PROJECT_ID="${2:-$(gcloud config get-value project)}"
DEFAULT_MACHINE_TYPE="e2-standard-4"
ARM_MACHINE_TYPE="c4a-standard-8"
DEFAULT_NUM_NODES=1
ARM_NUM_NODES=1
ZONE="${REGION}-a"

################################################################################
# Function to print colored output
################################################################################
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

################################################################################
# Function to validate prerequisites
################################################################################
validate_prerequisites() {
    print_info "Validating prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_warning "kubectl is not installed. You can install it with: gcloud components install kubectl"
    fi
    
    # Verify user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep -q .; then
        print_error "You are not authenticated. Run: gcloud auth login"
        exit 1
    fi
    
    print_info "Prerequisites validated successfully!"
}

################################################################################
# Function to display configuration
################################################################################
display_config() {
    echo ""
    echo "=================================="
    echo "GKE Cluster Configuration"
    echo "=================================="
    echo "Cluster Name:        $CLUSTER_NAME"
    echo "Project ID:          $PROJECT_ID"
    echo "Region:              $REGION"
    echo "Zone:                $ZONE"
    echo ""
    echo "Default Node Pool:"
    echo "  - Machine Type:    $DEFAULT_MACHINE_TYPE"
    echo "  - Number of Nodes: $DEFAULT_NUM_NODES"
    echo ""
    echo "Arm Node Pool:"
    echo "  - Machine Type:    $ARM_MACHINE_TYPE"
    echo "  - Number of Nodes: $ARM_NUM_NODES"
    echo "=================================="
    echo ""
}

################################################################################
# Function to create GKE cluster
################################################################################
create_cluster() {
    print_info "Creating GKE cluster: $CLUSTER_NAME"
    print_info "This may take 5-10 minutes..."
    echo ""
    
    gcloud container clusters create "$CLUSTER_NAME" \
        --region "$REGION" \
        --machine-type "$DEFAULT_MACHINE_TYPE" \
        --num-nodes "$DEFAULT_NUM_NODES" \
        --logging=SYSTEM,WORKLOAD \
        --monitoring=SYSTEM \
        --project "$PROJECT_ID"
    
    print_info "Cluster created successfully!"
}

################################################################################
# Function to add Arm node pool
################################################################################
add_arm_node_pool() {
    print_info "Adding Arm node pool to the cluster..."
    
    gcloud container node-pools create arm-pool \
        --cluster "$CLUSTER_NAME" \
        --region "$REGION" \
        --machine-type "$ARM_MACHINE_TYPE" \
        --num-nodes "$ARM_NUM_NODES" \
        --project "$PROJECT_ID"
    
    print_info "Arm node pool added successfully!"
}

################################################################################
# Function to get cluster credentials
################################################################################
get_credentials() {
    print_info "Getting cluster credentials..."
    
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --region "$REGION" \
        --project "$PROJECT_ID"
    
    print_info "Cluster credentials configured!"
}

################################################################################
# Function to verify cluster
################################################################################
verify_cluster() {
    print_info "Verifying cluster setup..."
    echo ""
    
    print_info "Cluster Info:"
    kubectl cluster-info
    echo ""
    
    print_info "Nodes in the cluster:"
    kubectl get nodes -o wide
    echo ""
    
    print_info "Node count by type:"
    echo "Default (E2) nodes:"
    kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool --no-headers | wc -l
    echo "Arm nodes:"
    kubectl get nodes -l cloud.google.com/gke-nodepool=arm-pool --no-headers | wc -l
    echo ""
}

################################################################################
# Function to display next steps
################################################################################
display_next_steps() {
    echo ""
    echo "=================================="
    echo "Cluster Creation Complete! ✓"
    echo "=================================="
    echo ""
    print_info "Your GKE cluster is ready to use!"
    echo ""
    echo "Next steps:"
    echo "1. Deploy NGINX:"
    echo "   kubectl create deployment nginx --image=nginx"
    echo ""
    echo "2. Expose the deployment:"
    echo "   kubectl expose deployment nginx --type=LoadBalancer --port=80"
    echo ""
    echo "3. Get the external IP:"
    echo "   kubectl get service nginx"
    echo ""
    echo "4. Access NGINX in your browser:"
    echo "   http://<EXTERNAL_IP>"
    echo ""
    echo "For more information, check the Readme.md file."
    echo "=================================="
    echo ""
}

################################################################################
# Main execution
################################################################################
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   GKE Cluster Creation Script          ║"
    echo "║   devops-pro-junction                  ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    # Validate prerequisites
    validate_prerequisites
    
    # Display configuration
    display_config
    
    print_info "Proceeding with cluster creation..."
    
    # Create cluster
    create_cluster
    echo ""
    
    # Add Arm node pool
    add_arm_node_pool
    echo ""
    
    # Get cluster credentials
    get_credentials
    echo ""
    
    # Verify cluster
    verify_cluster
    
    # Display next steps
    display_next_steps
}

# Run main function
main "$@"
