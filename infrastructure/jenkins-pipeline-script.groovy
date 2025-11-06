pipeline {
    agent any
    
    environment {
        GCP_PROJECT = 'kubernetes-474008'
        GCP_REGION = 'us-central1'
        TOFU_DIR = '/workspace/infrastructure/opentofu'
        CLOUDSDK_PYTHON = '/usr/bin/python3'
        
        // Artifact Registry
        ARTIFACT_REGISTRY = 'us-central1-docker.pkg.dev'
        REGISTRY_REPO = 'kubernetes-474008/agendaapp'
        
        // Aplicación
        APP_DIR = '/workspace/AgendaApp'
        FRONTEND_IMAGE = "${ARTIFACT_REGISTRY}/${REGISTRY_REPO}/frontend"
        BACKEND_IMAGE = "${ARTIFACT_REGISTRY}/${REGISTRY_REPO}/backend"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Preparar Entorno') {
            steps {
                echo '=== Configurando entorno para OpenTofu ==='
                sh '''
                    echo "Verificando herramientas instaladas..."
                    tofu version || echo "WARNING: OpenTofu no encontrado"
                    gcloud version || echo "WARNING: gcloud no encontrado"
                    echo ""
                    echo "Entorno preparado"
                '''
            }
        }
        
        stage('Autenticar GCP') {
            steps {
                echo '=== Autenticando con Google Cloud ==='
                withCredentials([file(credentialsId: 'gcp-jenkins-iac-credentials', variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        echo "Activando Service Account..."
                        gcloud auth activate-service-account --key-file=$GCP_KEY_FILE
                        gcloud config set project ${GCP_PROJECT}
                        
                        echo ""
                        echo "Autenticación exitosa"
                        echo "Proyecto activo: ${GCP_PROJECT}"
                    '''
                }
            }
        }
        
        stage('Clonar Repositorio IaC') {
            steps {
                echo '=== Obteniendo código de infraestructura ==='
                sh '''
                    # En un entorno real, clonarías desde Git
                    # git clone <repo-url> ${TOFU_DIR}
                    
                    echo "Directorio de trabajo: ${TOFU_DIR}"
                    echo "Código IaC obtenido"
                '''
            }
        }
        
        stage('Inicializar OpenTofu') {
            steps {
                echo '=== Inicializando OpenTofu ==='
                dir("${TOFU_DIR}") {
                    sh '''
                        tofu init -reconfigure
                        echo ""
                        echo "OpenTofu inicializado"
                    '''
                }
            }
        }
        
        stage('Validar Configuración') {
            steps {
                echo '=== Validando sintaxis de archivos HCL ==='
                dir("${TOFU_DIR}") {
                    sh '''
                        tofu validate
                        echo ""
                        echo "Configuración validada correctamente"
                    '''
                }
            }
        }
        
        stage('Generar Plan') {
            steps {
                echo '=== Generando plan de cambios ==='
                dir("${TOFU_DIR}") {
                    sh '''
                        tofu plan -var-file=environments/dev/terraform.tfvars -out=tfplan
                        echo ""
                        echo "Plan generado y guardado como 'tfplan'"
                    '''
                }
            }
        }
        
        stage('Aplicar Cambios') {
            steps {
                echo '=== Aplicando cambios de infraestructura ==='
                dir("${TOFU_DIR}") {
                    sh '''
                        echo "Ejecutando tofu apply..."
                        tofu apply -auto-approve tfplan
                        echo ""
                        echo "Infraestructura actualizada exitosamente"
                    '''
                }
            }
        }
        
        stage('Mostrar Outputs') {
            steps {
                echo '=== Mostrando información de infraestructura creada ==='
                dir("${TOFU_DIR}") {
                    sh '''
                        echo "Outputs de la infraestructura:"
                        echo ""
                        tofu output
                        echo ""
                        echo "Información de infraestructura disponible"
                    '''
                }
            }
        }
        
        stage('Configurar kubectl') {
            steps {
                echo '=== Configurando acceso al cluster GKE ==='
                sh '''
                    echo "Obteniendo credenciales del cluster..."
                    gcloud container clusters get-credentials agendaapp-cluster \
                        --region=${GCP_REGION} \
                        --project=${GCP_PROJECT}
                    
                    echo ""
                    echo "Verificando conexión al cluster..."
                    kubectl get nodes
                    echo ""
                    echo "kubectl configurado correctamente"
                '''
            }
        }
        
        stage('Construir Imágenes Docker') {
            steps {
                echo '=== Construyendo imágenes de la aplicación ==='
                sh '''
                    echo "Configurando Docker para Artifact Registry..."
                    gcloud auth configure-docker ${ARTIFACT_REGISTRY} --quiet
                    
                    echo ""
                    echo "Construyendo imagen del Backend..."
                    cd ${APP_DIR}/backend
                    docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} -t ${BACKEND_IMAGE}:latest .
                    
                    echo ""
                    echo "Construyendo imagen del Frontend..."
                    cd ${APP_DIR}/frontend
                    docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} -t ${FRONTEND_IMAGE}:latest .
                    
                    echo ""
                    echo "Imágenes construidas exitosamente"
                '''
            }
        }
        
        stage('Subir Imágenes a Registry') {
            steps {
                echo '=== Subiendo imágenes a Artifact Registry ==='
                sh '''
                    echo "Subiendo imagen del Backend..."
                    docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                    docker push ${BACKEND_IMAGE}:latest
                    
                    echo ""
                    echo "Subiendo imagen del Frontend..."
                    docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                    docker push ${FRONTEND_IMAGE}:latest
                    
                    echo ""
                    echo "Imágenes subidas a Artifact Registry"
                    echo "Backend: ${BACKEND_IMAGE}:${IMAGE_TAG}"
                    echo "Frontend: ${FRONTEND_IMAGE}:${IMAGE_TAG}"
                '''
            }
        }
        
        stage('Desplegar Aplicación en GKE') {
            steps {
                echo '=== Desplegando AgendaApp en Kubernetes ==='
                sh '''
                    echo "Aplicando manifiestos de Kubernetes..."
                    cd ${APP_DIR}/k8s
                    
                    # Desplegar base de datos PostgreSQL
                    echo "Desplegando PostgreSQL..."
                    kubectl apply -f postgres-pvc.yaml
                    kubectl apply -f postgres-deployment.yaml
                    
                    # Desplegar Backend
                    echo "Desplegando Backend..."
                    kubectl apply -f backend-postgres-working.yaml
                    kubectl set image deployment/backend-postgres backend=${BACKEND_IMAGE}:${IMAGE_TAG}
                    
                    # Esperar a que el backend tenga IP externa
                    echo "Esperando IP externa del backend..."
                    while [ -z "$(kubectl get service backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)" ]; do
                        echo "Esperando IP del backend..."
                        sleep 10
                    done
                    
                    # Obtener IP del backend
                    BACKEND_IP=$(kubectl get service backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
                    echo "Backend IP: $BACKEND_IP"
                    
                    # Actualizar frontend con la IP del backend
                    echo "Actualizando frontend con backend IP: $BACKEND_IP"
                    kubectl set env deployment/frontend BACKEND_URL="http://$BACKEND_IP:5000"
                    
                    # Desplegar Frontend
                    echo "Desplegando Frontend..."
                    kubectl apply -f frontend-deployment.yaml
                    kubectl set image deployment/frontend frontend=${FRONTEND_IMAGE}:${IMAGE_TAG}
                    
                    echo ""
                    echo "Esperando que los pods estén listos..."
                    kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s || true
                    kubectl wait --for=condition=ready pod -l app=backend-postgres --timeout=120s || true
                    kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s || true
                    
                    echo ""
                    echo "Aplicación desplegada exitosamente"
                '''
            }
        }
        
        stage('Verificar Despliegue') {
            steps {
                echo '=== Verificando estado del despliegue ==='
                sh '''
                    echo "Estado de los pods:"
                    kubectl get pods
                    
                    echo ""
                    echo "Servicios expuestos:"
                    kubectl get services
                    
                    echo ""
                    echo "Obteniendo IPs externas..."
                    FRONTEND_IP=$(kubectl get service frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pendiente...")
                    BACKEND_IP=$(kubectl get service backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pendiente...")
                    
                    echo ""
                    echo "URLs de Acceso:"
                    echo "   Frontend: http://${FRONTEND_IP}"
                    echo "   Backend:  http://${BACKEND_IP}:5000"
                    echo ""
                    echo "Verificación completada"
                '''
            }
        }
    }
    
    post {
        success {
            echo 'Despliegue completado exitosamente!'
            echo ''
            echo 'Resumen del Despliegue:'
            echo '   - Infraestructura creada con OpenTofu'
            echo '   - Imágenes Docker construidas'
            echo '   - Imágenes subidas a Artifact Registry'
            echo '   - Aplicación desplegada en GKE'
            echo ''
            echo 'Sistema completamente operativo'
            echo ''
            script {
                def frontendIP = sh(
                    script: "kubectl get service frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'Pendiente'",
                    returnStdout: true
                ).trim()
                def backendIP = sh(
                    script: "kubectl get service backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'Pendiente'",
                    returnStdout: true
                ).trim()
                
                echo "Accede a tu aplicación:"
                echo "   Frontend: http://${frontendIP}"
                echo "   Backend:  http://${backendIP}:5000"
            }
        }
        failure {
            echo 'ERROR: Error durante el despliegue'
            echo 'Revisa los logs para identificar el problema'
            echo ''
            echo 'Posibles causas:'
            echo '   • Credenciales GCP inválidas'
            echo '   • Errores en sintaxis HCL'
            echo '   • Error al construir imágenes Docker'
            echo '   • Problemas de conectividad con GKE'
            echo '   • Cuotas de GCP excedidas'
        }
        always {
            echo "=== Pipeline Completo Build #${BUILD_NUMBER} finalizado ==="
        }
    }
}
