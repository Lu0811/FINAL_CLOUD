#!/bin/bash
# Script para configurar Jenkins automáticamente

echo "=== Configurando Jenkins ==="

# Obtener el nombre del pod de Jenkins
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')

echo "Pod de Jenkins: $JENKINS_POD"

# Crear script de configuración dentro del pod
kubectl exec -n jenkins $JENKINS_POD -- bash -c 'cat > /tmp/setup-jenkins.groovy <<EOF
#!groovy
import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.getInstance()

// Crear usuario admin
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

// Configurar permisos
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Marcar como configurado
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

instance.save()
println("Usuario admin creado exitosamente")
EOF'

# Ejecutar el script de configuración
echo "Creando usuario admin..."
kubectl exec -n jenkins $JENKINS_POD -- groovy /tmp/setup-jenkins.groovy

# Instalar plugins necesarios
echo "Instalando plugins necesarios..."
kubectl exec -n jenkins $JENKINS_POD -- bash -c 'cat > /tmp/install-plugins.groovy <<EOF
#!groovy
import jenkins.model.*

def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

// Lista de plugins necesarios
def plugins = [
    "git",
    "workflow-aggregator",
    "docker-workflow",
    "kubernetes",
    "google-kubernetes-engine",
    "credentials-binding",
    "pipeline-stage-view"
]

println("Instalando plugins...")
plugins.each { plugin ->
    if (!pm.getPlugin(plugin)) {
        println("Instalando: " + plugin)
        def p = uc.getPlugin(plugin)
        if (p) {
            p.deploy()
        }
    } else {
        println("Ya instalado: " + plugin)
    }
}

instance.save()
EOF'

kubectl exec -n jenkins $JENKINS_POD -- groovy /tmp/install-plugins.groovy

echo ""
echo "=== Configuración Completada ==="
echo ""
echo "Jenkins está disponible en: http://35.232.149.227:8080"
echo "Usuario: admin"
echo "Password: admin123"
echo ""
echo "IMPORTANTE: Los plugins se están instalando en segundo plano."
echo "Espera 2-3 minutos antes de crear el pipeline."
echo ""
echo "Para verificar el progreso, visita:"
echo "http://35.232.149.227:8080/updateCenter/"
echo ""
echo "Reiniciando Jenkins para aplicar cambios..."

# Reiniciar Jenkins
kubectl delete pod -n jenkins $JENKINS_POD

echo ""
echo "Jenkins se está reiniciando. Espera 1-2 minutos y accede a:"
echo "http://35.232.149.227:8080"
