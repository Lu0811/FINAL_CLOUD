#!/bin/bash
set -e

# Configuration
PROJECT_ID="kubernetes-474008"
REGION="us-central1"

# Set up environment for gcloud
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export PATH=$PATH:/home/teriyaki/google-cloud-sdk/bin

echo "=== OpenTofu Infrastructure Deployment ==="
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo ""

# Check if OpenTofu is installed
if ! command -v tofu &> /dev/null; then
    echo "Error: OpenTofu is not installed. Please install it first."
    echo "Visit: https://opentofu.org/docs/intro/install/"
    exit 1
fi

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "Error: Not authenticated with gcloud. Please run:"
    echo "  export CLOUDSDK_PYTHON=/usr/bin/python3.11"
    echo "  gcloud auth login"
    exit 1
fi

# Set the project
gcloud config set project $PROJECT_ID

# Get access token for OpenTofu
echo "Setting up credentials for OpenTofu..."
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)

# Enable required APIs
echo "Enabling required GCP APIs..."
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable iam.googleapis.com

echo ""
echo "=== Initializing OpenTofu ==="
cd "$(dirname "$0")"
tofu init

echo ""
echo "=== Planning Infrastructure ==="
tofu plan -var-file=environments/dev/terraform.tfvars -out=tfplan

echo ""
read -p "Do you want to apply this plan? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "=== Applying Infrastructure ==="
tofu apply tfplan

echo ""
echo "=== Infrastructure Deployment Complete ==="
echo ""
echo "Next steps:"
echo "1. Configure kubectl to connect to the GKE cluster:"
echo "   gcloud container clusters get-credentials \$(tofu output -raw gke_cluster_name) --region $REGION --project $PROJECT_ID"
echo ""
echo "2. Deploy Jenkins to the cluster:"
echo "   kubectl apply -f modules/jenkins/jenkins-config.yaml"
echo ""
echo "3. Get Jenkins LoadBalancer IP:"
echo "   kubectl get svc jenkins -n jenkins"
echo ""
echo "4. Get Jenkins initial admin password:"
echo "   kubectl exec -n jenkins \$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -- cat /var/jenkins_home/secrets/initialAdminPassword"
