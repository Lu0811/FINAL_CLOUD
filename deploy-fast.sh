#!/bin/bash
echo "⚡ CI/CD Rápido para AgendaApp"
echo "=============================="

# Variables
PROJECT_ID="kubernetes-474008"
REGION="us-central1"
CLUSTER_NAME="agendaapp-cluster"
REGISTRY="us-central1-docker.pkg.dev/kubernetes-474008/agendaapp"
BUILD_TAG=$(git rev-parse --short HEAD)-$(date +%s)

echo "🏷️  Build Tag: $BUILD_TAG"
echo ""

# Configurar ambiente
echo "🔧 Configurando ambiente..."
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Autenticar con GCP
echo "🔐 Autenticando con GCP..."
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Conectar a GKE
echo "☸️  Conectando a GKE..."
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID

# Build Backend
echo "🔧 Construyendo Backend..."
cd AgendaApp/backend
docker build -t ${REGISTRY}/backend:${BUILD_TAG} -t ${REGISTRY}/backend:latest .

# Build Frontend  
echo "🌐 Construyendo Frontend..."
cd ../frontend
docker build -t ${REGISTRY}/frontend:${BUILD_TAG} -t ${REGISTRY}/frontend:latest .

# Push Images
echo "📤 Subiendo imágenes..."
docker push ${REGISTRY}/backend:${BUILD_TAG}
docker push ${REGISTRY}/backend:latest
docker push ${REGISTRY}/frontend:${BUILD_TAG}
docker push ${REGISTRY}/frontend:latest

# Deploy
echo "🚀 Desplegando a Kubernetes..."
cd ../k8s

# Update deployments
kubectl set image deployment/backend-postgres backend=${REGISTRY}/backend:${BUILD_TAG} --record
kubectl set image deployment/frontend frontend=${REGISTRY}/frontend:${BUILD_TAG} --record

echo "⏳ Esperando despliegue..."
kubectl rollout status deployment/backend-postgres --timeout=300s
kubectl rollout status deployment/frontend --timeout=300s

# Verificar
echo "✅ Verificando despliegue..."
kubectl get pods
echo ""
kubectl get services

# URLs de acceso
FRONTEND_IP=$(kubectl get svc frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pendiente")
BACKEND_IP=$(kubectl get svc backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pendiente")

echo ""
echo "🎯 URLs de Acceso:"
echo "   Frontend: http://${FRONTEND_IP}"
echo "   Backend:  http://${BACKEND_IP}:5000"
echo ""
echo "✅ ¡Despliegue completado en menos de 5 minutos!"