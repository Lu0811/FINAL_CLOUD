#!/bin/bash
echo "🔄 Configurando Jenkins para Ejecución Automática..."

export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
JENKINS_URL="http://35.232.149.227:8080"

echo "Pod de Jenkins: $JENKINS_POD"

# Crear configuración de job con trigger automático
cat > /tmp/agendaapp-auto-pipeline.xml <<'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>Pipeline AUTOMÁTICO de AgendaApp - Se ejecuta cada 5 minutos</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.93">
    <script>pipeline {
    agent any
    
    triggers {
        cron('H/5 * * * *')  // Ejecutar cada 5 minutos automáticamente
    }
    
    environment {
        BACKEND_URL = 'http://34.71.155.58:5000'
        FRONTEND_URL = 'http://34.70.211.16'
    }
    
    stages {
        stage('🏥 Auto Health Check') {
            steps {
                echo "🤖 EJECUCIÓN AUTOMÁTICA - $(date)"
                echo '=== Verificando tu Backend de AgendaApp ==='
                script {
                    try {
                        def response = sh(
                            script: "curl -s -f ${BACKEND_URL}/health",
                            returnStdout: true
                        ).trim()
                        echo "✅ Backend OK: ${response}"
                    } catch (Exception e) {
                        echo "❌ Backend no responde"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
        
        stage('📊 Verificar Pods') {
            steps {
                echo '=== Estado de los Pods ==='
                sh '''
                    export CLOUDSDK_PYTHON=/usr/bin/python3.11
                    export USE_GKE_GCLOUD_AUTH_PLUGIN=True
                    
                    echo "Pods corriendo:"
                    kubectl get pods | grep -E "backend|frontend|postgres"
                    
                    echo ""
                    echo "HPA Status:"
                    kubectl get hpa
                    
                    echo ""
                    echo "Uso de recursos:"
                    kubectl top pods | grep -E "backend|frontend" || echo "Métricas no disponibles"
                '''
            }
        }
        
        stage('🌐 Verificar URLs') {
            steps {
                echo '=== URLs de Acceso ==='
                sh '''
                    export CLOUDSDK_PYTHON=/usr/bin/python3.11
                    export USE_GKE_GCLOUD_AUTH_PLUGIN=True
                    
                    FRONTEND_IP=$(kubectl get svc frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pendiente")
                    BACKEND_IP=$(kubectl get svc backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pendiente")
                    
                    echo "🌐 Frontend: http://${FRONTEND_IP}"
                    echo "🔧 Backend:  http://${BACKEND_IP}:5000"
                    echo "🏥 Health:   http://${BACKEND_IP}:5000/health"
                '''
            }
        }
    }
    
    post {
        success {
            echo '✅ Todo funciona correctamente'
        }
        unstable {
            echo '⚠️  Hay algunos problemas, pero el sistema está funcionando'
        }
        failure {
            echo '❌ Hay problemas críticos'
        }
        always {
            echo "🤖 Próxima ejecución automática en 5 minutos"
        }
    }
}</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers>
    <hudson.triggers.TimerTrigger>
      <spec>H/5 * * * *</spec>
    </hudson.triggers.TimerTrigger>
  </triggers>
  <disabled>false</disabled>
</flow-definition>
EOF

# Copiar configuración al pod de Jenkins
echo "📁 Copiando configuración al Jenkins..."
kubectl cp /tmp/agendaapp-auto-pipeline.xml jenkins/$JENKINS_POD:/tmp/auto-job-config.xml

# Crear el job automático
echo "🔧 Creando job automático..."
kubectl exec -n jenkins $JENKINS_POD -- bash -c '
mkdir -p /var/jenkins_home/jobs/agendaapp-automatic
cp /tmp/auto-job-config.xml /var/jenkins_home/jobs/agendaapp-automatic/config.xml
chown -R jenkins:jenkins /var/jenkins_home/jobs/agendaapp-automatic
'

# Recargar Jenkins
echo "🔄 Recargando Jenkins..."
kubectl exec -n jenkins $JENKINS_POD -- bash -c 'curl -X POST http://localhost:8080/reload || true'

echo ""
echo "✅ ¡Jenkins Automático Configurado!"
echo ""
echo "🎯 Nuevo Job Creado:"
echo "   Nombre: agendaapp-automatic"
echo "   URL: http://35.232.149.227:8080/job/agendaapp-automatic/"
echo "   Frecuencia: Cada 5 minutos automáticamente"
echo ""
echo "🔍 Para verificar:"
echo "   1. Abre: http://35.232.149.227:8080"
echo "   2. Busca: 'agendaapp-automatic'"
echo "   3. Verás que se ejecuta solo cada 5 minutos"
echo ""
echo "⏰ Primera ejecución en los próximos 5 minutos..."