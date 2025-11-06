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
    
    // En producción, obtener la IP externa del backend
    // Esta será inyectada por el ConfigMap de Kubernetes
    return window.BACKEND_SERVICE_URL || 'http://backend-postgres-service:5000';
}

// Exportar la URL configurada
const API_BASE_URL = getBackendURL();

console.log('🔗 Backend URL configurada:', API_BASE_URL);
