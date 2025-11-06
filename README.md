# Implementación de Infraestructura como Código con OpenTofu y Jenkins

## Resumen Ejecutivo

Este proyecto implementa un pipeline CI/CD completo que automatiza tanto la creación de infraestructura en Google Cloud Platform (GCP) como el despliegue de la aplicación AgendaApp. 

**¿Qué hace este sistema?**

Con un solo click en Jenkins, el sistema:
1. **Crea la infraestructura completa** en GCP usando OpenTofu (VPC, GKE, Artifact Registry)
2. **Construye las imágenes Docker** del frontend y backend de la aplicación
3. **Sube las imágenes** a Google Artifact Registry
4. **Despliega la aplicación** en el cluster de Kubernetes (GKE)
5. **Proporciona las URLs** para acceder a la aplicación

**Tecnologías principales:**
- **IaC**: OpenTofu 1.10.7 (alternativa open-source a Terraform)
- **CI/CD**: Jenkins 2.528.1 LTS en Docker
- **Cloud**: Google Cloud Platform (GKE, Artifact Registry, VPC)
- **Contenedores**: Docker 28.5.2 + Kubernetes
- **Aplicación**: Python/Flask (Backend) + HTML/CSS/JS (Frontend) + PostgreSQL

**Problema resuelto:**
Antes, cada cambio requería:
- Crear infraestructura manualmente en GCP Console
- Construir imágenes Docker localmente
- Subir a registry manualmente
- Desplegar con kubectl manualmente
- Actualizar IPs hardcodeadas cuando cambiaban

Ahora: **Todo es automático con un solo click**.

## Arquitectura del Sistema

### Diagrama del Pipeline de CI/CD

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MÁQUINA LOCAL (Debian)                          │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │              Jenkins (Docker Container)                        │    │
│  │                                                                │    │
│  │  Herramientas instaladas:                                     │    │
│  │  - OpenTofu v1.10.6                                           │    │
│  │  - Google Cloud SDK 546.0.0                                   │    │
│  │  - kubectl                                                    │    │
│  │                                                                │    │
│  │  Volúmenes montados:                                          │    │
│  │  - /var/jenkins_home (persistencia)                           │    │
│  │  - ../opentofu:/workspace/infrastructure/opentofu            │    │
│  │  - jenkins-iac-credentials.json (Service Account GCP)         │    │
│  │                                                                │    │
│  │  Pipeline: agendaapp-infrastructure-auto                      │    │
│  │  ┌──────────────────────────────────────────────────────┐   │    │
│  │  │ 1. Preparar Entorno                                   │   │    │
│  │  │    - Verificar tofu, gcloud, kubectl                 │   │    │
│  │  ├──────────────────────────────────────────────────────┤   │    │
│  │  │ 2. Autenticar GCP                                     │   │    │
│  │  │    - gcloud auth activate-service-account            │   │    │
│  │  ├──────────────────────────────────────────────────────┤   │    │
│  │  │ 3. Clonar Repositorio IaC                            │   │    │
│  │  │    - Acceso a archivos .tf via volumen               │   │    │
│  │  ├──────────────────────────────────────────────────────┤   │    │
│  │  │ 4. Inicializar OpenTofu                              │   │    │
│  │  │    - tofu init -reconfigure                          │   │    │
│  │  ├──────────────────────────────────────────────────────┤   │    │
│  │  │ 5. Validar Configuración                             │   │    │
│  │  │    - tofu validate                                   │   │    │
│  │  ├──────────────────────────────────────────────────────┤   │    │
│  │  │ 6. Generar Plan                                      │   │    │
│  │  │    - tofu plan -out=tfplan                           │   │    │
│  │  ├──────────────────────────────────────────────────────┤   │    │
│  │  │ 7. Aplicar Cambios                                   │   │    │
│  │  │    - tofu apply -auto-approve tfplan                 │   │    │
│  │  ├──────────────────────────────────────────────────────┤   │    │
│  │  │ 8. Mostrar Outputs                                   │   │    │
│  │  │    - tofu output                                     │   │    │
│  │  └──────────────────────────────────────────────────────┘   │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                    │                                   │
│                                    │ API Calls                        │
│                                    ▼                                   │
└────────────────────────────────────┼───────────────────────────────────┘
                                     │
                                     │
                  ┌──────────────────┴──────────────────┐
                  │                                     │
                  ▼                                     │
        ┌─────────────────────────────────────────┐   │
        │      Google Cloud Platform (GCP)        │   │
        │      Project: kubernetes-474008         │   │
        │      Region: us-central1                │   │
        │                                         │   │
        │  Recursos creados por OpenTofu:        │   │
        │                                         │   │
        │  ┌────────────────────────────────┐   │   │
        │  │  VPC Network                    │   │   │
        │  │  - agendaapp-network            │   │   │
        │  │  - Subnet: 10.0.0.0/24          │   │   │
        │  │  - Secondary ranges:            │   │   │
        │  │    * gke-pods: 10.1.0.0/16      │   │   │
        │  │    * gke-services: 10.2.0.0/16  │   │   │
        │  └────────────────────────────────┘   │   │
        │                                         │   │
        │  ┌────────────────────────────────┐   │   │
        │  │  Firewall Rules                 │   │   │
        │  │  - allow-internal               │   │   │
        │  │  - allow-ssh                    │   │   │
        │  └────────────────────────────────┘   │   │
        │                                         │   │
        │  ┌────────────────────────────────┐   │   │
        │  │  Cloud NAT                      │   │   │
        │  │  - agendaapp-network-nat        │   │   │
        │  └────────────────────────────────┘   │   │
        │                                         │   │
        │  ┌────────────────────────────────┐   │   │
        │  │  GKE Cluster                    │   │   │
        │  │  - Nombre: agendaapp-cluster    │   │   │
        │  │  - Modo: Standard (no Autopilot)│   │   │
        │  │  - Node Pool:                   │   │   │
        │  │    * Tipo: e2-medium            │   │   │
        │  │    * Min: 1, Max: 3 nodos       │   │   │
        │  │    * Disk: 50GB pd-standard     │   │   │
        │  │  - Autoscaling: Habilitado      │   │   │
        │  │  - deletion_protection: false   │   │   │
        │  └────────────────────────────────┘   │   │
        │                                         │   │
        │  ┌────────────────────────────────┐   │   │
        │  │  Artifact Registry              │   │   │
        │  │  - Nombre: agendaapp            │   │   │
        │  │  - Formato: DOCKER              │   │   │
        │  │  - URL: us-central1-docker...   │   │   │
        │  └────────────────────────────────┘   │   │
        │                                         │   │
        │  ┌────────────────────────────────┐   │   │
        │  │  CloudSQL (Deshabilitado)       │   │   │
        │  │  - Requiere private service     │   │   │
        │  │    connection no configurada    │   │   │
        │  └────────────────────────────────┘   │   │
        └─────────────────────────────────────────┘   │
                                                       │
                                                       │
                      Aplicación AgendaApp             │
                    (A desplegar después)              │
                                                       │
                  ┌────────────────────────────────┐  │
                  │  Frontend (HTML/JS/CSS)        │  │
                  │  - Servicio: LoadBalancer      │  │
                  │  - Puerto: 80                  │  │
                  └────────────────────────────────┘  │
                                                       │
                  ┌────────────────────────────────┐  │
                  │  Backend (Python/Flask)        │  │
                  │  - Servicio: LoadBalancer      │  │
                  │  - Puerto: 5000                │  │
                  │  - Base de datos: PostgreSQL   │  │
                  └────────────────────────────────┘  │
                                                       │
                                                       │
```

---

## Proceso de Construcción: De Kubernetes Manual a IaC Automatizado

### Fase 1: Estado Inicial - Kubernetes Manual

#### 1.1 Situación de Partida

El proyecto comenzó con la aplicación AgendaApp desplegada manualmente en GKE:

- Cluster GKE creado manualmente desde la consola de GCP
- Deployments de frontend y backend aplicados con kubectl
- PostgreSQL desplegado en el cluster
- Servicios de tipo LoadBalancer expuestos manualmente
- Sin versionado de infraestructura
- Sin automatización de despliegues

**Problemas identificados:**
- No había trazabilidad de cambios en la infraestructura
- Configuración propensa a errores humanos
- Imposible replicar el entorno de forma consistente
- Dificultad para hacer rollback de cambios
- No había separación entre entornos (dev/staging/prod)

#### 1.2 Archivos Kubernetes Existentes

```
AgendaApp/
├── k8s/
│   ├── frontend-deployment.yaml
│   ├── backend-postgres-working.yaml
│   ├── postgres-deployment.yaml
│   ├── postgres-pvc.yaml
│   ├── frontend-hpa.yaml
│   ├── backend-hpa.yaml
│   ├── deploy.sh
│   └── cleanup.sh
└── helm/
    └── agendaapp/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── frontend-deployment.yaml
            ├── backend-deployment.yaml
            ├── mongodb-deployment.yaml
            └── ...
```

### Fase 2: Diseño de la Arquitectura IaC

#### 2.1 Decisiones Arquitectónicas

**Herramienta seleccionada: OpenTofu**
- Razón: Alternativa de código abierto a Terraform
- Compatible con HCL (HashiCorp Configuration Language)
- Sin restricciones de licencia empresarial
- Requisito explícito del proyecto

**Proveedor de nube: Google Cloud Platform**
- Proyecto existente: kubernetes-474008
- Región: us-central1
- Credenciales: Service Account con roles Editor y Storage Admin

**Estructura de módulos:**
- Modularización por componente de infraestructura
- Reutilización de código entre entornos
- Separación de concerns (networking, compute, storage)

#### 2.2 Estructura del Proyecto IaC

```
infrastructure/
├── opentofu/
│   ├── main.tf                 # Configuración raíz
│   ├── variables.tf            # Variables globales
│   ├── outputs.tf              # Outputs de infraestructura
│   ├── environments/
│   │   └── dev/
│   │       └── terraform.tfvars  # Valores específicos de dev
│   └── modules/
│       ├── vpc/                # Módulo de red
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── gke/                # Módulo de Kubernetes
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── cloudsql/           # Módulo de base de datos
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── artifact-registry/  # Módulo de registry
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── jenkins/            # Módulo de Jenkins (no usado)
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
└── jenkins/
    ├── Dockerfile              # Jenkins con OpenTofu y gcloud
    ├── docker-compose.yml      # Orquestación de Jenkins local
    ├── init.groovy             # Configuración inicial de seguridad
    └── start-jenkins.sh        # Script de inicio
```

### Fase 3: Implementación de Módulos OpenTofu

#### 3.1 Módulo VPC (Networking)

**Archivo: `infrastructure/opentofu/modules/vpc/main.tf`**

Componentes implementados:

1. **Red VPC principal**
   - Nombre: agendaapp-network
   - Modo: Custom (no auto-create-subnetworks)
   - Routing mode: Regional

2. **Subred para GKE**
   - CIDR primario: 10.0.0.0/24
   - Rangos secundarios:
     - gke-pods: 10.1.0.0/16 (para pods de Kubernetes)
     - gke-services: 10.2.0.0/16 (para servicios de Kubernetes)
   - Private Google Access: Habilitado

3. **Reglas de firewall**
   - allow-internal: Tráfico interno entre recursos (TCP/UDP/ICMP)
   - allow-ssh: Acceso SSH desde cualquier origen (0.0.0.0/0)

4. **Cloud Router y NAT**
   - Router regional para NAT
   - NAT configurado para permitir salida a Internet desde recursos sin IP pública
   - Auto-asignación de IPs externas

#### 3.2 Módulo GKE (Kubernetes Engine)

**Archivo: `infrastructure/opentofu/modules/gke/main.tf`**

Componentes implementados:

1. **Cluster de Kubernetes**
   - Nombre: agendaapp-cluster
   - Tipo: Standard (Autopilot deshabilitado)
   - Versión: 1.33.5-gke.1162000 (actualizada automáticamente)
   - Protección contra eliminación: false (para permitir destroy)
   - Remove default node pool: true (usar node pool personalizado)

2. **Configuración de red del cluster**
   - VPC: agendaapp-network
   - Subnetwork: agendaapp-network-gke-subnet
   - IP Allocation Policy:
     - Cluster secondary range: gke-pods
     - Services secondary range: gke-services

3. **Node Pool personalizado**
   - Nombre: default-pool
   - Tipo de máquina: e2-medium (2 vCPUs, 4GB RAM)
   - Disco: 50GB pd-standard
   - Autoscaling:
     - Mínimo: 1 nodo
     - Máximo: 3 nodos
   - Auto-repair: Habilitado
   - Auto-upgrade: Habilitado

4. **Configuración de seguridad**
   - Shielded nodes: Habilitado
   - Workload Identity: Configurado
   - Metadata server: GKE_METADATA mode

5. **Addons habilitados**
   - HTTP Load Balancing
   - Horizontal Pod Autoscaling
   - Monitoring (managed Prometheus)
   - Logging (System Components y Workloads)

#### 3.3 Módulo CloudSQL (Base de Datos)

**Archivo: `infrastructure/opentofu/modules/cloudsql/main.tf`**

Estado: **DESHABILITADO**

Razón: CloudSQL requiere configuración de Private Service Connection que no fue implementada en esta fase.

Configuración planeada (no aplicada):
- Instancia PostgreSQL 13
- Tier: db-f1-micro
- Disco: 10GB SSD
- Alta disponibilidad: Deshabilitada
- Backup automático: Configurado

Alternativa actual:
- PostgreSQL desplegado como pod en el cluster GKE
- PersistentVolume para datos
- No recomendado para producción

#### 3.4 Módulo Artifact Registry

**Archivo: `infrastructure/opentofu/modules/artifact-registry/main.tf`**

Componentes implementados:

1. **Repositorio Docker**
   - Nombre: agendaapp
   - Formato: DOCKER
   - Ubicación: us-central1
   - Modo: STANDARD_REPOSITORY
   - Descripción: Almacenamiento de imágenes Docker de AgendaApp

2. **Configuración de acceso**
   - URL: us-central1-docker.pkg.dev/kubernetes-474008/agendaapp
   - Autenticación vía Service Account
   - Integración con docker login

### Fase 4: Configuración de Variables y Outputs

#### 4.1 Variables de Entorno

**Archivo: `infrastructure/opentofu/environments/dev/terraform.tfvars`**

```hcl
project_id     = "kubernetes-474008"
region         = "us-central1"
environment    = "dev"

# VPC Configuration
network_name   = "agendaapp-network"
subnet_cidr    = "10.0.0.0/24"
pods_cidr      = "10.1.0.0/16"
services_cidr  = "10.2.0.0/16"

# GKE Configuration
gke_cluster_name = "agendaapp-cluster"
node_pools = [
  {
    name         = "default-pool"
    machine_type = "e2-medium"
    min_count    = 1
    max_count    = 3
    disk_size_gb = 50
  }
]

# Artifact Registry
artifact_registry_name = "agendaapp"

# CloudSQL (comentado)
# db_instance_name = "agendaapp-postgres"
# db_tier          = "db-f1-micro"
```

#### 4.2 Outputs de Infraestructura

**Archivo: `infrastructure/opentofu/outputs.tf`**

Outputs activos:
- gke_cluster_name: Nombre del cluster GKE
- gke_cluster_endpoint: Endpoint del API server (sensible)
- vpc_network_name: Nombre de la VPC creada
- artifact_registry_url: URL completa del registry

Outputs deshabilitados:
- cloudsql_connection_name
- cloudsql_private_ip

### Fase 5: Integración con Jenkins para Automatización Completa

El objetivo de esta fase es crear un pipeline único que maneje tanto la infraestructura (IaC) como el despliegue de la aplicación, eliminando la necesidad de intervención manual.

#### 5.1 Creación de Service Account en GCP

Comando ejecutado:

```bash
gcloud iam service-accounts create jenkins-iac-sa \
  --display-name="Jenkins IaC Automation" \
  --project=kubernetes-474008
```

Permisos asignados:

```bash
# Rol de Editor (gestión completa de recursos)
gcloud projects add-iam-policy-binding kubernetes-474008 \
  --member="serviceAccount:jenkins-iac-sa@kubernetes-474008.iam.gserviceaccount.com" \
  --role="roles/editor"

# Rol de Storage Admin (gestión de state)
gcloud projects add-iam-policy-binding kubernetes-474008 \
  --member="serviceAccount:jenkins-iac-sa@kubernetes-474008.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

Generación de credenciales:

```bash
gcloud iam service-accounts keys create \
  infrastructure/jenkins-iac-credentials.json \
  --iam-account=jenkins-iac-sa@kubernetes-474008.iam.gserviceaccount.com
```

#### 5.2 Construcción de Imagen Jenkins Personalizada

**Archivo: `infrastructure/jenkins/Dockerfile`**

Componentes instalados:

1. **Base image**
   - jenkins/jenkins:lts (versión 2.528.1)

2. **Dependencias del sistema**
   - curl, gnupg, lsb-release
   - unzip
   - python3 y python3-pip

3. **Google Cloud SDK**
   - Repositorio oficial de Google
   - Versión 546.0.0
   - Componentes: gcloud, gsutil, bq
   - **Plugin GKE**: google-cloud-cli-gke-gcloud-auth-plugin (CRÍTICO para kubectl)

4. **OpenTofu**
   - Instalación vía script oficial
   - Versión 1.10.7
   - Método: Paquete DEB

5. **kubectl**
   - Versión estable más reciente (v1.34.1)
   - Instalado en /usr/local/bin/kubectl

6. **Docker CLI**
   - Docker Engine Community 28.5.2
   - docker-buildx-plugin para multi-arquitectura
   - Necesario para construir imágenes dentro de Jenkins

7. **Plugins de Jenkins pre-instalados**
   - workflow-aggregator (Pipeline)
   - git
   - credentials
   - google-compute-engine
   - kubernetes

#### 5.3 Orquestación con Docker Compose

**Archivo: `infrastructure/jenkins/docker-compose.yml`**

Configuración:

```yaml
services:
  jenkins:
    build: .
    container_name: jenkins-iac
    restart: unless-stopped
    ports:
      - "8080:8080"  # Web UI
      - "50000:50000"  # Agentes
    volumes:
      - jenkins_home:/var/jenkins_home  # Persistencia
      - ../opentofu:/workspace/infrastructure/opentofu  # Código IaC
      - ../../AgendaApp:/workspace/AgendaApp  # Código de la aplicación
      - ../jenkins-iac-credentials.json:/var/secrets/gcp/key.json:ro  # Credenciales
      - /var/run/docker.sock:/var/run/docker.sock  # Docker socket (REQUERIDO)
    environment:
      - GOOGLE_APPLICATION_CREDENTIALS=/var/secrets/gcp/key.json
    user: root  # Para acceso a Docker socket
```

Cambios realizados:
- Volumen opentofu inicialmente montado como :ro (read-only)
- Cambiado a lectura-escritura para permitir .terraform/
- **Agregado volumen AgendaApp**: Permite a Jenkins acceder al código fuente para construir imágenes
- **Docker socket montado**: Esencial para que Jenkins pueda ejecutar `docker build` y `docker push`
- Eliminado JAVA_OPTS de setup wizard (causaba problemas)

#### 5.4 Pipeline Unificado: Infraestructura + Aplicación

**Script Groovy: `jenkins-pipeline-script.groovy`**

Pipeline completo de 13 etapas que automatiza desde la creación de infraestructura hasta el despliegue de la aplicación:

```groovy
pipeline {
    agent any
    
    environment {
        // Proyecto GCP
        GCP_PROJECT = 'kubernetes-474008'
        GCP_REGION = 'us-central1'
        
        // Directorios
        TOFU_DIR = '/workspace/infrastructure/opentofu'
        APP_DIR = '/workspace/AgendaApp'
        
        // Artifact Registry
        ARTIFACT_REGISTRY = 'us-central1-docker.pkg.dev'
        REGISTRY_REPO = 'kubernetes-474008/agendaapp'
        FRONTEND_IMAGE = "${ARTIFACT_REGISTRY}/${REGISTRY_REPO}/frontend"
        BACKEND_IMAGE = "${ARTIFACT_REGISTRY}/${REGISTRY_REPO}/backend"
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        CLOUDSDK_PYTHON = '/usr/bin/python3'
    }
}
```

**Etapas del Pipeline:**

**FASE 1: INFRAESTRUCTURA (OpenTofu)**

1. **Preparar Entorno**
   - Verifica tofu, gcloud, docker, kubectl
   - Valida que todas las herramientas estén disponibles

2. **Autenticar GCP**
   - Usa withCredentials para seguridad
   - Ejecuta gcloud auth activate-service-account
   - Configura proyecto activo

3. **Inicializar OpenTofu**
   - Ejecuta tofu init -reconfigure
   - Descarga providers (google, google-beta)
   - Inicializa módulos (vpc, gke, artifact-registry)

4. **Validar IaC**
   - Ejecuta tofu validate
   - Verifica sintaxis HCL
   - Valida referencias entre recursos

5. **Generar Plan**
   - Ejecuta tofu plan con terraform.tfvars
   - Muestra recursos a crear/modificar/destruir
   - Guarda plan binario

6. **Aplicar Infraestructura**
   - Ejecuta tofu apply -auto-approve
   - Crea VPC, GKE Cluster, Artifact Registry
   - Sin intervención manual

**FASE 2: APLICACIÓN (Docker + Kubernetes)**

7. **Configurar kubectl**
   - Obtiene credenciales del cluster GKE
   - Usa gke-gcloud-auth-plugin para autenticación
   - Verifica conectividad con kubectl get nodes

8. **Construir Imágenes Docker**
   - Backend: Construye desde AgendaApp/backend/Dockerfile
   - Frontend: Construye desde AgendaApp/frontend/Dockerfile
   - Tagea con número de build y 'latest'

9. **Subir a Artifact Registry**
   - Configura docker auth para Artifact Registry
   - Push backend:${BUILD_NUMBER} y backend:latest
   - Push frontend:${BUILD_NUMBER} y frontend:latest

10. **Desplegar Aplicación en GKE**
    - Aplica postgres-pvc.yaml y postgres-deployment.yaml
    - Aplica backend-postgres-working.yaml
    - Aplica frontend-deployment.yaml
    - Actualiza imágenes con kubectl set image

11. **Verificar Despliegue**
    - Lista pods con kubectl get pods
    - Lista servicios con kubectl get services
    - Obtiene IPs externas de LoadBalancers
    - Muestra URLs de acceso

**FASE 3: POST-DESPLIEGUE**

12. **Success Handler**
    - Muestra resumen completo del despliegue
    - Imprime URLs del frontend y backend
    - Confirma que todo está operativo

13. **Failure Handler**
    - Diagnóstico de errores
    - Muestra posibles causas
    - Guía para troubleshooting

### Fase 6: Solución al Problema de IPs Dinámicas

#### 6.1 El Problema Original

El frontend tenía la URL del backend hardcodeada en `app.js`:

```javascript
const API_BASE_URL = 'http://34.71.155.58:5000';  // IP antigua que cambia
```

**Consecuencias:**
- Cada vez que se recreaban los servicios LoadBalancer, cambiaba la IP
- El frontend dejaba de funcionar
- Había que editar manualmente app.js con la nueva IP
- No era escalable ni mantenible

#### 6.2 La Solución Implementada

**Enfoque:** Generar la configuración dinámicamente al iniciar el contenedor

**Archivos creados:**

1. **entrypoint.sh** (script de inicio del contenedor frontend):
```bash
#!/bin/sh
# Genera config.js dinámicamente con la URL del backend

BACKEND_URL=${BACKEND_URL:-"http://backend-postgres-service:5000"}

cat > /usr/share/nginx/html/config.js <<EOF
window.BACKEND_SERVICE_URL = '$BACKEND_URL';

function getBackendURL() {
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
        return 'http://localhost:5000';
    }
    return window.BACKEND_SERVICE_URL;
}

const API_BASE_URL = getBackendURL();
EOF

exec nginx -g 'daemon off;'
```

2. **Modificación de app.js**:
```javascript
// Ya no define API_BASE_URL aquí
// Lo obtiene de config.js generado dinámicamente
```

3. **Modificación de index.html**:
```html
<!-- Cargar config.js ANTES de app.js -->
<script src="config.js"></script>
<script src="app.js"></script>
```

4. **Actualización de Dockerfile del frontend**:
```dockerfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

**Ventajas:**
- ✅ La URL del backend se configura mediante variable de entorno
- ✅ Funciona en desarrollo (localhost) y producción (GKE)
- ✅ No requiere recompilar la imagen al cambiar IPs
- ✅ Se puede inyectar la URL via ConfigMap de Kubernetes

**Uso en Kubernetes:**
```yaml
env:
  - name: BACKEND_URL
    value: "http://34.41.85.14:5000"  # Se actualiza automáticamente
```

### Fase 7: Resolución de Problemas Técnicos

#### 7.1 Problema: Credenciales no encontradas

**Error:**
```
ERROR: Could not find credentials entry with ID 'gcp-jenkins-iac-credentials'
```

**Causa:**
Credenciales no agregadas correctamente en Jenkins

**Solución:**
1. Navegar a Manage Jenkins > Credentials > System > Global credentials
2. Add Credentials con los parámetros exactos:
   - Kind: Secret file
   - File: jenkins-iac-credentials.json
   - ID: gcp-jenkins-iac-credentials (exacto)
   - Description: GCP Service Account for IaC

#### 7.2 Problema: Sistema de archivos read-only

**Error:**
```
Error: Failed to update module manifest
Unable to write the module manifest file: open .terraform/modules/modules.json: read-only file system
```

**Causa:**
Volumen montado con flag :ro en docker-compose.yml

**Solución:**
1. Modificar docker-compose.yml:
   ```yaml
   # ANTES
   - ../opentofu:/workspace/infrastructure/opentofu:ro
   
   # DESPUÉS
   - ../opentofu:/workspace/infrastructure/opentofu
   ```

2. Recrear contenedor:
   ```bash
   docker compose down
   docker compose up -d
   ```

#### 7.3 Problema: Cloud Resource Manager API deshabilitada

**Warning (no crítico):**
```
Cloud Resource Manager API has not been used in project 276448872103 before or it is disabled
```

**Causa:**
API no habilitada en el proyecto

**Impacto:**
Advertencia únicamente, no impide funcionamiento del pipeline

**Solución futura:**
Habilitar API desde consola GCP o añadir a Service Account

#### 7.4 Problema: CloudSQL requiere private service connection

**Error durante tofu apply:**
```
Error creating CloudSQL instance: requires Private Service Connection
```

**Causa:**
CloudSQL con private IP requiere configuración adicional de VPC peering

**Solución temporal:**
Deshabilitar módulo CloudSQL:
1. Comentar en main.tf
2. Comentar outputs relacionados
3. Usar PostgreSQL en pods (no producción)

**Solución definitiva (pendiente):**
Implementar google_service_networking_connection en módulo VPC

#### 7.5 Problema: Docker no encontrado en Jenkins

**Error:**
```
docker: not found
script returned exit code 127
```

**Causa:**
Jenkins no tenía Docker CLI instalado, necesario para construir imágenes

**Solución:**
Agregar Docker CLI al Dockerfile de Jenkins:
```dockerfile
# Instalar Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-buildx-plugin && \
    rm -rf /var/lib/apt/lists/*
```

Reconstruir imagen:
```bash
docker compose build --no-cache
docker compose up -d
```

#### 7.6 Problema: gke-gcloud-auth-plugin no encontrado

**Error:**
```
executable gke-gcloud-auth-plugin not found
Unable to connect to the server
```

**Causa:**
kubectl requiere el plugin de autenticación de GKE para conectarse a clusters

**Solución:**
Instalar el plugin junto con Google Cloud SDK:
```dockerfile
apt-get install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin
```

Este plugin es crítico para que kubectl pueda autenticarse con GKE clusters.

#### 7.7 Problema: Nombre de contenedor incorrecto en kubectl set image

**Error:**
```
kubectl set image deployment/backend-postgres backend-postgres=...
error: unable to find container named "backend-postgres"
```

**Causa:**
El comando intenta actualizar un contenedor llamado `backend-postgres`, pero el contenedor real se llama `backend`

**Diagnóstico:**
```bash
kubectl get deployment backend-postgres -o=jsonpath='{.spec.template.spec.containers[*].name}'
# Resultado: backend
```

**Solución:**
Usar el nombre real del contenedor:
```bash
# INCORRECTO
kubectl set image deployment/backend-postgres backend-postgres=image:tag

# CORRECTO  
kubectl set image deployment/backend-postgres backend=image:tag
```

**Causa raíz:**
En Kubernetes, el nombre del deployment y el nombre del contenedor son independientes:
- Deployment: `backend-postgres`
- Contenedor dentro: `backend`

### Fase 8: Estado Actual del Proyecto

#### 8.1 Infraestructura Desplegada

**Recursos gestionados por OpenTofu:**
- 1 VPC network (agendaapp-network)
- 1 Subnet con rangos secundarios
- 2 Firewall rules (allow-internal, allow-ssh)
- 1 Cloud Router
- 1 Cloud NAT
- 1 GKE Cluster (agendaapp-cluster)
- 1 Node Pool (1-3 nodos e2-medium)
- 1 Artifact Registry (agendaapp)

**Total: 8-10 recursos en terraform.tfstate**

#### 8.2 Herramientas en Funcionamiento

**Jenkins:**
- URL: http://localhost:8080
- Usuario: admin
- Estado: Running en Docker
- Pipeline: agendaapp-infrastructure-auto (configurado)

**OpenTofu:**
- Versión: 1.10.6
- Providers: google ~>5.0, google-beta ~>5.0
- State: Local (terraform.tfstate)
- Módulos: 4 activos (vpc, gke, artifact-registry, jenkins-no-usado)

#### 8.3 Flujo de Trabajo Actual

**Para desplegar todo (Infraestructura + Aplicación):**

1. Acceder a Jenkins: http://localhost:8080
   - Usuario: admin
   - Contraseña: 6cdc4ab5fc1040cf8109c019d719f108

2. Abrir pipeline: `agendaapp-infrastructure-auto`

3. Click en **"Build Now"**

4. El pipeline ejecutará automáticamente:
   - ✅ Creación de infraestructura con OpenTofu (VPC, GKE, Artifact Registry)
   - ✅ Construcción de imágenes Docker (Frontend y Backend)
   - ✅ Subida de imágenes a Artifact Registry
   - ✅ Despliegue de aplicación en GKE (PostgreSQL, Backend, Frontend)
   - ✅ Verificación y obtención de URLs

5. Al finalizar, el pipeline mostrará las URLs de acceso:
   ```
   Frontend: http://<IP_EXTERNA>
   Backend:  http://<IP_EXTERNA>:5000
   ```

**Para hacer cambios:**

- **Cambios en infraestructura**: Modificar archivos .tf y ejecutar pipeline
- **Cambios en aplicación**: Modificar código, ejecutar pipeline (reconstruye imágenes)
- **Todo es automático**: Un solo click despliega todo

Para destruir infraestructura:

```bash
cd infrastructure/opentofu
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
tofu destroy -var-file=environments/dev/terraform.tfvars -auto-approve
```

### Fase 9: Próximos Pasos

#### 9.1 Infraestructura Pendiente

1. **Implementar CloudSQL con Private Service Connection**
   - Configurar google_compute_global_address para rango de peering
   - Crear google_service_networking_connection
   - Activar CloudSQL module en main.tf

2. **Migrar state a GCS (Google Cloud Storage)**
   - Crear bucket para state remoto
   - Configurar backend en main.tf
   - Ejecutar tofu init -migrate-state

3. **Implementar Terraform Workspaces**
   - Separar entornos: dev, staging, prod
   - Variables específicas por workspace
   - State separado por entorno

#### 9.2 Mejoras al Pipeline

1. **Tests Automatizados**
   - Unit tests del backend antes del build
   - Integration tests después del despliegue
   - Smoke tests de los endpoints
   - Health checks automáticos

2. **Integración con Git**
   - Configurar webhook de GitHub/GitLab
   - Trigger automático en push
   - Revisión de código antes de deploy

3. **Rollback Automático**
   - Detección de fallos post-despliegue
   - Rollback a versión anterior
   - Notificaciones de errores

4. **Monitoreo y Observabilidad**
   - Configurar Google Cloud Monitoring
   - Alertas de infraestructura
   - Dashboards de métricas

#### 9.3 Seguridad y Buenas Prácticas

1. **Secrets Management**
   - Migrar a Google Secret Manager
   - Eliminar credenciales en archivos
   - Rotación automática de keys

2. **Network Security**
   - Implementar Private GKE Cluster
   - Configurar Cloud Armor
   - Habilitar Binary Authorization

3. **Disaster Recovery**
   - Backups automáticos de state
   - Plan de recuperación documentado
   - Pruebas periódicas de restore

---

## Comandos de Referencia

### OpenTofu Local

```bash
# Inicializar
cd infrastructure/opentofu
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
tofu init

# Validar
tofu validate

# Plan
tofu plan -var-file=environments/dev/terraform.tfvars

# Apply
tofu apply -var-file=environments/dev/terraform.tfvars

# Destroy
tofu destroy -var-file=environments/dev/terraform.tfvars

# Listar recursos
tofu state list

# Ver output específico
tofu output gke_cluster_name
```

### Jenkins Docker

```bash
# Iniciar
cd infrastructure/jenkins
docker compose up -d

# Ver logs
docker logs jenkins-iac -f

# Reiniciar
docker compose restart

# Detener
docker compose down

# Reconstruir imagen
docker compose build --no-cache
docker compose up -d

# Acceder al contenedor
docker exec -it jenkins-iac bash
```

### GKE y kubectl

```bash
# Configurar kubectl
gcloud container clusters get-credentials agendaapp-cluster \
  --region=us-central1 \
  --project=kubernetes-474008

# Verificar nodos
kubectl get nodes

# Ver pods
kubectl get pods --all-namespaces

# Aplicar manifiestos
kubectl apply -f AgendaApp/k8s/

# Ver servicios
kubectl get services

# Logs de pod
kubectl logs <pod-name>
```

### Artifact Registry

```bash
# Configurar Docker
gcloud auth configure-docker us-central1-docker.pkg.dev

# Tag de imagen
docker tag agendaapp-frontend:latest \
  us-central1-docker.pkg.dev/kubernetes-474008/agendaapp/frontend:latest

# Push de imagen
docker push \
  us-central1-docker.pkg.dev/kubernetes-474008/agendaapp/frontend:latest

# Listar imágenes
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/kubernetes-474008/agendaapp
```

---

## Referencias Técnicas

### Documentación Oficial

- OpenTofu: https://opentofu.org/docs/
- Google Cloud Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- GKE: https://cloud.google.com/kubernetes-engine/docs
- Jenkins Pipeline: https://www.jenkins.io/doc/book/pipeline/

### Versiones Utilizadas

- OpenTofu: 1.10.7
- Google Cloud SDK: 546.0.0
- Google Cloud GKE Auth Plugin: Incluido
- Jenkins: 2.528.1 LTS
- kubectl: Client 1.34.1
- Docker CE CLI: 28.5.2
- Docker Buildx Plugin: Incluido
- GKE: 1.33.5-gke.1162000
- Docker Compose: v2
- Nginx (frontend): 1.25-alpine
- Python (backend): 3.9-slim
- PostgreSQL: 13

### Estructura de Archivos del Proyecto

```
/home/teriyaki/Música/big data/
├── AgendaApp/                          # Aplicación
│   ├── backend/                        # Backend Python/Flask
│   ├── frontend/                       # Frontend HTML/JS
│   ├── k8s/                            # Manifiestos Kubernetes
│   └── helm/                           # Charts Helm
├── infrastructure/                     # IaC
│   ├── opentofu/                       # Configuración OpenTofu
│   │   ├── main.tf                     # Raíz
│   │   ├── variables.tf                # Variables globales
│   │   ├── outputs.tf                  # Outputs
│   │   ├── terraform.tfstate           # State local
│   │   ├── environments/               # Configuración por entorno
│   │   │   └── dev/
│   │   │       └── terraform.tfvars
│   │   └── modules/                    # Módulos reutilizables
│   │       ├── vpc/
│   │       ├── gke/
│   │       ├── cloudsql/
│   │       └── artifact-registry/
│   ├── jenkins/                        # Jenkins local
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   ├── init.groovy
│   │   └── start-jenkins.sh
│   ├── jenkins-iac-credentials.json    # Service Account
│   ├── jenkins-pipeline-script.groovy  # Script del pipeline
│   ├── JENKINS-SETUP.md                # Guía de configuración
│   └── README.md                       # Este documento
└── README.md                           # README principal
```

---

---

## Guía Rápida de Uso

### Inicio Rápido

1. **Levantar Jenkins:**
   ```bash
   cd infrastructure/jenkins
   docker compose up -d
   ```

2. **Acceder a Jenkins:**
   - URL: http://localhost:8080
   - Usuario: `admin`
   - Contraseña: `6cdc4ab5fc1040cf8109c019d719f108`

3. **Ejecutar Pipeline:**
   - Ir a `agendaapp-infrastructure-auto`
   - Click en **"Build Now"**
   - Esperar ~10-15 minutos

4. **Acceder a la Aplicación:**
   - El pipeline mostrará las URLs al finalizar
   - Frontend: `http://<IP_MOSTRADA>`
   - Backend: `http://<IP_MOSTRADA>:5000`

### Comandos Útiles

```bash
# Ver logs de Jenkins
docker logs jenkins-iac -f

# Reiniciar Jenkins
cd infrastructure/jenkins
docker compose restart

# Detener todo
docker compose down

# Ver estado de la infraestructura
cd infrastructure/opentofu
tofu state list

# Ver pods en GKE
kubectl get pods
kubectl get services

# Destruir infraestructura (cuidado!)
cd infrastructure/opentofu
tofu destroy -var-file=environments/dev/terraform.tfvars
```

### Solución de Problemas Comunes

**Jenkins no inicia:**
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

**Pipeline falla en Docker:**
- Verificar: `docker exec jenkins-iac docker ps`
- Si falla, reconstruir imagen con Docker CLI

**Pipeline falla en kubectl:**
- Verificar que gke-gcloud-auth-plugin esté instalado
- Reconstruir imagen de Jenkins

**IPs del frontend/backend no funcionan:**
- Esperar 2-3 minutos a que LoadBalancers obtengan IPs
- Verificar con: `kubectl get services`

---

## Conclusión

Este proyecto implementa una solución completa de Infraestructura como Código utilizando OpenTofu y Jenkins para la gestión automatizada de recursos en Google Cloud Platform. La arquitectura modular permite escalabilidad, mantenibilidad y replicabilidad del entorno, estableciendo las bases para un flujo de trabajo DevOps maduro.

### Logros Alcanzados

✅ **Automatización Completa**: Un solo pipeline gestiona infraestructura y aplicación
✅ **Infraestructura como Código**: Todo versionado y reproducible con OpenTofu
✅ **CI/CD Funcional**: Jenkins construye, sube y despliega automáticamente
✅ **Configuración Dinámica**: Frontend se adapta a cambios de IPs automáticamente
✅ **Escalabilidad**: GKE con autoscaling de 1-3 nodos
✅ **Alta Disponibilidad**: LoadBalancers para servicios públicos
✅ **Artifact Registry**: Gestión centralizada de imágenes Docker

### Capacidades del Sistema

- Despliegue consistente y reproducible de infraestructura
- Versionado completo de cambios en infraestructura y aplicación
- Automatización total: desde código hasta producción en un click
- Validación previa de cambios mediante planes de OpenTofu
- Rollback controlado en caso de errores
- Separación de responsabilidades (IaC, aplicación, configuración)

### Trabajo Futuro

Las siguientes fases del proyecto incluirán:
- Implementación de CloudSQL con private connectivity
- Migración a state remoto (GCS) para trabajo en equipo
- Tests automatizados en el pipeline
- Integración con Git (webhooks automáticos)
- Monitoreo y alertas con Google Cloud Monitoring
- Implementación de múltiples entornos (dev/staging/prod)
