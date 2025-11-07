FROM nginx:1.25-alpine


# Se ejecuta antes del despliegue en KubernetesCOPY index.html /usr/share/nginx/html/

COPY config.js /usr/share/nginx/html/

# Obtener la IP externa del servicio backendCOPY app.js /usr/share/nginx/html/

BACKEND_IP=$(kubectl get service backend-postgres-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)COPY style.css /usr/share/nginx/html/



if [ -z "$BACKEND_IP" ]; thenRUN chown -R nginx:nginx /usr/share/nginx/html && \

    echo "  La IP del backend aún no está disponible"    chmod -R 755 /usr/share/nginx/html

    echo "Usando nombre de servicio interno de Kubernetes"

    BACKEND_URL="http://backend-postgres-service:5000"EXPOSE 80

else

    echo " IP del backend obtenida: $BACKEND_IP"HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \

    BACKEND_URL="http://$BACKEND_IP:5000"    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

fi

CMD ["nginx", "-g", "daemon off;"]
# Crear ConfigMap con la URL del backend
kubectl create configmap frontend-config \
    --from-literal=BACKEND_URL="$BACKEND_URL" \
    --dry-run=client -o yaml | kubectl apply -f -

echo " ConfigMap creado con BACKEND_URL=$BACKEND_URL"
