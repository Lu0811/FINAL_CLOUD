# 🚀 Jenkins Local para Infraestructura como Código

## ✅ Jenkins está corriendo

**URL:** http://localhost:8080

**Contraseña inicial:** `6cdc4ab5fc1040cf8109c019d719f108`

---

## 📋 Pasos para configurar Jenkins

### 1. Acceder a Jenkins
1. Abre tu navegador en: **http://localhost:8080**
2. Usa la contraseña: `6cdc4ab5fc1040cf8109c019d719f108`
3. Selecciona **"Install suggested plugins"**
4. Crea tu usuario admin (o salta este paso)

### 2. Agregar credenciales de GCP
1. Ve a **Manage Jenkins** → **Manage Credentials**
2. Click en **(global)** domain
3. Click en **Add Credentials**
4. Configura:
   - **Kind:** Secret file
   - **File:** Sube `/home/teriyaki/Música/big data/infrastructure/jenkins-iac-credentials.json`
   - **ID:** `gcp-jenkins-iac-credentials`
   - **Description:** GCP Service Account para IaC
5. Click **Create**

### 3. Crear el Pipeline de IaC
1. En el Dashboard, click **New Item**
2. Nombre: `agendaapp-infrastructure-auto`
3. Tipo: **Pipeline**
4. Click **OK**
5. En la configuración del pipeline:
   - **Build Triggers:** Marca "GitHub hook trigger for GITScm polling" (opcional para automatizar)
   - **Pipeline:**
     - **Definition:** Pipeline script
     - **Script:** Copia el contenido del archivo:
       ```bash
       /home/teriyaki/Música/big data/infrastructure/jenkins-pipeline-script.groovy
       ```
       
       > 💡 **TIP:** Puedes ver el contenido con: `cat jenkins-pipeline-script.groovy`

6. Click **Save**

### 4. Ejecutar el Pipeline
1. En el pipeline `agendaapp-infrastructure-auto`, click **Build Now**
2. El pipeline:
   - ✅ Autenticará con GCP
   - ✅ Inicializará OpenTofu
   - ✅ Validará la configuración
   - ✅ Generará un plan
   - ✅ **Aplicará automáticamente** los cambios (creará VPC, GKE, Artifact Registry)
   - ✅ Mostrará los outputs de la infraestructura

---

## 🔧 Herramientas disponibles en Jenkins

El contenedor de Jenkins tiene instalado:
- ✅ **OpenTofu** (`tofu`) - Para gestionar IaC
- ✅ **gcloud CLI** - Para interactuar con GCP
- ✅ **kubectl** - Para gestionar Kubernetes

## 📂 Archivos montados

- **IaC:** `/workspace/infrastructure/opentofu` (read-only)
- **Credenciales GCP:** `/var/secrets/gcp/key.json`

---

## 🎯 Resultado esperado

Después de ejecutar el pipeline, tendrás:
- ✅ VPC con subnets configuradas
- ✅ GKE cluster con nodos e2-medium (1-3 nodos)
- ✅ Artifact Registry para imágenes Docker
- ✅ Firewall rules
- ✅ Cloud NAT
- ❌ CloudSQL (deshabilitado - requiere private service connection)

---

## 🔄 Flujo automático

**A partir de ahora:**
1. Haces cambios en archivos `.tf` en `/home/teriyaki/Música/big data/infrastructure/opentofu/`
2. Ejecutas el pipeline en Jenkins (o configuras webhook de Git)
3. Jenkins automáticamente aplica los cambios con `tofu apply`

---

## 🛑 Comandos útiles

```bash
# Ver logs de Jenkins
docker logs jenkins-iac -f

# Reiniciar Jenkins
cd /home/teriyaki/Música/big\ data/infrastructure/jenkins
docker compose restart

# Detener Jenkins
docker compose down

# Levantar Jenkins
docker compose up -d

# Acceder al contenedor
docker exec -it jenkins-iac bash
```

---

## ⚠️ Troubleshooting

### Jenkins no responde
```bash
docker logs jenkins-iac
```

### Verificar credenciales GCP dentro del contenedor
```bash
docker exec jenkins-iac cat /var/secrets/gcp/key.json
```

### Verificar archivos IaC
```bash
docker exec jenkins-iac ls -la /workspace/infrastructure/opentofu
```

---

## 📝 Próximos pasos

Después de que Jenkins cree la infraestructura:
1. Configurar kubectl para el nuevo cluster
2. Desplegar AgendaApp en el cluster
3. Configurar pipeline para la aplicación (build + deploy automático)
