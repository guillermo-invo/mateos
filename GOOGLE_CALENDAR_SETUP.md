# Configuración de Google Calendar con Mateos

## Estado Actual
- ✅ Calendar ID guardado: `c_0c44e02391421207de4f23659eab7603fd098368b04ef8d6d3aaf9ea361d2660@group.calendar.google.com`
- ✅ Nombre del calendario: **trunches**
- ✅ Directorio de secrets creado: `/home/azureuser/mateos/secrets/`
- ⏳ Pendiente: Credenciales de Google Cloud

---

## Opción Recomendada: Service Account

### Paso 1: Crear Proyecto en Google Cloud

1. Ir a https://console.cloud.google.com/
2. En el selector de proyectos (arriba izquierda), click en "New Project"
3. Nombre del proyecto: `Mateos Calendar Sync`
4. Click en "Create"

### Paso 2: Habilitar Google Calendar API

1. En el proyecto recién creado, ir a **APIs & Services > Library**
2. Buscar "Google Calendar API"
3. Click en "Google Calendar API" en los resultados
4. Click en **ENABLE**

### Paso 3: Crear Service Account

1. Ir a **IAM & Admin > Service Accounts**
2. Click en **+ CREATE SERVICE ACCOUNT**
3. Llenar los datos:
   - **Service account name:** `mateos-calendar-sync`
   - **Service account ID:** (se auto-genera)
   - **Description:** "Service account para sincronizar Mateos con Google Calendar"
4. Click en **CREATE AND CONTINUE**
5. En "Grant this service account access to project":
   - NO hace falta seleccionar rol
   - Click en **CONTINUE**
6. En "Grant users access to this service account":
   - Dejar vacío
   - Click en **DONE**

### Paso 4: Descargar JSON Key

1. En la lista de Service Accounts, click en el que acabás de crear (`mateos-calendar-sync`)
2. Ir a la pestaña **KEYS**
3. Click en **ADD KEY > Create new key**
4. Seleccionar tipo **JSON**
5. Click en **CREATE**
6. Se descargará un archivo JSON automáticamente (ej: `mateos-calendar-sync-abc123.json`)

**IMPORTANTE:**
- Este archivo contiene credenciales sensibles
- Solo se descarga UNA VEZ
- Guardarlo en lugar seguro

### Paso 5: Compartir el Calendario con el Service Account

1. En el archivo JSON descargado, buscar el campo `"client_email"`
   - Será algo como: `mateos-calendar-sync@mateos-calendar-sync-123456.iam.gserviceaccount.com`
2. Abrir Google Calendar: https://calendar.google.com/
3. En la lista de calendarios (izquierda), encontrar **"trunches"**
4. Click en los 3 puntos al lado de "trunches" > **Settings and sharing**
5. Scroll down a **"Share with specific people or groups"**
6. Click en **+ Add people and groups**
7. Pegar el email del service account (del paso 1)
8. Permisos: Seleccionar **"Make changes to events"**
9. Click en **SEND**

### Paso 6: Subir Credenciales al Servidor

**Opción A - Desde tu máquina local (recomendado):**

```bash
# Renombrar el archivo descargado para consistencia
mv ~/Downloads/mateos-calendar-sync-*.json ~/Downloads/google-calendar-service-account.json

# Subirlo al servidor vía SCP
scp ~/Downloads/google-calendar-service-account.json azureuser@tu-servidor-ip:/home/azureuser/mateos/secrets/

# O si usás VSCode con Remote SSH, simplemente arrastrá el archivo a:
# /home/azureuser/mateos/secrets/google-calendar-service-account.json
```

**Opción B - Copiar y pegar el contenido:**

Si no podés usar SCP, copiá el contenido del JSON y ejecutá en el servidor:

```bash
cat > /home/azureuser/mateos/secrets/google-calendar-service-account.json << 'EOF'
{
  "type": "service_account",
  "project_id": "...",
  "private_key_id": "...",
  ... (pegar todo el contenido del JSON aquí)
}
EOF

# Configurar permisos correctos
chmod 600 /home/azureuser/mateos/secrets/google-calendar-service-account.json
```

### Paso 7: Verificar la Configuración

Una vez que tengas el archivo en el servidor, ejecutá:

```bash
# Verificar que el archivo existe y tiene permisos correctos
ls -la /home/azureuser/mateos/secrets/

# Verificar que el JSON es válido
python3 -m json.tool /home/azureuser/mateos/secrets/google-calendar-service-account.json > /dev/null && echo "✓ JSON válido" || echo "✗ JSON inválido"

# Verificar que tiene el campo client_email
grep -o '"client_email"[^,]*' /home/azureuser/mateos/secrets/google-calendar-service-account.json
```

### Paso 8: Configurar la Integración en Mateos

Una vez que las credenciales estén en el servidor, avisame y voy a:

1. Crear el script de sincronización con Google Calendar
2. Probar la conexión
3. Configurar la sincronización bidireccional:
   - Mateos → Google Calendar (crear eventos para bloques planificados)
   - Google Calendar → Mateos (leer bloques existentes)
4. Configurar cron job para sincronización automática

---

## Troubleshooting

### Error: "Invalid credentials"
- Verificar que compartiste el calendario con el email correcto del service account
- Verificar que el JSON está completo y no está corrupto

### Error: "Calendar not found"
- Verificar que el Calendar ID es correcto
- Verificar que el service account tiene permisos en ese calendario

### Error: "API not enabled"
- Verificar que habilitaste Google Calendar API en el proyecto de Google Cloud

---

## Próximos Pasos

Una vez configurado, podrás:

1. **Ver bloques de tiempo del calendario** en Mateos
2. **Crear bloques automáticamente** desde Mateos en Google Calendar
3. **Sincronizar tareas** con eventos del calendario
4. **Analizar uso de tiempo real** vs planificado
5. **Recibir notificaciones** cuando hay conflictos de horarios

---

**¿Necesitás ayuda con algún paso?** Avisame cuando llegues al Paso 7 y continúo con la implementación.
