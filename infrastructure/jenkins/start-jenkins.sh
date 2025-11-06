#!/bin/bash

# Script para levantar Jenkins local con OpenTofu y gcloud

set -e

echo "🚀 =============================================="
echo "   LEVANTANDO JENKINS LOCAL PARA IaC"
echo "=============================================="
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}"

# Verificar que existen las credenciales GCP
if [ ! -f "../jenkins-iac-credentials.json" ]; then
    echo "❌ Error: No se encontró el archivo de credenciales"
    echo "   Ubicación esperada: ../jenkins-iac-credentials.json"
    exit 1
fi

echo "📋 Paso 1: Construir imagen de Jenkins personalizada"
echo "----------------------------------------"
docker compose build
echo "✅ Imagen construida"
echo ""

echo "📋 Paso 2: Levantar Jenkins"
echo "----------------------------------------"
docker compose up -d
echo "✅ Jenkins iniciado"
echo ""

echo "⏳ Esperando a que Jenkins esté listo..."
sleep 30

echo ""
echo "📋 Paso 3: Obtener contraseña inicial de Jenkins"
echo "----------------------------------------"
INITIAL_PASSWORD=$(docker exec jenkins-iac cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "")

if [ -z "$INITIAL_PASSWORD" ]; then
    echo "⚠️  Contraseña aún no disponible. Espera 1 minuto y ejecuta:"
    echo "   docker exec jenkins-iac cat /var/jenkins_home/secrets/initialAdminPassword"
else
    echo "📝 Contraseña inicial de Jenkins:"
    echo "   ${INITIAL_PASSWORD}"
fi

echo ""
echo "✅ =============================================="
echo "   JENKINS LISTO"
echo "=============================================="
echo ""
echo "🌐 Accede a Jenkins: http://localhost:8080"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Abre http://localhost:8080 en tu navegador"
echo "   2. Usa la contraseña mostrada arriba"
echo "   3. Instala los plugins sugeridos"
echo "   4. Crea un nuevo Pipeline llamado 'agendaapp-infrastructure'"
echo "   5. En Pipeline > Definition, selecciona 'Pipeline script'"
echo "   6. Copia el contenido de: ../jenkins-iac-pipeline-auto-apply.xml"
echo ""
echo "💡 Jenkins tiene acceso a:"
echo "   • OpenTofu (tofu)"
echo "   • Google Cloud SDK (gcloud)"
echo "   • kubectl"
echo "   • Credenciales GCP en /var/secrets/gcp/key.json"
echo "   • Archivos IaC en /workspace/infrastructure/opentofu"
echo ""
