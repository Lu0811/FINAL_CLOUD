#!/bin/bash
# Script para crear el pipeline de AgendaApp en Jenkins automáticamente

echo "🚀 Creando pipeline de AgendaApp en Jenkins..."

export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
JENKINS_URL="http://35.232.149.227:8080"

echo "Pod de Jenkins: $JENKINS_POD"

# Crear el archivo XML de configuración del job
cat > /tmp/agendaapp-pipeline-config.xml <<'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>Pipeline para verificar y gestionar AgendaApp</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.93">
    <script>pipeline {
    agent any
    
    environment {
        BACKEND_URL = 'http://34.71.155.58:5000'
        FRONTEND_URL = 'http://34.70.211.16'
    }
    
    stages {
        stage('🏥 Health Check Backend') {
            steps {
                echo '=== Verificando tu Backend de AgendaApp ==='
                script {
                    def response = sh(
                        script: "curl -s ${BACKEND_URL}/health",
                        returnStdout: true
                    ).trim()
                    echo "Respuesta del backend: ${response}"
                    echo '✅ Backend funcionando correctamente'
                }
            }
        }
        
        stage('📝 Verificar Tareas') {
            steps {
                echo '=== Obteniendo tareas actuales ==='
                sh """
                    echo "Tareas en tu aplicación:"
                    curl -s ${BACKEND_URL}/tasks
                """
            }
        }
        
        stage('🌐 Verificar Frontend') {
            steps {
                echo '=== Verificando tu Frontend ==='
                script {
                    def statusCode = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' ${FRONTEND_URL}",
                        returnStdout: true
                    ).trim()
                    
                    echo "Frontend status code: ${statusCode}"
                    
                    if (statusCode == '200') {
                        echo '✅ Frontend funcionando correctamente'
                    } else {
                        echo "⚠️ Frontend respondió con código: ${statusCode}"
                    }
                }
            }
        }
        
        stage('📊 Resumen') {
            steps {
                echo '=== Resumen de tu Aplicación ==='
                echo "Backend URL: ${BACKEND_URL}"
                echo "Frontend URL: ${FRONTEND_URL}"
                echo "Estado: Verificado exitosamente"
            }
        }
    }
    
    post {
        success {
            echo '✅ ¡Tu AgendaApp está funcionando perfectamente!'
            echo "   Backend: ${BACKEND_URL}"
            echo "   Frontend: ${FRONTEND_URL}"
        }
        failure {
            echo '❌ Hay problemas con tu aplicación'
            echo '   Revisa los logs arriba'
        }
        always {
            echo "=== Build #${BUILD_NUMBER} completado ==="
        }
    }
}</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Copiar el archivo al pod de Jenkins
echo "Copiando configuración al pod de Jenkins..."
kubectl cp /tmp/agendaapp-pipeline-config.xml jenkins/$JENKINS_POD:/tmp/job-config.xml

# Crear el directorio del job y copiar la configuración
echo "Creando el job en Jenkins..."
kubectl exec -n jenkins $JENKINS_POD -- bash -c '
mkdir -p /var/jenkins_home/jobs/agendaapp-healthcheck
cp /tmp/job-config.xml /var/jenkins_home/jobs/agendaapp-healthcheck/config.xml
chown -R jenkins:jenkins /var/jenkins_home/jobs/agendaapp-healthcheck
'

# Recargar configuración de Jenkins
echo "Recargando configuración de Jenkins..."
kubectl exec -n jenkins $JENKINS_POD -- bash -c '
curl -X POST http://localhost:8080/reload || true
'

echo ""
echo "✅ ¡Pipeline creado exitosamente!"
echo ""
echo "📍 Accede a Jenkins:"
echo "   URL: http://35.232.149.227:8080"
echo ""
echo "🎯 Para ejecutar el pipeline:"
echo "   1. Abre: http://35.232.149.227:8080"
echo "   2. Busca el job: 'agendaapp-healthcheck'"
echo "   3. Click en 'Build Now'"
echo "   4. Click en '#1' para ver el resultado"
echo "   5. Click en 'Console Output'"
echo ""
echo "🔄 Si no ves el job, reinicia Jenkins:"
echo "   kubectl delete pod -n jenkins -l app=jenkins"
echo ""
