#!/bin/bash

# Script para recrear infraestructura con Jenkins configurado para aplicar cambios automáticamente
# Este script es el "bootstrap" inicial - después de esto, Jenkins se encargará de todo

set -e

export CLOUDSDK_PYTHON=/usr/bin/python3.11
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)

echo "🚀 =============================================="
echo "   RECREANDO INFRAESTRUCTURA CON JENKINS"
echo "=============================================="
echo ""

# Directorio de trabajo
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOFU_DIR="${SCRIPT_DIR}/opentofu"

cd "${TOFU_DIR}"

echo "📋 Paso 1: Inicializar OpenTofu"
echo "----------------------------------------"
tofu init -reconfigure
echo "✅ OpenTofu inicializado"
echo ""

echo "📋 Paso 2: Validar configuración"
echo "----------------------------------------"
tofu validate
echo "✅ Configuración válida"
echo ""

echo "📋 Paso 3: Generar plan de infraestructura"
echo "----------------------------------------"
tofu plan -var-file=environments/dev/terraform.tfvars
echo ""
read -p "¿Deseas aplicar estos cambios? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Aplicación cancelada por el usuario"
    exit 1
fi

echo ""
echo "📋 Paso 4: Aplicar infraestructura (VPC, GKE, Artifact Registry)"
echo "----------------------------------------"
tofu apply -var-file=environments/dev/terraform.tfvars -auto-approve

echo ""
echo "✅ Infraestructura base creada"
echo ""

echo "📋 Paso 5: Configurar kubectl para el nuevo cluster"
echo "----------------------------------------"
CLUSTER_NAME=$(tofu output -raw gke_cluster_name)
gcloud container clusters get-credentials ${CLUSTER_NAME} --region=us-central1 --project=kubernetes-474008
echo "✅ kubectl configurado"
echo ""

echo "📋 Paso 6: Desplegar Jenkins en el cluster"
echo "----------------------------------------"
kubectl create namespace jenkins --dry-run=client -o yaml | kubectl apply -f -

# Crear secret con las credenciales de GCP
kubectl create secret generic gcp-jenkins-iac-credentials \
    --from-file=key.json=../jenkins-iac-credentials.json \
    -n jenkins \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret con credenciales GCP creado en Jenkins namespace"
echo ""

echo "📋 Paso 7: Desplegar Jenkins con configuración personalizada"
echo "----------------------------------------"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      serviceAccountName: jenkins
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - containerPort: 8080
        - containerPort: 50000
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        - name: gcp-credentials
          mountPath: /var/secrets/gcp
          readOnly: true
        env:
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: /var/secrets/gcp/key.json
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
      - name: gcp-credentials
        secret:
          secretName: gcp-jenkins-iac-credentials
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: jenkins
spec:
  type: LoadBalancer
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: agent
    port: 50000
    targetPort: 50000
  selector:
    app: jenkins
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: jenkins
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: jenkins
EOF

echo "✅ Jenkins desplegado"
echo ""

echo "📋 Paso 8: Esperando a que Jenkins esté listo..."
echo "----------------------------------------"
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins
echo "✅ Jenkins deployment listo"
echo ""

echo "⏳ Esperando IP externa del LoadBalancer..."
JENKINS_IP=""
for i in {1..30}; do
    JENKINS_IP=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ ! -z "$JENKINS_IP" ]; then
        break
    fi
    echo "   Intento $i/30 - Esperando IP..."
    sleep 10
done

if [ -z "$JENKINS_IP" ]; then
    echo "⚠️  No se pudo obtener la IP del LoadBalancer"
    echo "   Ejecuta: kubectl get svc -n jenkins"
else
    echo "✅ Jenkins disponible en: http://${JENKINS_IP}:8080"
fi

echo ""
echo "📋 Paso 9: Obtener contraseña inicial de Jenkins"
echo "----------------------------------------"
echo "⏳ Esperando 30 segundos para que Jenkins genere la contraseña..."
sleep 30

JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
echo "📝 Contraseña inicial de Jenkins:"
kubectl exec -n jenkins ${JENKINS_POD} -- cat /var/jenkins_home/secrets/initialAdminPassword || echo "⚠️  Aún no disponible, espera unos minutos"

echo ""
echo "✅ =============================================="
echo "   INFRAESTRUCTURA RECREADA CON ÉXITO"
echo "=============================================="
echo ""
echo "📋 Próximos pasos:"
echo "   1. Accede a Jenkins: http://${JENKINS_IP}:8080"
echo "   2. Usa la contraseña mostrada arriba"
echo "   3. Instala los plugins sugeridos"
echo "   4. Crea el pipeline 'agendaapp-infrastructure-auto'"
echo "   5. Usa la configuración en: jenkins-iac-pipeline-auto-apply.xml"
echo ""
echo "🎯 A partir de ahora, cada cambio en la IaC será aplicado automáticamente por Jenkins"
echo ""
