# Infrastructure as Code - OpenTofu Configuration

This directory contains the Infrastructure as Code (IaC) configuration for the AgendaApp using OpenTofu (OpenSource Terraform fork).

## Architecture

The infrastructure consists of:

- **VPC Network**: Custom network with subnets and firewall rules
- **GKE Cluster**: Google Kubernetes Engine cluster for application hosting
- **CloudSQL**: PostgreSQL database instance with private networking
- **Artifact Registry**: Docker image repository for application containers
- **Jenkins**: CI/CD service account with necessary permissions

## Prerequisites

1. **OpenTofu** - Install from https://opentofu.org/docs/intro/install/
   ```bash
   # For Linux
   curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
   chmod +x install-opentofu.sh
   ./install-opentofu.sh
   ```

2. **Google Cloud SDK** - Already installed
   ```bash
   gcloud auth login
   gcloud config set project kubernetes-474008
   ```

3. **kubectl** - Already installed with gke-gcloud-auth-plugin

## Directory Structure

```
opentofu/
├── main.tf                    # Root configuration with module calls
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── deploy.sh                  # Deployment script
├── environments/
│   └── dev/
│       └── terraform.tfvars   # Environment-specific values
└── modules/
    ├── vpc/                   # VPC network module
    ├── gke/                   # GKE cluster module
    ├── cloudsql/              # CloudSQL database module
    ├── artifact-registry/     # Artifact Registry module
    └── jenkins/               # Jenkins service account module
```

## Deployment Steps

### 1. Deploy Infrastructure with OpenTofu

```bash
cd /home/teriyaki/Música/big\ data/infrastructure/opentofu
chmod +x deploy.sh
./deploy.sh
```

This script will:
- Check prerequisites
- Enable required GCP APIs
- Initialize OpenTofu
- Create an execution plan
- Apply the infrastructure (after confirmation)

### 2. Connect to GKE Cluster

```bash
gcloud container clusters get-credentials agendaapp-cluster \
  --region us-central1 \
  --project kubernetes-474008
```

### 3. Deploy Jenkins to Kubernetes

```bash
kubectl apply -f modules/jenkins/jenkins-config.yaml
```

Wait for Jenkins to be ready:
```bash
kubectl get pods -n jenkins -w
```

### 4. Access Jenkins

Get the LoadBalancer IP:
```bash
kubectl get svc jenkins -n jenkins
```

Get the initial admin password:
```bash
kubectl exec -n jenkins $(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') \
  -- cat /var/jenkins_home/secrets/initialAdminPassword
```

Access Jenkins at `http://<JENKINS_IP>:8080`

### 5. Configure Jenkins Pipeline

1. Install required plugins:
   - Docker Pipeline
   - Google Kubernetes Engine Plugin
   - Git Plugin

2. Configure credentials:
   - Add GCP service account key
   - Configure Docker registry credentials

3. Create a new Pipeline job:
   - Point to your Git repository
   - Use the Jenkinsfile at the root of the project

## Module Details

### VPC Module
- Creates custom VPC network
- Configures subnets with secondary ranges for GKE pods and services
- Sets up firewall rules
- Creates Cloud NAT for outbound connectivity

### GKE Module
- Deploys autopilot GKE cluster
- Configures node pools with autoscaling (1-3 nodes)
- Enables Workload Identity
- Configures IP allocation policy

### CloudSQL Module
- Creates PostgreSQL 14 instance
- Configures private IP networking
- Sets up automated backups
- Creates database and user

### Artifact Registry Module
- Creates Docker repository
- Configures access permissions

### Jenkins Module
- Creates service account for Jenkins
- Assigns necessary IAM roles:
  - container.developer (GKE access)
  - artifactregistry.writer (push images)
  - storage.admin (GCS access)
- Configures Workload Identity binding

## CI/CD Pipeline

The Jenkinsfile defines a pipeline with the following stages:

1. **Checkout**: Clone the repository
2. **Test Backend**: Run Python tests
3. **Build Backend Image**: Build Docker image for backend
4. **Build Frontend Image**: Build Docker image for frontend
5. **Push Images**: Push to Artifact Registry
6. **Deploy to GKE**: Update deployments with new images
7. **Smoke Test**: Verify backend health endpoint

## Updating the Infrastructure

To make changes to the infrastructure:

1. Edit the relevant module or configuration file
2. Run the deploy script again:
   ```bash
   ./deploy.sh
   ```
3. Review the plan carefully
4. Confirm to apply changes

## Destroying the Infrastructure

**⚠️ WARNING: This will delete all resources!**

```bash
cd /home/teriyaki/Música/big\ data/infrastructure/opentofu
tofu destroy -var-file=environments/dev/terraform.tfvars
```

## Troubleshooting

### OpenTofu initialization fails
```bash
rm -rf .terraform .terraform.lock.hcl
tofu init
```

### API not enabled error
```bash
gcloud services enable <api-name>.googleapis.com
```

### kubectl authentication issues
```bash
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export CLOUDSDK_PYTHON=/usr/bin/python3.11
gcloud container clusters get-credentials agendaapp-cluster --region us-central1
```

### Jenkins pod not starting
```bash
kubectl describe pod -n jenkins <pod-name>
kubectl logs -n jenkins <pod-name>
```

## Cost Optimization

Current configuration is optimized for development:
- GKE: e2-medium nodes (1-3 nodes with autoscaling)
- CloudSQL: db-f1-micro instance
- Artifact Registry: Standard tier

For production, consider:
- Increase node pool size and machine types
- Use Cloud SQL high availability
- Enable GKE cluster autoscaling
- Configure backup retention policies

## Security Best Practices

- Service accounts use least-privilege IAM roles
- CloudSQL uses private IP (no public access)
- VPC firewall rules restrict traffic
- Workload Identity enabled for pod-level authentication
- Jenkins credentials stored securely

## References

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Google Cloud Provider for Terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Jenkins on Kubernetes](https://www.jenkins.io/doc/book/installing/kubernetes/)
