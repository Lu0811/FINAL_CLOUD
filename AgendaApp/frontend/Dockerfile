FROM nginx:1.25-alpine

# Copiar archivos estáticos del frontend
COPY index.html /usr/share/nginx/html/
COPY config.js /usr/share/nginx/html/
COPY app.js /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/

# Configurar permisos
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Exponer puerto 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Comando por defecto
CMD ["nginx", "-g", "daemon off;"]
