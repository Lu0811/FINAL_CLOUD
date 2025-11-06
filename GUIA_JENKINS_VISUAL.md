# 🎯 GUÍA VISUAL - Usar Jenkins con Tu AgendaApp

## ✅ PASO 1: Abre Jenkins en tu Navegador

**URL:** http://35.232.149.227:8080

Deberías ver la pantalla principal de Jenkins con:
- "Welcome to Jenkins!" en el centro
- Un menú lateral izquierdo

---

## ✅ PASO 2: Busca Tu Pipeline

En la pantalla principal, deberías ver una tabla con:

```
┌─────────────────────────────────────────────────┐
│  Name                    │ Last Success │ ...  │
├─────────────────────────────────────────────────┤
│  📁 agendaapp-healthcheck │     —        │  →   │
└─────────────────────────────────────────────────┘
```

**Si NO ves el job "agendaapp-healthcheck":**
- Refresca la página (F5)
- O ejecuta esto en terminal:
  ```bash
  kubectl delete pod -n jenkins -l app=jenkins
  ```
  Espera 1 minuto y recarga la página

---

## ✅ PASO 3: Entra al Pipeline

1. **Click en "agendaapp-healthcheck"** (el nombre azul)
2. Verás la página del job

---

## ✅ PASO 4: Ejecuta el Pipeline

En la página del job, en el menú lateral izquierdo:

1. **Click en "Build Now"** 
2. Aparecerá "#1" en "Build History" (abajo a la izquierda)
3. **Click en "#1"** (el número azul)
4. **Click en "Console Output"** (menú lateral)

---

## ✅ PASO 5: Mira los Resultados

Verás algo como esto:

```
Started by user anonymous
Running on Jenkins in /var/jenkins_home/workspace/agendaapp-healthcheck
[Pipeline] Start of Pipeline
[Pipeline] node
[Pipeline] {
[Pipeline] stage
[Pipeline] { (🏥 Health Check Backend)
[Pipeline] echo
=== Verificando tu Backend de AgendaApp ===
[Pipeline] sh
+ curl -s http://34.71.155.58:5000/health
{"database":"connected","status":"healthy","tasks_count":4}
[Pipeline] echo
✅ Backend funcionando correctamente
[Pipeline] }
[Pipeline] stage
[Pipeline] { (📝 Verificar Tareas)
[Pipeline] echo
=== Obteniendo tareas actuales ===
[Pipeline] sh
+ curl -s http://34.71.155.58:5000/tasks
[{"id":1,"title":"Tarea 1",...}]
[Pipeline] }
[Pipeline] stage
[Pipeline] { (🌐 Verificar Frontend)
[Pipeline] echo
✅ Frontend funcionando correctamente
[Pipeline] }
...
✅ ¡Tu AgendaApp está funcionando perfectamente!
```

---

## 🔄 PASO 6: Ejecutarlo de Nuevo

Para volver a ejecutar el pipeline:
1. Click en "← Back to Project" (arriba)
2. Click en "Build Now" otra vez
3. Verás "#2", "#3", etc.

---

## 📊 ¿QUÉ HACE ESTE PIPELINE?

Este pipeline verifica TU aplicación AgendaApp:

### Etapa 1: Health Check Backend
- Hace `curl` a tu backend: http://34.71.155.58:5000/health
- Muestra si está saludable
- ✅ Verifica la conexión con PostgreSQL

### Etapa 2: Ver Tareas
- Obtiene las tareas de tu app: http://34.71.155.58:5000/tasks
- Muestra cuántas tareas tienes

### Etapa 3: Verificar Frontend
- Verifica que tu frontend responda: http://34.70.211.16
- Confirma que la UI está accesible

### Etapa 4: Resumen
- Muestra un resumen de todo
- URLs de tu aplicación
- Estado final

---

## 🎨 INTERFAZ DE JENKINS - QUÉ SIGNIFICA CADA COLOR

```
🔵 Azul    = Build exitoso (todo bien)
🔴 Rojo    = Build falló (algo salió mal)
⚪ Gris    = Build no ejecutado aún
🟡 Amarillo = Build inestable (warnings)
```

---

## 🚀 COMANDOS RÁPIDOS DESDE TERMINAL

### Ver si Jenkins está corriendo:
```bash
export CLOUDSDK_PYTHON=/usr/bin/python3.11
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
kubectl get pods -n jenkins
```

### Ver logs de Jenkins:
```bash
kubectl logs -n jenkins -l app=jenkins --tail=50
```

### Ejecutar el pipeline desde terminal:
```bash
# Método simple (sin autenticación)
curl -X POST http://35.232.149.227:8080/job/agendaapp-healthcheck/build

# Esperar 10 segundos y ver resultado
sleep 10
curl http://35.232.149.227:8080/job/agendaapp-healthcheck/1/consoleText
```

### Ver último build desde terminal:
```bash
# Ver resultado del último build
LAST_BUILD=$(curl -s http://35.232.149.227:8080/job/agendaapp-healthcheck/lastBuild/buildNumber)
echo "Último build: #$LAST_BUILD"

curl -s http://35.232.149.227:8080/job/agendaapp-healthcheck/$LAST_BUILD/consoleText | tail -30
```

### Reiniciar Jenkins si algo no funciona:
```bash
kubectl delete pod -n jenkins -l app=jenkins
# Esperar 1 minuto
sleep 60
```

---

## 📁 ESTRUCTURA DE TU PROYECTO CON JENKINS

```
Tu Infraestructura
├── 🌐 Frontend (34.70.211.16)
│   └── HTML + JavaScript
│
├── 🔧 Backend (34.71.155.58:5000)
│   └── Flask + Python
│
├── 🗄️ PostgreSQL
│   └── Base de datos con tus tareas
│
└── 🤖 Jenkins (35.232.149.227:8080)
    └── Verifica automáticamente que todo funcione
        ├── Health Check Backend ✅
        ├── Obtener Tareas ✅
        └── Verificar Frontend ✅
```

---

## 🎯 PRÓXIMOS PASOS

Una vez que veas que el pipeline funciona:

### 1. Agregar más verificaciones
Edita el pipeline para agregar más checks:
- Verificar cuántas tareas hay
- Crear una tarea de prueba
- Borrar una tarea de prueba

### 2. Programar ejecución automática
Hacer que el pipeline se ejecute automáticamente cada X minutos:
- En el job, click "Configure"
- Busca "Build Triggers"
- Marca "Build periodically"
- Ingresa: `H/5 * * * *` (cada 5 minutos)

### 3. Crear más pipelines
- Pipeline para reiniciar la app
- Pipeline para escalar replicas
- Pipeline para desplegar cambios

---

## ❓ TROUBLESHOOTING

### Problema: No veo el job "agendaapp-healthcheck"
**Solución:**
```bash
# Reiniciar Jenkins
kubectl delete pod -n jenkins -l app=jenkins
# Esperar 1 minuto y recargar la página
```

### Problema: El build falla con error de conexión
**Solución:**
```bash
# Verificar que tu app esté corriendo
kubectl get pods

# Verificar backend
curl http://34.71.155.58:5000/health

# Verificar frontend
curl http://34.70.211.16
```

### Problema: Jenkins no responde
**Solución:**
```bash
# Ver estado del pod
kubectl get pods -n jenkins

# Ver logs
kubectl logs -n jenkins -l app=jenkins --tail=100

# Reiniciar
kubectl delete pod -n jenkins -l app=jenkins
```

### Problema: El pipeline se queda "en progreso" sin terminar
**Solución:**
- Espera 30 segundos más
- Si sigue trabado, cancela el build (botón rojo X)
- Ejecuta "Build Now" de nuevo

---

## 📞 RESUMEN RÁPIDO

```bash
# 1. Abrir Jenkins
firefox http://35.232.149.227:8080

# 2. Click en "agendaapp-healthcheck"
# 3. Click en "Build Now"
# 4. Click en "#1"
# 5. Click en "Console Output"
# 6. ¡Mira los resultados! 🎉
```

---

## ✅ CHECKLIST

- [ ] Jenkins abierto en navegador
- [ ] Job "agendaapp-healthcheck" visible
- [ ] Ejecutado "Build Now"
- [ ] Visto el resultado en Console Output
- [ ] Build exitoso (bolita azul)
- [ ] Se ven los resultados de tu backend
- [ ] Se ven las tareas de tu app

**Una vez completado esto, ¡Jenkins está funcionando con tu proyecto!** 🎉

---

**Última actualización:** 6 de Noviembre 2025
