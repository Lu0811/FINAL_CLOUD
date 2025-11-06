#!/bin/bash

echo "🚀 Desplegando AgendaApp en Kubernetes..."

# Aplicar PersistentVolume y PVC primero
echo "📦 Creando almacenamiento persistente para MongoDB..."
kubectl apply -f mongo-pvc.yaml

# Esperar un momento para que se configure
sleep 5

# Desplegar MongoDB
echo "🍃 Desplegando MongoDB..."
kubectl apply -f mongo-deployment.yaml

# Esperar a que MongoDB esté listo
echo "⏳ Esperando a que MongoDB esté listo..."
kubectl wait --for=condition=ready pod -l app=mongodb --timeout=300s

# Desplegar Backend
echo "🔧 Desplegando Backend..."
kubectl apply -f backend-deployment.yaml

# Esperar a que el backend esté listo
echo "⏳ Esperando a que el Backend esté listo..."
kubectl wait --for=condition=ready pod -l app=backend --timeout=300s

# Desplegar Frontend
echo "🌐 Desplegando Frontend..."
kubectl apply -f frontend-deployment.yaml

# Esperar a que el frontend esté listo
echo "⏳ Esperando a que el Frontend esté listo..."
kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s

echo ""
echo "✅ ¡Despliegue completado!"
echo ""
echo "📊 Estado de los pods:"
kubectl get pods

echo ""
echo "🌐 Servicios desplegados:"
kubectl get services

echo ""
echo "🔗 Para acceder a la aplicación:"
echo "   Ejecuta: kubectl get service frontend-service"
echo "   Busca la EXTERNAL-IP y abre http://EXTERNAL-IP en tu navegador"

echo ""
echo "🔍 Para ver los logs del backend:"
echo "   kubectl logs -l app=backend -f"

echo ""
echo "🛠️ Para verificar la base de datos:"
echo "   kubectl exec -it deployment/mongodb -- mongosh agendaapp"
