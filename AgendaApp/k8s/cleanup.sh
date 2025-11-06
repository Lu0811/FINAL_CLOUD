#!/bin/bash

echo "🧹 Limpiando despliegue de AgendaApp..."

# Eliminar frontend
echo "🌐 Eliminando Frontend..."
kubectl delete -f frontend-deployment.yaml

# Eliminar backend
echo "🔧 Eliminando Backend..."
kubectl delete -f backend-deployment.yaml

# Eliminar MongoDB
echo "🍃 Eliminando MongoDB..."
kubectl delete -f mongo-deployment.yaml

# Eliminar almacenamiento (CUIDADO: esto borra los datos)
echo "📦 Eliminando almacenamiento persistente..."
kubectl delete -f mongo-pvc.yaml

echo ""
echo "✅ Limpieza completada!"
echo ""
echo "📊 Pods restantes:"
kubectl get pods

echo ""
echo "🌐 Servicios restantes:"
kubectl get services
