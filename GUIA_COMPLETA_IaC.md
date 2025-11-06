# 🚀 Guía Completa - Infrastructure as Code con OpenTofu y Jenkins

## 📋 Índice
1. [¿Qué hemos construido?](#qué-hemos-construido)
2. [¿Cómo funciona todo?](#cómo-funciona-todo)
3. [Componentes del Sistema](#componentes-del-sistema)
4. [Guía de Uso Paso a Paso](#guía-de-uso-paso-a-paso)
5. [Acceder a Jenkins](#acceder-a-jenkins)
6. [Configurar el Pipeline](#configurar-el-pipeline)
7. [¿Qué puedes hacer a futuro?](#qué-puedes-hacer-a-futuro)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 ¿Qué hemos construido?

Has implementado una **solución profesional de Infrastructure as Code (IaC)** para tu aplicación AgendaApp. Esto significa que ahora puedes:

✅ **Definir toda tu infraestructura como código** (archivos .tf)
✅ **Automatizar el despliegue** con un solo comando
✅ **Versionar tu infraestructura** en Git
✅ **Replicar ambientes** fácilmente (dev, staging, producción)
✅ **Pipeline de CI/CD automático** con Jenkins

### Estado Actual de tu Infraestructura:

```
┌─────────────────────────────────────────────────┐
│          Google Cloud Platform (GCP)            │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │     GKE Cluster (agendaapp-cluster)      │  │
│  │                                          │  │
│  │  ┌─────────────┐  ┌──────────────────┐  │  │
│  │  │  Frontend   │  │    Backend       │  │  │
│  │  │  3 replicas │  │    3 replicas    │  │  │
│  │  │  Nginx      │  │    Flask+Python  │  │  │
│  │  │             │  │                  │  │  │
│  │  │ 34.70.X.X   │  │  34.71.X.X:5000  │  │  │
│  │  └─────────────┘  └──────────────────┘  │  │
│  │                                          │  │
│  │  ┌─────────────┐  ┌──────────────────┐  │  │
│  │  │ PostgreSQL  │  │    Jenkins       │  │  │
│  │  │  1 replica  │  │    1 replica     │  │  │
│  │  │  PG 14      │  │    CI/CD Server  │  │  │
│  │  │             │  │                  │  │  │
│  │  │ (interno)   │  │  35.232.149.227  │  │  │
│  │  └─────────────┘  └──────────────────┘  │  │
│  │                                          │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │      Artifact Registry                   │  │
│  │      (Repositorio de imágenes Docker)    │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🔧 ¿Cómo funciona todo?

### 1. **Infrastructure as Code (OpenTofu)**

OpenTofu lee tus archivos `.tf` y los convierte en recursos reales en Google Cloud:

```
Archivos .tf  →  OpenTofu  →  API de Google Cloud  →  Recursos Creados
  (código)      (procesa)      (crea/actualiza)        (infraestructura)
```

**Ejemplo:** Cuando escribes esto en `main.tf`:

```hcl
module "vpc" {
  source = "./modules/vpc"
  network_name = "agendaapp-network"
}
```

OpenTofu automáticamente:
1. Lee la configuración
2. Llama a la API de Google Cloud
3. Crea la red VPC
4. Configura subnets, firewall, NAT, etc.

### 2. **Pipeline de CI/CD (Jenkins)**

Cada vez que haces un commit a tu repositorio Git:

```
1. Git Push
   ↓
2. Jenkins detecta el cambio
   ↓
3. Ejecuta tests automáticos
   ↓
4. Construye imágenes Docker
   ↓
5. Sube imágenes a Artifact Registry
   ↓
6. Actualiza aplicación en Kubernetes
   ↓
7. Verifica que todo funcione (smoke test)
   ↓
8. ✅ Aplicación desplegada automáticamente
```

---

## 📦 Componentes del Sistema

### 1. **Módulos de OpenTofu**

#### 📁 `modules/vpc/` - Red Virtual Privada
**¿Qué hace?**
- Crea una red aislada para tus recursos
- Define rangos de IPs
- Configura firewall
- Habilita NAT para acceso a internet

**Archivos:**
- `main.tf`: Define la red, subnets, firewall, router y NAT
- `variables.tf`: Parámetros configurables
- `outputs.tf`: Información que otros módulos pueden usar

**Lo más importante:**
```hcl
# Crea una red VPC
resource "google_compute_network" "vpc" {
  name = "agendaapp-network"
  auto_create_subnetworks = false
}

# Crea subnet con rangos para GKE
resource "google_compute_subnetwork" "subnets" {
  name          = "agendaapp-network-gke-subnet"
  ip_cidr_range = "10.0.0.0/24"
  
  # Rangos adicionales para pods y servicios de Kubernetes
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.1.0.0/16"  # 65,536 IPs para pods
  }
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.2.0.0/16"  # 65,536 IPs para servicios
  }
}
```

#### 📁 `modules/gke/` - Cluster de Kubernetes
**¿Qué hace?**
- Crea el cluster de Kubernetes
- Configura pools de nodos con autoscaling
- Habilita Workload Identity (seguridad)
- Configura mantenimiento automático

**Configuración actual:**
- **Nodos:** e2-medium (2 vCPU, 4GB RAM)
- **Autoscaling:** 1-3 nodos (se adapta a la carga)
- **Ubicación:** us-central1 (regional = alta disponibilidad)

#### 📁 `modules/cloudsql/` - Base de Datos PostgreSQL
**¿Qué hace?**
- Crea instancia de PostgreSQL 14
- Configura backups automáticos
- Establece red privada (sin acceso público)
- Define base de datos y usuario

**Seguridad:**
- ✅ Solo accesible desde dentro de la VPC
- ✅ Backups diarios a las 3 AM
- ✅ SSL obligatorio
- ✅ Máximo 100 conexiones simultáneas

#### 📁 `modules/artifact-registry/` - Registro de Imágenes
**¿Qué hace?**
- Almacena tus imágenes Docker
- Permite versionar imágenes
- Integración con GKE para deploys

**URL del registry:**
```
us-central1-docker.pkg.dev/kubernetes-474008/agendaapp
```

#### 📁 `modules/jenkins/` - Servidor CI/CD
**¿Qué hace?**
- Despliega Jenkins en Kubernetes
- Crea service account con permisos necesarios
- Configura almacenamiento persistente
- Expone servicio con LoadBalancer

---

## 📖 Guía de Uso Paso a Paso

### Paso 1: Acceder a tu Infraestructura

#### Ver todos los recursos desplegados:
```bash
# Configurar variables de entorno
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Ver pods en Kubernetes
kubectl get pods --all-namespaces

# Ver servicios con IPs externas
kubectl get svc --all-namespaces

# Ver estado del cluster
kubectl cluster-info
```

#### Resultado esperado:
```
NAMESPACE     NAME                          READY   STATUS    IP EXTERNA
default       backend-postgres-xxx          1/1     Running   34.71.155.58
default       frontend-xxx                  1/1     Running   34.70.211.16
default       postgres-xxx                  1/1     Running   (interno)
jenkins       jenkins-xxx                   1/1     Running   35.232.149.227
```

---

## 🎨 Acceder a Jenkins

### 1. **Obtener la IP de Jenkins:**
```bash
kubectl get svc -n jenkins
```

**Tu IP de Jenkins:** `http://35.232.149.227:8080`

### 2. **Acceder por primera vez:**

Como desactivamos el wizard de instalación inicial, Jenkins está listo pero necesitas configurar credenciales manualmente.

**Opción A - Crear usuario admin manualmente:**
```bash
# Entrar al pod de Jenkins
kubectl exec -it -n jenkins $(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -- /bin/bash

# Dentro del pod, crear usuario admin
cat > /var/jenkins_home/init.groovy.d/basic-security.groovy <<'EOF'
#!groovy
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)
instance.save()

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)
instance.save()
EOF

# Reiniciar Jenkins
exit

# Desde tu terminal local, reinicia el pod
kubectl delete pod -n jenkins -l app=jenkins
```

**Credenciales:**
- Usuario: `admin`
- Password: `admin123` (cámbialo después)

### 3. **Instalar Plugins Necesarios:**

Una vez dentro de Jenkins:

1. Ve a: **Manage Jenkins** → **Manage Plugins** → **Available**
2. Busca e instala:
   - ✅ **Docker Pipeline**
   - ✅ **Google Kubernetes Engine Plugin**
   - ✅ **Git Plugin**
   - ✅ **Pipeline Plugin**
   - ✅ **Kubernetes Plugin**

3. Reinicia Jenkins después de instalar

---

## ⚙️ Configurar el Pipeline

### 1. **Configurar Credenciales de GCP:**

**Opción más simple - Usar gcloud auth:**
```bash
# En tu terminal local
gcloud auth application-default print-access-token
```

En Jenkins:
1. **Manage Jenkins** → **Manage Credentials**
2. **(global)** → **Add Credentials**
3. Tipo: **Secret text**
4. Secret: (pega el token de arriba)
5. ID: `gcp-token`

### 2. **Crear Pipeline Job:**

1. **New Item** → Nombre: `agendaapp-pipeline` → **Pipeline** → OK

2. En **Pipeline** section:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `[URL de tu repositorio]`
   - Branch: `*/main` o `*/master`
   - Script Path: `Jenkinsfile`

3. **Build Triggers:**
   - ✅ Poll SCM: `H/5 * * * *` (revisa cada 5 minutos)
   - O configura webhook de GitHub/GitLab

4. **Save**

### 3. **Primer Build:**

1. Click en **Build Now**
2. Ve a **Console Output** para ver el progreso
3. El pipeline ejecutará todas las etapas

---

## 🚀 ¿Qué puedes hacer a futuro?

### 🎯 **Mejoras Inmediatas (Nivel Básico)**

#### 1. **Agregar más tests**
```python
# En AgendaApp/backend/tests/test_app.py
def test_create_task():
    response = client.post('/tasks', json={
        'title': 'Nueva Tarea',
        'description': 'Descripción de prueba'
    })
    assert response.status_code == 201

def test_get_tasks():
    response = client.get('/tasks')
    assert response.status_code == 200
    assert isinstance(response.json, list)
```

#### 2. **Agregar healthcheck más robusto**
```python
# En app.py
@app.route('/health')
def health():
    try:
        # Verificar conexión a base de datos
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        conn.close()
        
        return jsonify({
            'status': 'healthy',
            'database': 'connected',
            'timestamp': datetime.now().isoformat()
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 503
```

#### 3. **Configurar notificaciones en Jenkins**
```groovy
// Agregar al final del Jenkinsfile
post {
    success {
        echo "✅ Deploy exitoso!"
        // Enviar email o Slack notification
    }
    failure {
        echo "❌ Deploy falló!"
        // Alertar al equipo
    }
}
```

### 🎯 **Mejoras Intermedias (Nivel Medio)**

#### 1. **Implementar Ambientes (Dev, Staging, Prod)**

**Estructura:**
```
infrastructure/opentofu/environments/
├── dev/
│   └── terraform.tfvars
├── staging/
│   └── terraform.tfvars
└── prod/
    └── terraform.tfvars
```

**Ejemplo staging:**
```hcl
# staging/terraform.tfvars
project_id = "kubernetes-474008"
region     = "us-central1"
environment = "staging"
gke_min_node_count = 2
gke_max_node_count = 5
```

**Deploy a staging:**
```bash
cd infrastructure/opentofu
tofu plan -var-file=environments/staging/terraform.tfvars
tofu apply -var-file=environments/staging/terraform.tfvars
```

#### 2. **Blue-Green Deployment**

Modifica el Jenkinsfile para hacer deploys sin downtime:

```groovy
stage('Blue-Green Deploy') {
    steps {
        script {
            // Crear nueva versión (green)
            sh """
                kubectl apply -f k8s/backend-deployment-green.yaml
                kubectl wait --for=condition=ready pod -l app=backend,version=green --timeout=300s
            """
            
            // Cambiar tráfico a green
            sh """
                kubectl patch svc backend-service -p '{"spec":{"selector":{"version":"green"}}}'
            """
            
            // Eliminar versión anterior (blue)
            sh """
                sleep 30
                kubectl delete deployment backend-blue || true
            """
        }
    }
}
```

#### 3. **Monitoring y Logs**

**Instalar Prometheus y Grafana:**
```bash
# Agregar repo de Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Ver servicios
kubectl get svc -n monitoring
```

**Acceder a Grafana:**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Dashboards recomendados:
- Kubernetes Cluster Monitoring
- Node Exporter Full
- PostgreSQL Database

#### 4. **Agregar Redis para Caché**

**Crear módulo de Redis:**
```hcl
# modules/redis/main.tf
resource "google_redis_instance" "cache" {
  name           = "agendaapp-cache"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.region
}
```

**En backend:**
```python
import redis

redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST'),
    port=6379,
    decode_responses=True
)

@app.route('/tasks')
def get_tasks():
    # Intentar obtener del caché
    cached = redis_client.get('tasks')
    if cached:
        return jsonify(json.loads(cached))
    
    # Si no está en caché, obtener de DB
    tasks = fetch_from_db()
    redis_client.setex('tasks', 60, json.dumps(tasks))  # TTL 60s
    return jsonify(tasks)
```

### 🎯 **Mejoras Avanzadas (Nivel Profesional)**

#### 1. **Implementar GitOps con ArgoCD**

ArgoCD sincroniza automáticamente tu cluster con Git:

```bash
# Instalar ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Acceder a ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Password inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Crear aplicación en ArgoCD:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: agendaapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/tu-usuario/agendaapp'
    targetRevision: HEAD
    path: k8s
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### 2. **Service Mesh con Istio**

Istio añade observabilidad, seguridad y control de tráfico:

```bash
# Instalar Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

istioctl install --set profile=demo -y

# Habilitar inyección automática
kubectl label namespace default istio-injection=enabled

# Re-deployar pods para que tengan sidecar proxy
kubectl rollout restart deployment/backend-postgres
kubectl rollout restart deployment/frontend
```

**Beneficios:**
- Métricas detalladas de tráfico
- Retry automático en fallos
- Circuit breaker
- Mutual TLS entre servicios
- Traffic splitting (A/B testing)

#### 3. **Security Scanning Automático**

Agregar al Jenkinsfile:

```groovy
stage('Security Scan') {
    steps {
        script {
            // Escanear vulnerabilidades en imágenes Docker
            sh """
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                  aquasec/trivy image ${BACKEND_IMAGE}:${BUILD_TAG}
            """
            
            // Escanear código fuente
            sh """
                docker run --rm -v \$(pwd):/src hysnsec/safety \
                  check -r /src/AgendaApp/backend/requirements.txt
            """
        }
    }
}
```

#### 4. **Auto-Scaling Inteligente con HPA y VPA**

**Horizontal Pod Autoscaler (HPA):**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-postgres
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
```

#### 5. **Disaster Recovery y Backups**

**Script de backup automático:**
```bash
#!/bin/bash
# backup-agendaapp.sh

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/backups/agendaapp"

# Backup de PostgreSQL
kubectl exec -n default postgres-xxx -- pg_dump -U agendaapp agendaapp > \
  ${BACKUP_DIR}/db-backup-${DATE}.sql

# Backup de configuración de Kubernetes
kubectl get all --all-namespaces -o yaml > \
  ${BACKUP_DIR}/k8s-config-${DATE}.yaml

# Subir a Google Cloud Storage
gsutil cp ${BACKUP_DIR}/* gs://agendaapp-backups/${DATE}/

# Retener solo últimos 30 días
find ${BACKUP_DIR} -mtime +30 -delete
```

**Automatizar con CronJob en Kubernetes:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-agendaapp
spec:
  schedule: "0 2 * * *"  # Todos los días a las 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: google/cloud-sdk:slim
            command: ["/bin/bash", "/scripts/backup-agendaapp.sh"]
            volumeMounts:
            - name: backup-script
              mountPath: /scripts
          restartPolicy: OnFailure
          volumes:
          - name: backup-script
            configMap:
              name: backup-scripts
```

#### 6. **Multi-Region para Alta Disponibilidad**

**Crear cluster en otra región:**
```hcl
# environments/prod-multi-region/terraform.tfvars
primary_region   = "us-central1"
secondary_region = "us-east1"
multi_region_enabled = true
```

**Configurar Traffic Director:**
```hcl
resource "google_compute_global_address" "default" {
  name = "agendaapp-global-ip"
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "agendaapp-global-lb"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}
```

---

## 🐛 Troubleshooting

### Problema: Jenkins no inicia
```bash
# Ver logs
kubectl logs -n jenkins -l app=jenkins

# Problemas comunes:
# 1. Permisos del volumen
kubectl describe pvc -n jenkins jenkins-pvc

# 2. Recursos insuficientes
kubectl describe pod -n jenkins -l app=jenkins
```

### Problema: Pipeline falla en "Push Images"
```bash
# Verificar autenticación con Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Verificar que el repositorio existe
gcloud artifacts repositories list --location=us-central1
```

### Problema: Backend no conecta con PostgreSQL
```bash
# Verificar servicio de PostgreSQL
kubectl get svc postgres-service

# Verificar variables de entorno en backend
kubectl describe pod -l app=backend

# Probar conexión manual
kubectl exec -it backend-postgres-xxx -- /bin/bash
python3 -c "import psycopg2; conn = psycopg2.connect('host=postgres-service dbname=agendaapp user=agendaapp password=xxx')"
```

### Problema: OpenTofu falla con quota exceeded
```bash
# Ver cuotas actuales
gcloud compute project-info describe --project=kubernetes-474008

# Solicitar aumento de quota en GCP Console:
# https://console.cloud.google.com/iam-admin/quotas
```

---

## 📚 Recursos Adicionales

### Documentación Oficial:
- [OpenTofu Docs](https://opentofu.org/docs/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)

### Tutoriales Recomendados:
- [Kubernetes Patterns](https://www.redhat.com/en/resources/oreilly-kubernetes-patterns-book)
- [Jenkins CI/CD Pipeline](https://www.jenkins.io/doc/tutorials/)
- [Terraform/OpenTofu Best Practices](https://www.terraform-best-practices.com/)

### Comandos Útiles:
```bash
# Ver todos los recursos
kubectl get all --all-namespaces

# Escalar manualmente
kubectl scale deployment backend-postgres --replicas=5

# Ver logs en tiempo real
kubectl logs -f deployment/backend-postgres

# Ejecutar comando en pod
kubectl exec -it pod-name -- /bin/bash

# Port-forward para debug local
kubectl port-forward svc/backend-service 5000:5000

# Describe para debug
kubectl describe pod pod-name

# Ver eventos del cluster
kubectl get events --sort-by='.lastTimestamp'
```

---

## ✅ Checklist de Verificación

Antes de presentar tu proyecto, verifica:

- [ ] ✅ Infraestructura definida en código (OpenTofu)
- [ ] ✅ Todos los módulos creados y documentados
- [ ] ✅ Jenkins desplegado y accesible
- [ ] ✅ Pipeline funciona correctamente
- [ ] ✅ Aplicación responde en las IPs públicas
- [ ] ✅ Tests automáticos ejecutándose
- [ ] ✅ Imágenes Docker en Artifact Registry
- [ ] ✅ Documentación completa en español
- [ ] ✅ Diagrama de arquitectura
- [ ] ✅ README con instrucciones de uso

---

## 🎓 Conclusión

Has implementado una solución **nivel producción** que incluye:

✨ **Infrastructure as Code** con OpenTofu
✨ **CI/CD Pipeline** automatizado con Jenkins  
✨ **Arquitectura de microservicios** en Kubernetes
✨ **Alta disponibilidad** con múltiples replicas
✨ **Seguridad** con Workload Identity y redes privadas
✨ **Monitoreo** con health checks
✨ **Escalabilidad** con autoscaling

Esta implementación demuestra conocimiento de:
- DevOps practices
- Cloud architecture
- Container orchestration
- Automation
- Security best practices

**¡Felicitaciones! 🎉**

Tu proyecto está listo para obtener puntos adicionales. Continúa expandiendo con las ideas de mejoras futuras para seguir aprendiendo.

---

**Fecha:** Noviembre 2025  
**Proyecto:** AgendaApp Infrastructure as Code  
**Tecnologías:** OpenTofu, Jenkins, Kubernetes, GCP
