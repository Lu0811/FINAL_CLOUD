# 📋 Comandos de Ejecución - AgendaApp con Jenkins e IaC

##  Configuración Inicial

### Variables de Entorno
```bash
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export PROJECT_ID=kubernetes-474008
export REGION=us-central1
export CLUSTER_NAME=agendaapp-cluster
```

##  Infraestructura como Código (OpenTofu)

### Desplegar Infraestructura Completa
```bash
cd "/home/teriyaki/Música/big data/infrastructure/opentofu"
chmod +x deploy.sh
./deploy.sh
```

### Bootstrap Jenkins + IaC Automatizado
```bash
cd "/home/teriyaki/Música/big data/infrastructure"
chmod +x bootstrap-jenkins-iac.sh
./bootstrap-jenkins-iac.sh
```

### Comandos OpenTofu Individuales
```bash
cd "/home/teriyaki/Música/big data/infrastructure/opentofu"

# Inicializar
tofu init

# Planificar
tofu plan -var-file=environments/dev/terraform.tfvars

# Aplicar
tofu apply -var-file=environments/dev/terraform.tfvars -auto-approve

# Ver estado
tofu state list

# Ver outputs
tofu output

# Destruir (¡CUIDADO!)
tofu destroy -var-file=environments/dev/terraform.tfvars
```

##  Jenkins - Gestión y Configuración

### Verificar Estado de Jenkins
```bash
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Ver pods de Jenkins
kubectl get pods -n jenkins

# Ver servicios de Jenkins
kubectl get svc -n jenkins

# Ver logs de Jenkins
kubectl logs -n jenkins -l app=jenkins --tail=50

# Ver logs en tiempo real
kubectl logs -n jenkins -l app=jenkins -f
```

### Obtener Credenciales de Jenkins
```bash
# Obtener IP externa
JENKINS_IP=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Jenkins URL: http://${JENKINS_IP}:8080"

# Obtener contraseña inicial
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n jenkins ${JENKINS_POD} -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### Reiniciar Jenkins
```bash
# Reiniciar el pod
kubectl delete pod -n jenkins -l app=jenkins

# Esperar a que esté listo
kubectl wait --for=condition=ready pod -l app=jenkins -n jenkins --timeout=300s
```

### Configuración Automatizada de Jenkins
```bash
cd "/home/teriyaki/Música/big data/infrastructure"

# Setup completo de Jenkins
chmod +x setup-jenkins.sh
./setup-jenkins.sh

# Crear pipeline automáticamente
chmod +x crear-pipeline.sh
./crear-pipeline.sh
```

##  Gestión de la Aplicación (AgendaApp)

### Despliegue Manual de AgendaApp
```bash
cd "/home/teriyaki/Música/big data/AgendaApp/k8s"

# Desplegar todo
chmod +x deploy.sh
./deploy.sh

# O paso a paso:
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f backend-postgres-working.yaml
kubectl apply -f frontend-deployment.yaml
```

### Verificar Estado de la Aplicación
```bash
# Ver todos los pods
kubectl get pods

# Ver servicios
kubectl get services

# Ver pods con más detalles
kubectl get pods -o wide

# Verificar IPs externas
kubectl get svc -o wide

# Estado específico de deployments
kubectl get deployments
```

### Obtener URLs de Acceso
```bash
# Frontend
FRONTEND_IP=$(kubectl get svc frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend: http://${FRONTEND_IP}"

# Backend
BACKEND_IP=$(kubectl get svc backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Backend: http://${BACKEND_IP}:5000"

# Health check del backend
curl -s http://${BACKEND_IP}:5000/health
```

### Limpieza de la Aplicación
```bash
cd "/home/teriyaki/Música/big data/AgendaApp/k8s"

# Limpiar todo
chmod +x cleanup.sh
./cleanup.sh

# O manual:
kubectl delete -f frontend-deployment.yaml
kubectl delete -f backend-postgres-working.yaml
kubectl delete -f postgres-deployment.yaml
kubectl delete -f postgres-pvc.yaml
```

##  Monitoreo y Logs

### Ver Logs de Aplicación
```bash
# Logs del frontend
kubectl logs -l app=frontend --tail=50

# Logs del backend
kubectl logs -l app=backend-postgres --tail=50

# Logs de PostgreSQL
kubectl logs -l app=postgres --tail=50

# Logs en tiempo real
kubectl logs -l app=backend-postgres -f
```

### Acceso a Bases de Datos
```bash
# Conectar a PostgreSQL
kubectl exec -it deployment/postgres -- psql -U postgres -d agendaapp

# Ver tablas en PostgreSQL
kubectl exec -it deployment/postgres -- psql -U postgres -d agendaapp -c "\dt"

# Verificar conexión a BD
kubectl exec -it deployment/postgres -- pg_isready -U postgres
```

### Health Checks
```bash
# Health check manual del backend
BACKEND_IP=$(kubectl get svc backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -f http://${BACKEND_IP}:5000/health

# Verificar que todos los pods estén ready
kubectl get pods --field-selector=status.phase=Running

# Ver eventos del cluster
kubectl get events --sort-by=.metadata.creationTimestamp
```

##  Pipelines de Jenkins

### Ejecutar Pipeline desde Terminal
```bash
# Pipeline de health check
curl -X POST http://35.232.149.227:8080/job/agendaapp-healthcheck/build

# Ver resultado (esperar 10 segundos)
sleep 10
curl http://35.232.149.227:8080/job/agendaapp-healthcheck/1/consoleText

# Pipeline completo de despliegue
curl -X POST http://35.232.149.227:8080/job/agendaapp-deploy/build
```

### Verificar Pipeline desde Jenkins UI
```bash
echo "Jenkins URLs:"
echo "- Principal: http://35.232.149.227:8080"
echo "- Pipeline Health Check: http://35.232.149.227:8080/job/agendaapp-healthcheck"
echo "- Pipeline Deploy: http://35.232.149.227:8080/job/agendaapp-deploy"
```

## 🐳 Docker y Registry

### Construir Imágenes Localmente
```bash
cd "/home/teriyaki/Música/big data/AgendaApp"

# Backend
cd backend
docker build -t backend:latest .

# Frontend
cd ../frontend
docker build -t frontend:latest .
```

### Subir a Artifact Registry
```bash
# Configurar Docker para GCP
gcloud auth configure-docker us-central1-docker.pkg.dev

# Tags para el registry
docker tag backend:latest us-central1-docker.pkg.dev/kubernetes-474008/agendaapp/backend:latest
docker tag frontend:latest us-central1-docker.pkg.dev/kubernetes-474008/agendaapp/frontend:latest

# Push al registry
docker push us-central1-docker.pkg.dev/kubernetes-474008/agendaapp/backend:latest
docker push us-central1-docker.pkg.dev/kubernetes-474008/agendaapp/frontend:latest
```

## ⚙️ Configuración del Cluster

### Conectar kubectl al Cluster
```bash
gcloud container clusters get-credentials agendaapp-cluster \
  --region us-central1 \
  --project kubernetes-474008
```

### Verificar Configuración
```bash
# Ver contexto actual
kubectl config current-context

# Ver nodos del cluster
kubectl get nodes

# Ver namespaces
kubectl get namespaces

# Ver recursos en todos los namespaces
kubectl get all --all-namespaces
```

### Escalado de Aplicación
```bash
# Escalar backend
kubectl scale deployment backend-postgres --replicas=3

# Escalar frontend
kubectl scale deployment frontend --replicas=2

# Ver estado del escalado
kubectl get deployments

# Auto-scaling (si está configurado)
kubectl get hpa
```

## 🛠️ Troubleshooting

### Reiniciar Componentes
```bash
# Reiniciar backend
kubectl rollout restart deployment/backend-postgres

# Reiniciar frontend
kubectl rollout restart deployment/frontend

# Reiniciar PostgreSQL
kubectl rollout restart deployment/postgres

# Ver estado del restart
kubectl rollout status deployment/backend-postgres
```

### Debugging
```bash
# Describir pod con problemas
kubectl describe pod <pod-name>

# Entrar a un pod
kubectl exec -it <pod-name> -- /bin/bash

# Ver recursos del cluster
kubectl top nodes
kubectl top pods

# Ver configuración de servicios
kubectl describe svc frontend-service
kubectl describe svc backend-postgres-service
```

### Verificar Conectividad
```bash
# Test de conectividad entre pods
kubectl exec -it deployment/frontend -- curl backend-postgres-service:5000/health

# Test desde fuera del cluster
BACKEND_IP=$(kubectl get svc backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -v http://${BACKEND_IP}:5000/health

# Test de DNS interno
kubectl exec -it deployment/frontend -- nslookup backend-postgres-service
```

## 📊 Comandos de Verificación Completa

### Script de Verificación General
```bash
echo "=== VERIFICACIÓN COMPLETA DE AGENDAAPP ==="
echo ""
echo "1. Estado del cluster:"
kubectl get nodes
echo ""
echo "2. Pods en ejecución:"
kubectl get pods
echo ""
echo "3. Servicios expuestos:"
kubectl get services
echo ""
echo "4. Deployments:"
kubectl get deployments
echo ""
echo "5. URLs de acceso:"
FRONTEND_IP=$(kubectl get svc frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pendiente")
BACKEND_IP=$(kubectl get svc backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pendiente")
echo "   Frontend: http://${FRONTEND_IP}"
echo "   Backend:  http://${BACKEND_IP}:5000"
echo ""
echo "6. Health check:"
if [ "$BACKEND_IP" != "Pendiente" ]; then
    curl -s http://${BACKEND_IP}:5000/health || echo "Backend no responde"
else
    echo "Backend IP no disponible aún"
fi
echo ""
echo "7. Jenkins:"
JENKINS_IP=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "No disponible")
echo "   Jenkins: http://${JENKINS_IP}:8080"
```

## 🔄 Comandos de Mantenimiento

### Backup y Restore
```bash
# Backup de la base de datos
kubectl exec deployment/postgres -- pg_dump -U postgres agendaapp > backup.sql

# Restore (ejemplo)
kubectl exec -i deployment/postgres -- psql -U postgres agendaapp < backup.sql
```

### Actualizar Aplicación
```bash
# Actualizar imagen del backend
kubectl set image deployment/backend-postgres backend=us-central1-docker.pkg.dev/kubernetes-474008/agendaapp/backend:v2.0

# Actualizar imagen del frontend
kubectl set image deployment/frontend frontend=us-central1-docker.pkg.dev/kubernetes-474008/agendaapp/frontend:v2.0

# Ver progreso de la actualización
kubectl rollout status deployment/backend-postgres
kubectl rollout status deployment/frontend
```

### Limpieza Completa
```bash
# Eliminar aplicación
cd "/home/teriyaki/Música/big data/AgendaApp/k8s"
./cleanup.sh

# Eliminar Jenkins
kubectl delete namespace jenkins

# Destruir infraestructura (¡CUIDADO!)
cd "/home/teriyaki/Música/big data/infrastructure/opentofu"
tofu destroy -var-file=environments/dev/terraform.tfvars
```

---

## 📚 Notas Importantes

1. **Siempre configura las variables de entorno** antes de ejecutar comandos de GCP
2. **Verifica que kubectl esté conectado** al cluster correcto antes de aplicar cambios
3. **Los LoadBalancers tardan unos minutos** en obtener IP externa
4. **Jenkins necesita 2-3 minutos** para estar completamente operativo después del despliegue
5. **Guarda las IPs externas** una vez asignadas para acceso rápido

## 🎯 URLs de Acceso Rápido

- **Jenkins**: http://35.232.149.227:8080 (IP fija)
- **Frontend**: Verificar con `kubectl get svc frontend-service`
- **Backend**: Verificar con `kubectl get svc backend-postgres-service`
- **Health Check**: `curl http://BACKEND_IP:5000/health`