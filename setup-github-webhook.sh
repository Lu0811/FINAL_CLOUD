#!/bin/bash
echo "🔗 Configurando GitHub Hook para Jenkins"
echo ""

# Variables
GITHUB_REPO="Lu0811/FINAL_CLOUD"
JENKINS_URL="http://35.232.149.227:8080"
WEBHOOK_URL="${JENKINS_URL}/github-webhook/"

echo "📋 Configuración:"
echo "   GitHub Repo: ${GITHUB_REPO}"
echo "   Jenkins URL: ${JENKINS_URL}"
echo "   Webhook URL: ${WEBHOOK_URL}"
echo ""

echo "🔧 PASOS PARA CONFIGURAR GITHUB HOOK:"
echo ""
echo "=== 1. EN JENKINS ==="
echo "   1. Ir a: ${JENKINS_URL}"
echo "   2. Abrir job: 'agendaapp-healthcheck'"
echo "   3. Click 'Configure'"
echo "   4. En 'Source Code Management':"
echo "      ☑️ Git"
echo "      Repository URL: https://github.com/${GITHUB_REPO}.git"
echo "      Branch: */main"
echo "   5. En 'Build Triggers':"
echo "      ☑️ GitHub hook trigger for GITScm polling"
echo "   6. Save"
echo ""

echo "=== 2. EN GITHUB ==="
echo "   1. Ir a: https://github.com/${GITHUB_REPO}"
echo "   2. Settings → Webhooks → Add webhook"
echo "   3. Configurar:"
echo "      Payload URL: ${WEBHOOK_URL}"
echo "      Content type: application/json"
echo "      Which events: Just the push event"
echo "      Active: ✅"
echo "   4. Add webhook"
echo ""

echo "=== 3. VERIFICAR CONEXIÓN ==="
echo "   Hacer un cambio pequeño en el repo y push:"
echo "   git add ."
echo "   git commit -m 'Test webhook'"
echo "   git push"
echo ""
echo "   Jenkins debería ejecutarse automáticamente!"
echo ""

echo "🧪 COMANDO PARA PROBAR WEBHOOK MANUALMENTE:"
echo "curl -X POST ${WEBHOOK_URL}"
echo ""

echo "📍 URLs IMPORTANTES:"
echo "   Jenkins: ${JENKINS_URL}"
echo "   GitHub: https://github.com/${GITHUB_REPO}"
echo "   Webhook: ${WEBHOOK_URL}"
echo ""

# Verificar que Jenkins esté accesible
echo "🔍 Verificando Jenkins..."
if curl -s -f ${JENKINS_URL} > /dev/null; then
    echo "✅ Jenkins accesible en ${JENKINS_URL}"
else
    echo "❌ Jenkins no accesible. Verificar que esté corriendo."
fi

echo ""
echo "🎯 DESPUÉS DE CONFIGURAR:"
echo "   • Cada git push → Jenkins ejecuta automáticamente"
echo "   • Sin esperas de 5 minutos"
echo "   • Integración continua real"