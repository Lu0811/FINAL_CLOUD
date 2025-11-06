# ⚡ Guía Rápida - Jenkins sin Contraseña

## 🎉 ¡Jenkins está listo!

**Jenkins URL:** http://35.232.149.227:8080

**NOTA:** La seguridad está temporalmente deshabilitada para que puedas configurarlo fácilmente.

---

## 📝 Paso 1: Acceder a Jenkins

1. Abre tu navegador
2. Ve a: **http://35.232.149.227:8080**
3. ¡Ya estás dentro! (sin contraseña)

---

## 🔧 Paso 2: Crear tu Primer Pipeline

### Opción Simple - Pipeline de Prueba

1. En Jenkins, click **New Item** (esquina superior izquierda)
2. Nombre: `test-pipeline`
3. Selecciona **Pipeline**
4. Click **OK**
5. Baja hasta la sección **Pipeline**
6. En el campo de script, pega esto:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Hello') {
            steps {
                echo '🎉 ¡Hola desde Jenkins!'
            }
        }
        
        stage('Check Backend') {
            steps {
                sh 'curl -s http://34.71.155.58:5000/health'
            }
        }
        
        stage('Check Frontend') {
            steps {
                sh 'curl -s http://34.70.211.16'
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completado exitosamente!'
        }
    }
}
```

7. Click **Save**
8. Click **Build Now**
9. Click en el número del build (#1) que aparece abajo
10. Click en **Console Output** para ver el resultado

---

## 🚀 Paso 3: Pipeline Real de AgendaApp

Una vez que el pipeline de prueba funcione, crea el pipeline real:

1. Click **New Item**
2. Nombre: `agendaapp-deploy`
3. Selecciona **Pipeline**
4. Click **OK**
5. En la sección **Pipeline**, pega este script:

```groovy
pipeline {
    agent any
    
    environment {
        PROJECT_ID = 'kubernetes-474008'
        BACKEND_IP = '34.71.155.58'
        FRONTEND_IP = '34.70.211.16'
    }
    
    stages {
        stage('🔍 Health Check') {
            steps {
                echo 'Verificando salud de la aplicación...'
                script {
                    def backendHealth = sh(
                        script: 'curl -s http://34.71.155.58:5000/health',
                        returnStdout: true
                    ).trim()
                    echo "Backend Health: ${backendHealth}"
                }
            }
        }
        
        stage('📊 Get Status') {
            steps {
                echo 'Obteniendo estado actual...'
                sh '''
                    echo "=== Tareas Actuales ==="
                    curl -s http://34.71.155.58:5000/tasks | head -20
                '''
            }
        }
        
        stage('📈 Deploy Info') {
            steps {
                echo '=== Información de Deployment ==='
                echo "Backend URL: http://${BACKEND_IP}:5000"
                echo "Frontend URL: http://${FRONTEND_IP}"
                echo "Proyecto GCP: ${PROJECT_ID}"
            }
        }
    }
    
    post {
        success {
            echo '✅ ¡Pipeline ejecutado exitosamente!'
            echo '   Backend: http://34.71.155.58:5000'
            echo '   Frontend: http://34.70.211.16'
        }
        failure {
            echo '❌ Pipeline falló. Revisa los logs arriba.'
        }
    }
}
```

6. Click **Save**
7. Click **Build Now**

---

## 🎨 Paso 4: Configurar Seguridad (Después de Probar)

Una vez que hayas probado que todo funciona:

1. Ve a **Manage Jenkins** (menú lateral)
2. Click en **Security** o **Configure Global Security**
3. En **Security Realm**, selecciona **Jenkins' own user database**
4. Marca ✅ **Allow users to sign up**
5. En **Authorization**, selecciona **Logged-in users can do anything**
6. Click **Save**
7. Ve a: http://35.232.149.227:8080/signup
8. Crea tu usuario (admin / admin123)
9. Ve de nuevo a **Manage Jenkins** → **Security**
10. Desmarca ❌ **Allow users to sign up**
11. Click **Save**

---

## 📦 Paso 5: Instalar Plugins (Opcional pero Recomendado)

Para tener una mejor experiencia:

1. Ve a **Manage Jenkins** → **Manage Plugins**
2. Click en **Available plugins**
3. Busca e instala:
   - **Blue Ocean** (interfaz moderna)
   - **Pipeline Stage View** (visualización bonita)
   - **Docker Pipeline** (para builds con Docker)
   - **Git Plugin** (para integrar con Git)

4. Click **Install without restart**

---

## 🎯 Lo que Puedes Hacer Ahora

### Ver tus Pipelines:
- Dashboard principal muestra todos tus jobs
- Click en cualquier job para ver su historial
- Click en un build para ver los logs

### Ejecutar un Pipeline:
- Entra al job
- Click **Build Now**
- Ve el progreso en tiempo real

### Ver Console Output:
- Click en el número del build
- Click **Console Output**
- Ve los logs paso a paso

### Modificar un Pipeline:
- Entra al job
- Click **Configure**
- Edita el script
- Click **Save**

---

## ⚙️ Comandos Útiles

### Verificar Jenkins desde terminal:
```bash
# Ver status
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
kubectl get pods -n jenkins

# Ver logs
kubectl logs -n jenkins -l app=jenkins --tail=50

# Reiniciar Jenkins
kubectl delete pod -n jenkins -l app=jenkins
```

### Habilitar seguridad nuevamente:
```bash
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n jenkins $JENKINS_POD -- rm -f /var/jenkins_home/init.groovy.d/disable-security.groovy
kubectl delete pod -n jenkins -l app=jenkins
```

---

## 🎉 ¡Listo!

Ahora tienes:
- ✅ Jenkins corriendo y accesible
- ✅ Sin contraseña (temporal, para configuración)
- ✅ Pipelines de ejemplo listos para usar
- ✅ Guías para configurar seguridad después

**Siguiente paso:** 
1. Abre http://35.232.149.227:8080
2. Crea el pipeline de prueba
3. Ejecuta tu primer build
4. ¡Mira los resultados!

---

**¿No funciona algo?** Revisa `CONFIGURAR_JENKINS.md` para troubleshooting detallado.
