#!/bin/bash
echo "🔄 Configurando Auto-Deploy Local con Git Hooks"

# Crear script de post-commit
cat > .git/hooks/post-commit <<'EOF'
#!/bin/bash
echo "🚀 Auto-Deploy activado por commit..."

# Solo hacer deploy si hay cambios en AgendaApp/
if git diff-tree --name-only HEAD^ HEAD | grep -q "AgendaApp/"; then
    echo "📦 Cambios detectados en AgendaApp, iniciando deploy..."
    ./deploy-fast.sh
else
    echo "ℹ️  No hay cambios en AgendaApp, skip deploy"
fi
EOF

# Hacer ejecutable
chmod +x .git/hooks/post-commit

echo "✅ Auto-Deploy configurado!"
echo ""
echo "🎯 Cómo funciona:"
echo "   1. Haces cambios en AgendaApp/"
echo "   2. git add . && git commit -m 'cambios'"
echo "   3. Automáticamente se ejecuta deploy-fast.sh"
echo "   4. En 3-5 minutos tu app está actualizada"
echo ""
echo "🧪 Para probar:"
echo "   echo '// test' >> AgendaApp/backend/app.py"
echo "   git add . && git commit -m 'test auto-deploy'"