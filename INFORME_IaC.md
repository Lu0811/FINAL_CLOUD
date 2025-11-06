# AgendaApp - Infrastructure as Code Implementation

## Resumen del Proyecto

Este documento describe la implementación de Infrastructure as Code (IaC) para AgendaApp utilizando **OpenTofu** (fork open source de Terraform) y **Jenkins** para CI/CD.

## 🎯 Objetivos Cumplidos

✅ Configuración completa de infraestructura como código con OpenTofu
✅ Módulos para VPC, GKE, CloudSQL, Artifact Registry y Jenkins  
✅ Pipeline de CI/CD con Jenkinsfile
✅ Despliegue de Jenkins en GKE
✅ Documentación completa del proceso

## 📁 Estructura del Proyecto

```
infrastructure/
├── README.md
└── opentofu/
    ├── main.tf                     # Configuración principal
    ├── variables.tf                # Definición de variables
    ├── outputs.tf                  # Outputs de la infraestructura
    ├── deploy.sh                   # Script de despliegue automatizado
    ├── environments/
    │   └── dev/
    │       └── terraform.tfvars    # Valores para ambiente dev
    └── modules/
        ├── vpc/                    # Módulo de red VPC
        ├── gke/                    # Módulo de cluster GKE
        ├── cloudsql/               # Módulo de base de datos
        ├── artifact-registry/      # Módulo de registro de imágenes
        └── jenkins/                # Módulo de servicio Jenkins
            ├── main.tf
            ├── variables.tf
            ├── outputs.tf
            └── jenkins-config.yaml # Deployment de Jenkins en K8s
```

## 🏗️ Componentes de Infraestructura

### 1. VPC Network (`modules/vpc/`)
- Red VPC personalizada: `agendaapp-network`
- Subnet para GKE con rangos secundarios para pods y servicios
- Reglas de firewall para tráfico interno y SSH
- Cloud Router y Cloud NAT para conectividad externa

**Características:**
- Subnet principal: `10.0.0.0/24`
- Rango de pods: `10.1.0.0/16`
- Rango de servicios: `10.2.0.0/16`

### 2. GKE Cluster (`modules/gke/`)
- Cluster regional en `us-central1`
- Node pool con autoscaling (1-3 nodos)
- Tipo de máquina: `e2-medium`
- Workload Identity habilitado
- Release channel: REGULAR

**Configuración:**
```hcl
machine_type = "e2-medium"
min_count    = 1
max_count    = 3
disk_size_gb = 50
```

### 3. CloudSQL PostgreSQL (`modules/cloudsql/`)
- PostgreSQL 14
- Tier: `db-f1-micro` (desarrollo)
- Private IP (sin acceso público)
- Backups automáticos a las 03:00 AM
- SSL requerido

**Configuración:**
```hcl
database_version = "POSTGRES_14"
tier            = "db-f1-micro"
backup_enabled  = true
```

### 4. Artifact Registry (`modules/artifact-registry/`)
- Repositorio Docker en `us-central1`
- Nombre: `agendaapp`
- Formato: DOCKER
- URL: `us-central1-docker.pkg.dev/kubernetes-474008/agendaapp`

### 5. Jenkins CI/CD (`modules/jenkins/`)
- Service Account con permisos:
  - `container.developer` (acceso a GKE)
  - `artifactregistry.writer` (push de imágenes)
  - `storage.admin` (acceso a GCS)
- Workload Identity configurado
- Despliegue en namespace `jenkins`
- Persistent Volume de 20Gi
- LoadBalancer para acceso externo

## 🚀 Pipeline CI/CD (Jenkinsfile)

El pipeline automatiza el proceso completo de build y deployment:

### Etapas del Pipeline:

1. **Checkout** 
   - Clona el repositorio
   - Obtiene el commit SHA para tags

2. **Test Backend**
   - Instala dependencias de Python
   - Ejecuta tests con pytest

3. **Build Backend Image**
   - Construye imagen Docker del backend
   - Tag: `commit-sha-build-number` y `latest`

4. **Build Frontend Image**
   - Construye imagen Docker del frontend
   - Tag: `commit-sha-build-number` y `latest`

5. **Push Images to Artifact Registry**
   - Autentica con GCP
   - Push de ambas imágenes al registry

6. **Deploy to GKE**
   - Actualiza deployments con nuevas imágenes
   - Espera rollout exitoso

7. **Smoke Test**
   - Verifica endpoint de health del backend
   - Confirma que la aplicación responde

### Variables de Entorno:

```groovy
PROJECT_ID     = 'kubernetes-474008'
CLUSTER_NAME   = 'agendaapp-cluster'
REGION         = 'us-central1'
REGISTRY       = 'us-central1-docker.pkg.dev/kubernetes-474008/agendaapp-repo'
```

## 📝 Instrucciones de Uso

### 1. Desplegar Infraestructura con OpenTofu

```bash
cd /home/teriyaki/Música/big\ data/infrastructure/opentofu

# Configurar credenciales
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)

# Ejecutar deployment
chmod +x deploy.sh
./deploy.sh
```

### 2. Verificar Despliegue de Jenkins

```bash
# Ver estado de pods
kubectl get pods -n jenkins

# Ver servicio y obtener IP externa
kubectl get svc -n jenkins

# Obtener contraseña inicial de Jenkins
kubectl exec -n jenkins $(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') \
  -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### 3. Configurar Jenkins

Una vez que Jenkins esté accesible en `http://<EXTERNAL-IP>:8080`:

1. **Instalar plugins requeridos:**
   - Docker Pipeline
   - Google Kubernetes Engine Plugin
   - Git Plugin
   - Pipeline Plugin

2. **Configurar credenciales:**
   - Agregar service account de GCP
   - Configurar acceso a Artifact Registry

3. **Crear Pipeline Job:**
   - New Item → Pipeline
   - Pipeline from SCM
   - Git repository: tu repositorio
   - Script Path: `Jenkinsfile`

## 🔧 Gestión de la Infraestructura

### Ver Estado Actual:
```bash
cd infrastructure/opentofu
tofu show
```

### Actualizar Infraestructura:
```bash
# Modificar archivos de configuración
tofu plan -var-file=environments/dev/terraform.tfvars
tofu apply -var-file=environments/dev/terraform.tfvars
```

### Destruir Infraestructura:
```bash
tofu destroy -var-file=environments/dev/terraform.tfvars
```

## 📊 Estado Actual del Despliegue

### Infraestructura Existente:
- ✅ GKE Cluster: `agendaapp-cluster` (running)
- ✅ Backend: 3 replicas en `34.71.155.58:5000`
- ✅ Frontend: 3 replicas en `34.70.211.16`
- ✅ PostgreSQL: 1 replica (running)
- ✅ Jenkins: Desplegado en namespace `jenkins` (pending LoadBalancer IP)

### Módulos OpenTofu Creados:
- ✅ VPC Module
- ✅ GKE Module
- ✅ CloudSQL Module
- ✅ Artifact Registry Module
- ✅ Jenkins Module

## 🎓 Beneficios de esta Implementación

### Para el Proyecto Académico:

1. **Infrastructure as Code (IaC)**
   - Código versionado y reproducible
   - Documentación como código
   - Fácil rollback y versionado

2. **Automatización CI/CD**
   - Pipeline completamente automatizado
   - Tests automáticos
   - Despliegue continuo

3. **Mejores Prácticas**
   - Módulos reutilizables
   - Separación de ambientes
   - Security best practices

4. **Herramientas Open Source**
   - OpenTofu (no Terraform propietario)
   - Jenkins para CI/CD
   - Kubernetes para orquestación

## 🔍 Diferencias con Terraform

OpenTofu es un fork 100% open source de Terraform que mantiene compatibilidad completa con la sintaxis HCL de Terraform, pero con las siguientes ventajas:

- ✅ Completamente open source (licencia MPL 2.0)
- ✅ Gobernanza comunitaria (Linux Foundation)
- ✅ Sin restricciones de licencia empresarial
- ✅ Compatibilidad total con código Terraform existente
- ✅ Desarrollo activo y transparente

## 📈 Próximos Pasos Recomendados

1. **Configurar Jenkins completamente:**
   - Instalar plugins
   - Configurar credenciales de GCP
   - Crear pipeline job

2. **Ejecutar primer build:**
   - Commit y push de código
   - Jenkins ejecutará pipeline automáticamente
   - Verificar deployment exitoso

3. **Optimizaciones futuras:**
   - Agregar stages de QA/Staging
   - Implementar blue-green deployment
   - Configurar monitoring y alertas
   - Agregar tests de integración

## 📚 Referencias

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Google Cloud Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Jenkins on Kubernetes](https://www.jenkins.io/doc/book/installing/kubernetes/)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)

## 🎯 Conclusión

Se ha implementado exitosamente una solución completa de Infrastructure as Code utilizando:

- **OpenTofu** para definición declarativa de infraestructura
- **Módulos reutilizables** para VPC, GKE, CloudSQL, Artifact Registry y Jenkins
- **Jenkins** desplegado en GKE para CI/CD
- **Pipeline automatizado** con 7 etapas de build y deployment
- **Documentación completa** del proceso y configuración

Esta implementación cumple con los requisitos del proyecto y demuestra el uso de mejores prácticas de DevOps e Infrastructure as Code.

---

**Proyecto:** AgendaApp - Aplicación de Gestión de Tareas  
**Plataforma:** Google Kubernetes Engine (GKE)  
**Herramientas:** OpenTofu + Jenkins + Kubernetes  
**Fecha:** Noviembre 2025
