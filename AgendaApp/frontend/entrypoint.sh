#!/bin/sh
# Script de inicio para el frontend de AgendaApp
# Genera el archivo config.js con la URL del backend desde variable de entorno

# Obtener la URL del backend desde variable de entorno o usar default
BACKEND_URL=${BACKEND_URL:-"http://backend-postgres-service:5000"}

echo "🔧 Configurando frontend con backend: $BACKEND_URL"

# Generar config.js dinámicamente
cat > /usr/share/nginx/html/config.js <<EOF
// Configuración dinámica generada al inicio del contenedor
// Backend URL: $BACKEND_URL

// Variable global para la URL del backend
window.BACKEND_SERVICE_URL = '$BACKEND_URL';

// Detectar si estamos en producción (Kubernetes) o desarrollo (local)
function getBackendURL() {
    // Si estamos en localhost, usar localhost
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
        return 'http://localhost:5000';
    }
    
    // En producción, usar la URL inyectada
    return window.BACKEND_SERVICE_URL;
}

// Exportar la URL configurada
const API_BASE_URL = getBackendURL();

console.log('🔗 Backend URL configurada:', API_BASE_URL);
EOF

echo "✅ config.js generado exitosamente"
echo "📄 Contenido:"
cat /usr/share/nginx/html/config.js

# Iniciar nginx
echo ""
echo "🚀 Iniciando nginx..."
exec nginx -g 'daemon off;'
