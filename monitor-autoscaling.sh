#!/bin/bash
echo "=== MONITOR DE AUTOESCALAMIENTO ==="
echo "Presiona Ctrl+C para salir"
echo ""

while true; do
    clear
    echo " $(date)"
    echo ""
    
    echo "  NODOS (Uso de Recursos):"
    kubectl top nodes 2>/dev/null || echo "Métricas no disponibles"
    echo ""
    
    echo " PODS ACTIVOS:"
    kubectl get pods -o wide | grep -E "NAME|backend|frontend"
    echo ""
    
    echo " HORIZONTAL POD AUTOSCALER:"
    kubectl get hpa
    echo ""
    
    echo " CONSUMO DE RECURSOS:"
    kubectl top pods 2>/dev/null | grep -E "NAME|backend|frontend" || echo "Métricas no disponibles"
    echo ""
    
    echo " Próxima actualización en 10 segundos..."
    sleep 10
done