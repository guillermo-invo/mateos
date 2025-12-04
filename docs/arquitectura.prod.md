# Documentación de Arquitectura y Funcionamiento

Este documento describe la arquitectura de los dos proyectos principales: `mateos` e `involucra-hub`.

## 1. Proyecto: `mateos`

### 1.1. Descripción General

`mateos` es un sistema simplificado para transcribir notas de voz de Telegram y almacenarlas en una base de datos PostgreSQL. A diferencia de `asistente-personal`, este proyecto está completamente contenedorizado con Docker, lo que facilita su gestión.

### 1.2. Componentes (Servicios Docker)

Todos los componentes de `mateos` se gestionan con un único archivo `docker-compose.yml`.

-   **`postgres-db`**:
    -   **Imagen**: `postgres:15.5-alpine`
    -   **Función**: Base de datos para almacenar las transcripciones.
    -   **Persistencia**: Los datos se guardan en un volumen de Docker llamado `postgres-data`, por lo que **no se pierden** si se detiene el contenedor.

-   **`next-app`**:
    -   **Función**: Actúa como la API principal del sistema. Procesa las solicitudes del bot, se comunica con la API de OpenAI (Whisper) para realizar las transcripciones y guarda los resultados en la base de datos.
    -   **Framework**: Construido con Next.js.

-   **`telegram-bot`**:
    -   **Función**: Es el bot de Telegram que escucha los mensajes de voz. Cuando recibe un audio, lo envía al servicio `next-app` para su procesamiento.
    -   **Nota**: A diferencia de proyectos anteriores, el bot aquí **sí está dockerizado**, lo que simplifica su ejecución.

### 1.3. Flujo de Inicio y Reinicio

**Pregunta:** Si el sistema se detiene, ¿qué tengo que hacer para volver a iniciarlo?

**Respuesta:** El proceso es muy sencillo gracias a Docker Compose.

1.  **Navega al directorio del proyecto:**
    ```bash
    cd /home/azureuser/mateos
    ```
2.  **Inicia todos los servicios:**
    ```bash
    docker-compose up -d --build
    ```
    -   El comando `docker-compose up -d` inicia todos los servicios (base de datos, API y bot) en segundo plano.
    -   La opción `--build` asegura que se reconstruyan las imágenes de Docker si ha habido algún cambio en el código fuente (por ejemplo, en `next-app` o `telegram-bot`).

**En resumen: para iniciar o reiniciar, solo necesitas ejecutar `docker-compose up -d` en la carpeta del proyecto.** No es necesario instalar dependencias (`npm install`) manualmente, ya que eso se gestiona dentro de la construcción de las imágenes de Docker.

---

## 2. Proyecto: `involucra-hub`

### 2.1. Descripción General

`involucra-hub` es una arquitectura de microservicios modular y escalable. Se basa en **cinco componentes Docker Compose independientes** que se comunican a través de una red Docker compartida, permitiendo una gran flexibilidad y separación de responsabilidades.

### 2.2. La Red Compartida: `involucra-network`

El componente clave de esta arquitectura es la red `involucra-network`. Todos los servicios de los cinco componentes están conectados a esta red, lo que les permite comunicarse entre sí utilizando sus nombres de contenedor como si fueran nombres de host (DNS).

Esta red es de tipo `external: true` en la mayoría de los archivos, lo que significa que se crea una vez (en el `docker-compose.yml` de `databases`) y los demás componentes se "acoplan" a ella.

### 2.3. Componentes (Microservicios)

#### a) `databases`

-   **Ubicación**: `/home/azureuser/involucra-hub/databases/docker-compose.yml`
-   **Función**: Centraliza todos los motores de persistencia de datos.
-   **Servicios**: `postgres`, `mysql`, `redis`.
-   **Clave**: Este es el componente que **crea** la red `involucra-network`.

#### b) `involucrate-backend`

-   **Ubicación**: `/home/azureuser/involucra-hub/involucrate-backend/docker-compose.yml`
-   **Función**: Es la API principal de la aplicación web "Involúcrate".
-   **Conexiones**: Se conecta al servicio `n8n-postgres-prod` del componente `databases`.

#### c) `involucrate-frontend`

-   **Ubicación**: `/home/azureuser/involucra-hub/involucrate-frontend/docker-compose.yml`
-   **Función**: Es la interfaz de usuario de la aplicación web "Involúcrate".
-   **Conexiones**: Se comunica con el `involucrate-backend-prod`.

#### d) `applications`

-   **Ubicación**: `/home/azureuser/involucra-hub/applications/docker-compose.yml`
-   **Función**: Contiene aplicaciones y herramientas de soporte (`n8n`, `nocodb`, `chatwoot`, bots de WhatsApp, scripts de Python).
-   **Conexiones**: Estos servicios se conectan a las bases de datos y entre sí a través de la `involucra-network`.

#### e) `nginx`

-   **Ubicación**: `/home/azureuser/involucra-hub/nginx/docker-compose.yml`
-   **Función**: Actúa como un **proxy inverso**. Es el único punto de entrada para el tráfico externo (HTTP/HTTPS), redirigiendo las peticiones al servicio interno correspondiente.

### 2.4. Flujo de Inicio

Para iniciar todo el ecosistema de `involucra-hub`, debes iniciar cada componente en el orden correcto de dependencias:

1.  **Bases de Datos (Primero):**
    ```bash
    cd /home/azureuser/involucra-hub/databases
    docker-compose up -d
    ```
2.  **Backend y Aplicaciones:**
    ```bash
    cd /home/azureuser/involucra-hub/involucrate-backend && docker-compose up -d
    cd /home/azureuser/involucra-hub/applications && docker-compose up -d
    ```
3.  **Frontend:**
    ```bash
    cd /home/azureuser/involucra-hub/involucrate-frontend && docker-compose up -d
    ```
4.  **Nginx (Al final):**
    ```bash
    cd /home/azureuser/involucra-hub/nginx && docker-compose up -d
    ```

---

## 3. Conexión entre Proyectos

**Pregunta:** ¿Puedo acceder a la base de datos de `mateos` desde un servicio en `involucra-hub` (como `python_runner`)?

**Respuesta:** **Sí, y ya está configurado para ello.**

El archivo `docker-compose.yml` del proyecto `mateos` ya incluye una configuración para conectar sus servicios a la red `involucra-network`:

```yaml
networks:
  app-network:
    driver: bridge
  involucra-network:
    external: true
```

Y los servicios `postgres-db` y `next-app` están conectados a ella:

```yaml
services:
  postgres-db:
    # ...
    networks:
      - app-network
      - involucra-network
  next-app:
    # ...
    networks:
      - app-network
      - involucra-network
```

### ¿Cómo conectarse?

Gracias a esta configuración, cualquier servicio dentro de `involucra-hub` puede acceder a la base de datos de `mateos` usando su nombre de contenedor: `transcripcion-postgres`.

**Ejemplo:** La cadena de conexión desde `python_runner` (en `involucra-hub`) a la base de datos de `mateos` sería:

`postgresql://asistente:n8npass@transcripcion-postgres:5432/transcripciones_db`

Esto te permite, como querías, "chupar" datos de la base de datos de `mateos` y usarlos en tus automatizaciones de `involucra-hub` de forma directa y eficiente.