// Configuración dinámica de la API del backend
// Este archivo se genera automáticamente al desplegar

// Detectar si estamos en producción (Kubernetes) o desarrollo (local)
function getBackendURL() {
    // Si hay una variable de entorno inyectada por Kubernetes, usarla
    const backendFromEnv = window.BACKEND_URL;
    if (backendFromEnv) {
        return backendFromEnv;
    }
    
    // Si estamos en localhost, usar localhost
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
        return 'http://localhost:5000';
    }
    
    // En producción, usar la IP externa del backend LoadBalancer
    // IP externa del servicio backend-postgres-service
    return window.BACKEND_SERVICE_URL || 'http://34.41.85.14:5000';
}

// Exportar la URL configurada
const API_BASE_URL = getBackendURL();

console.log('🔗 Backend URL configurada:', API_BASE_URL);
