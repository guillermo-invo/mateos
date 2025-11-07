# Configuración de NocoDB para conectar a la base de datos de Mateos

## 📋 Parámetros de Conexión

Para conectar NocoDB a la base de datos `asistente_db` del proyecto Mateos a través de la red `involucra-network`, utiliza los siguientes parámetros:

### **Host Address:**
```
postgres-db
```

### **Port Number:**
```
5432
```

### **Username:**
```
asistente
```

### **Password:**
```
n8npass
```

### **Database Name:**
```
asistente_db
```

### **SSL:**
```
No
```

## 🔗 URL de Conexión Completa

```
postgresql://asistente:n8npass@postgres-db:5432/asistente_db
```

## ⚠️ Requisitos Importantes

1. **Red Docker**: Asegúrate que el contenedor de NocoDB esté conectado a la red `involucra-network` (red externa).

2. **Visibilidad**: Los contenedores pueden comunicarse usando sus nombres de servicio cuando están en la misma red Docker.

3. **Base de Datos**: Verifica que la base de datos `asistente_db` exista en el contenedor PostgreSQL.

4. **Permisos**: Confirma que el usuario `asistente` tenga los permisos necesarios sobre la base de datos `asistente_db`.

## 🐳 Configuración del Contenedor NocoDB

Si estás ejecutando NocoDB en un contenedor Docker, asegúrate de incluirlo en la red `involucra-network`:

```yaml
services:
  nocodb:
    image: nocodb/nocodb:latest
    container_name: nocodb
    networks:
      - involucra-network
    # ... otras configuraciones
```

## 📝 Notas

- No se requiere SSL para la conexión entre contenedores en la misma red Docker.
- La comunicación es interna y segura dentro de la red Docker.
- Si NocoDB se ejecuta fuera de Docker, necesitarías usar `localhost:1432` como host y puerto.