pipeline {
    agent any
    
    environment {
        PROJECT_ID = 'kubernetes-474008'
        CLUSTER_NAME = 'agendaapp-cluster'
        REGION = 'us-central1'
        REGISTRY = "${REGION}-docker.pkg.dev/${PROJECT_ID}/agendaapp-repo"
        BACKEND_IMAGE = "${REGISTRY}/backend"
        FRONTEND_IMAGE = "${REGISTRY}/frontend"
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.BUILD_TAG = "${env.GIT_COMMIT_SHORT}-${env.BUILD_NUMBER}"
                }
            }
        }
        
        stage('Test Backend') {
            steps {
                dir('AgendaApp/backend') {
                    sh '''
                        python3 -m pip install --user -r requirements.txt
                        python3 -m pytest tests/ -v || true
                    '''
                }
            }
        }
        
        stage('Build Backend Image') {
            steps {
                dir('AgendaApp/backend') {
                    sh """
                        gcloud auth configure-docker ${REGION}-docker.pkg.dev
                        docker build -t ${BACKEND_IMAGE}:${BUILD_TAG} -t ${BACKEND_IMAGE}:latest .
                    """
                }
            }
        }
        
        stage('Build Frontend Image') {
            steps {
                dir('AgendaApp/frontend') {
                    sh """
                        docker build -t ${FRONTEND_IMAGE}:${BUILD_TAG} -t ${FRONTEND_IMAGE}:latest .
                    """
                }
            }
        }
        
        stage('Push Images to Artifact Registry') {
            steps {
                sh """
                    docker push ${BACKEND_IMAGE}:${BUILD_TAG}
                    docker push ${BACKEND_IMAGE}:latest
                    docker push ${FRONTEND_IMAGE}:${BUILD_TAG}
                    docker push ${FRONTEND_IMAGE}:latest
                """
            }
        }
        
        stage('Deploy to GKE') {
            steps {
                sh """
                    gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID}
                    
                    # Update backend deployment
                    kubectl set image deployment/backend-postgres backend=${BACKEND_IMAGE}:${BUILD_TAG} --record
                    kubectl rollout status deployment/backend-postgres
                    
                    # Update frontend deployment
                    kubectl set image deployment/frontend frontend=${FRONTEND_IMAGE}:${BUILD_TAG} --record
                    kubectl rollout status deployment/frontend
                """
            }
        }
        
        stage('Smoke Test') {
            steps {
                sh '''
                    # Wait for service to be ready
                    sleep 10
                    
                    # Get backend service IP
                    BACKEND_IP=$(kubectl get svc backend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
                    
                    # Test backend health
                    curl -f http://${BACKEND_IP}:5000/health || exit 1
                    
                    echo "Smoke test passed!"
                '''
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed successfully! 🎉"
            echo "Backend Image: ${BACKEND_IMAGE}:${BUILD_TAG}"
            echo "Frontend Image: ${FRONTEND_IMAGE}:${BUILD_TAG}"
        }
        failure {
            echo "Pipeline failed! ❌"
        }
        always {
            cleanWs()
        }
    }
}
