#!/bin/bash
echo "🧪 PROBANDO GITHUB ACTIONS"
echo "=========================="
echo ""

# Hacer un cambio pequeño para activar el workflow
echo "// Test GitHub Actions - $(date)" >> AgendaApp/backend/app.py

# Commit y push
git add .
git commit -m "🧪 Test GitHub Actions CI/CD"
git push

echo ""
echo "✅ Push realizado!"
echo ""
echo "🎯 Ahora verifica en:"
echo "   https://github.com/Lu0811/FINAL_CLOUD/actions"
echo ""
echo "👀 Deberías ver:"
echo "   ✅ Un workflow 'AgendaApp CI/CD' ejecutándose"
echo "   ✅ Status: 🟡 In progress → 🟢 Success (si todo OK)"
echo "   ✅ Tiempo: ~3-5 minutos"
echo ""
echo "🚀 Si ves ✅ Success, significa que:"
echo "   • Las imágenes se construyeron"
echo "   • Se subieron a Artifact Registry"
echo "   • Se desplegaron en GKE"
echo "   • ¡Tu app está actualizada!"