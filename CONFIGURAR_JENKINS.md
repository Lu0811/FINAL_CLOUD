# 🔧 Guía Paso a Paso - Configurar Jenkins para AgendaApp

## 📍 Información de Acceso

**URL de Jenkins:** http://35.232.149.227:8080

**NOTA:** Como desactivamos el wizard de instalación, Jenkins está corriendo sin configuración inicial. Necesitamos configurarlo manualmente.

---

## 🚀 Paso 1: Acceder a Jenkins (Primera Vez)

### Opción A: Habilitar Acceso sin Autenticación Temporalmente

Esto es temporal solo para la configuración inicial:

```bash
# Configurar variables
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Obtener nombre del pod
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')

# Deshabilitar seguridad temporalmente
kubectl exec -n jenkins $JENKINS_POD -- bash -c 'echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><useSecurity>false</useSecurity>" > /var/jenkins_home/config.xml'

# Reiniciar Jenkins
kubectl delete pod -n jenkins -l app=jenkins

# Esperar a que reinicie (30-60 segundos)
sleep 60

echo "Jenkins está listo en: http://35.232.149.227:8080"
```

### Opción B: Usar Port-Forward (Más Seguro)

```bash
# En una terminal, ejecutar:
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
kubectl port-forward -n jenkins svc/jenkins 8080:8080

# Luego accede a: http://localhost:8080
```

---

## 🎨 Paso 2: Configuración Inicial en la UI de Jenkins

### 2.1 Abrir Jenkins
Abre tu navegador y ve a: **http://35.232.149.227:8080**

### 2.2 Configurar Seguridad

1. Click en **Manage Jenkins** (menú lateral izquierdo)
2. Click en **Security** o **Configure Global Security**
3. En **Security Realm**, selecciona **Jenkins' own user database**
4. Marca ✅ **Allow users to sign up**
5. En **Authorization**, selecciona **Logged-in users can do anything**
6. Click **Save**

### 2.3 Crear Usuario Admin

1. Ve a: http://35.232.149.227:8080/signup
2. Crea tu usuario:
   - Username: `admin`
   - Password: `admin123` (o el que prefieras)
   - Full name: `Admin`
   - Email: tu email
3. Click **Sign up**

### 2.4 Desactivar Registro Público (Importante)

1. Ve a **Manage Jenkins** → **Security**
2. Desmarca ❌ **Allow users to sign up**
3. Click **Save**

---

## 📦 Paso 3: Instalar Plugins Necesarios

### 3.1 Ir a Gestión de Plugins

1. **Manage Jenkins** → **Manage Plugins** (o **Plugins**)
2. Click en la pestaña **Available plugins**

### 3.2 Buscar e Instalar Plugins

Busca e instala los siguientes plugins (usa la barra de búsqueda):

- ✅ **Git Plugin** - Para clonar repositorios
- ✅ **Pipeline** - Para usar Jenkinsfile
- ✅ **Docker Pipeline** - Para construir imágenes Docker
- ✅ **Kubernetes Plugin** - Para desplegar en K8s
- ✅ **Google Kubernetes Engine Plugin** - Integración con GKE
- ✅ **Credentials Binding Plugin** - Para gestionar credenciales
- ✅ **Pipeline: Stage View** - Para visualizar el pipeline

### 3.3 Instalar

1. Selecciona todos los plugins
2. Click **Install without restart** o **Download now and install after restart**
3. Marca ✅ **Restart Jenkins when installation is complete**
4. Espera 2-3 minutos a que Jenkins reinicie

---

## 🔑 Paso 4: Configurar Credenciales de GCP

### 4.1 Obtener Access Token

En tu terminal local:

```bash
export CLOUDSDK_PYTHON=/usr/bin/python3.11
gcloud auth print-access-token
```

Copia el token que aparece (algo como: `ya29.c.b0Aaekm1K...`)

### 4.2 Agregar Credencial en Jenkins

1. Ve a **Manage Jenkins** → **Manage Credentials**
2. Click en **(global)** domain
3. Click **Add Credentials**
4. Configura:
   - **Kind:** `Secret text`
   - **Scope:** `Global`
   - **Secret:** (pega el token de GCP)
   - **ID:** `gcp-token`
   - **Description:** `GCP Access Token`
5. Click **Create**

**NOTA:** Este token expira en 1 hora. Para producción, usa un Service Account Key.

---

## 🏗️ Paso 5: Crear el Pipeline de AgendaApp

### 5.1 Crear Nuevo Job

1. En el Dashboard de Jenkins, click **New Item**
2. Nombre: `agendaapp-pipeline`
3. Selecciona **Pipeline**
4. Click **OK**

### 5.2 Configurar el Pipeline

#### Opción A: Pipeline desde Git (Recomendado)

Si tienes el código en Git:

1. En **Pipeline** section:
   - **Definition:** `Pipeline script from SCM`
   - **SCM:** `Git`
   - **Repository URL:** `[URL de tu repo]`
   - **Branch Specifier:** `*/main`
   - **Script Path:** `Jenkinsfile`

2. En **Build Triggers** (opcional):
   - ✅ **Poll SCM**
   - **Schedule:** `H/5 * * * *` (revisa cada 5 minutos)

3. Click **Save**

#### Opción B: Pipeline Script Directo

Si no tienes Git configurado, puedes pegar el script directamente:

1. En **Pipeline** section:
   - **Definition:** `Pipeline script`
   - En el editor, pega el siguiente script simplificado:

```groovy
pipeline {
    agent any
    
    environment {
        PROJECT_ID = 'kubernetes-474008'
        CLUSTER_NAME = 'agendaapp-cluster'
        REGION = 'us-central1'
    }
    
    stages {
        stage('Test Connection') {
            steps {
                script {
                    echo "✅ Conectando con GCP..."
                    sh 'gcloud version || echo "gcloud no disponible"'
                    sh 'kubectl version --client || echo "kubectl no disponible"'
                }
            }
        }
        
        stage('Check Application Status') {
            steps {
                script {
                    echo "📊 Verificando estado de la aplicación..."
                    sh '''
                        curl -s http://34.71.155.58:5000/health || echo "Backend no responde"
                        curl -s http://34.70.211.16 || echo "Frontend no responde"
                    '''
                }
            }
        }
        
        stage('Deploy Info') {
            steps {
                echo "🚀 Pipeline ejecutado exitosamente!"
                echo "Backend: http://34.71.155.58:5000"
                echo "Frontend: http://34.70.211.16"
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline completado con éxito!"
        }
        failure {
            echo "❌ Pipeline falló"
        }
    }
}
```

2. Click **Save**

### 5.3 Ejecutar el Pipeline

1. En la página del job, click **Build Now**
2. Ve el progreso en **Build History**
3. Click en el número del build (ej: #1)
4. Click en **Console Output** para ver los logs

---

## 🎯 Paso 6: Pipeline Completo con Docker Build

Una vez que el pipeline básico funcione, puedes usar el Jenkinsfile completo que ya tienes en `/home/teriyaki/Música/big data/Jenkinsfile`

### Requisitos adicionales:

1. **Instalar Docker en Jenkins:**

```bash
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')

# Instalar Docker CLI en el pod de Jenkins
kubectl exec -n jenkins $JENKINS_POD -- bash -c '
apt-get update && apt-get install -y docker.io
usermod -aG docker jenkins
'
```

2. **Configurar DinD (Docker in Docker):**

Para usar Docker dentro de Jenkins, necesitas modificar el deployment:

```yaml
# Ya está configurado en tu jenkins-config.yaml
# Solo necesitas agregar el socket de Docker como volumen
```

---

## 🔥 Pipeline Simplificado para Empezar

Si quieres empezar con algo más simple, aquí tienes un pipeline que solo verifica y reinicia la aplicación:

```groovy
pipeline {
    agent any
    
    environment {
        PROJECT_ID = 'kubernetes-474008'
        REGION = 'us-central1'
    }
    
    stages {
        stage('Health Check') {
            steps {
                echo "🏥 Verificando salud de la aplicación..."
                sh '''
                    curl -f http://34.71.155.58:5000/health || exit 1
                    echo "✅ Backend saludable"
                '''
            }
        }
        
        stage('Get Pods Status') {
            steps {
                echo "📊 Estado de los pods..."
                sh '''
                    export CLOUDSDK_PYTHON=/usr/bin/python3.11
                    export USE_GKE_GCLOUD_AUTH_PLUGIN=True
                    
                    kubectl get pods -o wide
                '''
            }
        }
        
        stage('Rolling Restart') {
            when {
                expression { 
                    return params.RESTART == 'true' 
                }
            }
            steps {
                echo "🔄 Reiniciando aplicación..."
                sh '''
                    export CLOUDSDK_PYTHON=/usr/bin/python3.11
                    export USE_GKE_GCLOUD_AUTH_PLUGIN=True
                    
                    kubectl rollout restart deployment/backend-postgres
                    kubectl rollout restart deployment/frontend
                    
                    kubectl rollout status deployment/backend-postgres
                    kubectl rollout status deployment/frontend
                '''
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline completado exitosamente!"
        }
        failure {
            echo "❌ Pipeline falló. Revisa los logs."
        }
    }
}
```

---

## ⚠️ Troubleshooting

### Problema: No puedo acceder a Jenkins

```bash
# Verificar que el pod está corriendo
kubectl get pods -n jenkins

# Ver logs del pod
kubectl logs -n jenkins -l app=jenkins --tail=50

# Verificar servicio
kubectl get svc -n jenkins

# Port-forward como alternativa
kubectl port-forward -n jenkins svc/jenkins 8080:8080
```

### Problema: Jenkins pide password pero no lo tengo

```bash
# Opción 1: Deshabilitar seguridad temporalmente
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n jenkins $JENKINS_POD -- rm -f /var/jenkins_home/config.xml
kubectl delete pod -n jenkins -l app=jenkins
```

### Problema: Plugins no se instalan

1. Ve a **Manage Jenkins** → **System Information**
2. Verifica que tienes conexión a internet
3. Ve a **Manage Jenkins** → **Plugin Manager** → **Advanced**
4. Click **Check now** para actualizar la lista de plugins

### Problema: Pipeline falla con error de kubectl

Jenkins necesita kubectl configurado:

```bash
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')

# Instalar kubectl en Jenkins
kubectl exec -n jenkins $JENKINS_POD -- bash -c '
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
'

# Configurar kubeconfig
kubectl exec -n jenkins $JENKINS_POD -- bash -c '
mkdir -p /var/jenkins_home/.kube
# Copiar tu kubeconfig aquí
'
```

---

## 📚 Próximos Pasos

Una vez que Jenkins esté configurado:

1. ✅ Crea el pipeline básico y ejecútalo
2. ✅ Verifica que puede acceder a tus servicios
3. ✅ Configura triggers automáticos (webhook de Git)
4. ✅ Implementa el Jenkinsfile completo con Docker build
5. ✅ Configura notificaciones (email, Slack)

---

## 🎉 Resumen

1. Accede a Jenkins: http://35.232.149.227:8080
2. Configura usuario y seguridad
3. Instala plugins necesarios
4. Configura credenciales de GCP
5. Crea pipeline y ejecuta tu primer build
6. ¡Disfruta de tu CI/CD automatizado!

**¿Necesitas ayuda?** Revisa la `GUIA_COMPLETA_IaC.md` para más detalles.
