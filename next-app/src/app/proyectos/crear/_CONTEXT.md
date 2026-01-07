# _CONTEXT.md - Página Crear Proyecto

## PROPÓSITO

Página de formulario para crear proyectos estratégicos con asistencia de IA. Permite al usuario ingresar nombre, descripción, seleccionar áreas de vida y motivos personales, opcionalmente convertir ideas existentes en proyectos.

---

## STACK TÉCNICO ESPECÍFICO

- **Framework:** Next.js 15 (Client Component - `'use client'`)
- **Estado:** React hooks (useState, useEffect)
- **Routing:** next/navigation (useRouter, useSearchParams)
- **Validación:** Formulario HTML5 + validación client-side

---

## ARQUITECTURA Y FLUJO

### Flujo de Creación

```
Usuario completa formulario
  → Validación client-side
  → POST /api/proyectos-estrategicos/generar
  → Next.js API reenvía a automatizaciones
  → Automatizaciones genera con IA (10-30s)
  → Retorna project ID
  → Muestra mensaje de éxito (SIN redirección)
  → Resetea formulario
  → Recarga lista de ideas disponibles
```

### Estructura del Formulario

**Campos:**
1. **Seleccionar Idea** (opcional):
   - Dropdown con ideas disponibles (no implementadas)
   - Al seleccionar: auto-rellena nombre y descripción
   - Deshabilita edición de nombre/descripción

2. **Nombre del Proyecto** (required):
   - Input text
   - Min length: 1
   - Deshabilitado si se seleccionó idea

3. **Descripción del Proyecto** (required):
   - Textarea (5 rows)
   - Min length: 1
   - Deshabilitado si se seleccionó idea

4. **Área de Vida** (opcional):
   - Radio buttons (single select)
   - Lista cargada desde `/api/areas-vida`
   - Input text para crear nueva área (alternativa)

5. **Motivos Personales** (opcional):
   - Checkboxes (multiple select)
   - Lista cargada desde `/api/motivos-personales`
   - Input text para crear nuevo motivo (adicional)

---

## REGLAS Y RESTRICCIONES

### Validación

#### ✅ SIEMPRE:
- Validar que descripción no esté vacía (required)
- Validar que nombre no esté vacío (required)
- Deshabilitar botón submit mientras loading=true
- Mostrar indicador visual durante generación ("Generando proyecto con IA...")

#### ❌ NUNCA:
- Redirigir automáticamente después de crear proyecto
- Permitir crear proyecto sin descripción
- Hacer submit del formulario si loading=true

### Estado del Formulario

**Estados posibles:**
- `loading: false` - Normal, usuario puede interactuar
- `loading: true` - Generando proyecto, botón submit deshabilitado
- `error: string | null` - Error mostrado en banner rojo
- `success: { id, nombre } | null` - Éxito mostrado en banner verde

### Mensajes de Usuario

#### ✅ Mensaje de Éxito:
```
¡Proyecto "[nombre]" creado exitosamente (ID: [id])!
El backend ha generado todas las tareas, subtareas y relaciones estratégicas.
```

#### ❌ Mensaje de Error:
```
[Mensaje de error del servidor]
```

---

## INTEGRACIÓN CON IA

### Datos Enviados al Backend

```typescript
const body = {
  nombre: nombre || 'Proyecto sin nombre',
  descripcion: descripcion, // REQUERIDO
  areasIds: selectedArea ? [selectedArea] : undefined,
  motivosIds: selectedMotivos.length > 0 ? selectedMotivos : undefined,
  nuevaAreaVida: nuevaAreaVida.trim() || undefined,
  nuevoMotivoPersonal: nuevoMotivoPersonal.trim() || undefined,
  ideaId: selectedIdeaId || undefined,
}
```

### Timeout y Loading

**Tiempo esperado:** 10-30 segundos (generación con IA)

**Indicador de loading:**
- Botón: "Generando proyecto con IA..." (deshabilitado)
- Estado: `loading = true`
- No hay barra de progreso (no se puede estimar)

---

## NOTAS PARA IA

### ⚠️ NO Redirigir Después de Crear

**Problema histórico:** Se redirigía automáticamente a `/proyectos/[id]` causando error 404 o carga incorrecta.

**Solución actual:**
- Mostrar mensaje de éxito en la misma página
- NO usar `router.push()` después de success
- NO usar `<a href>` en mensaje de éxito (causa navegación completa)
- Usuario puede crear otro proyecto inmediatamente

### ⚠️ Ideas Disponibles

**Carga inicial:**
```typescript
const ideasRes = await fetch('/api/ideas/disponibles')
const ideasData = await ideasRes.json()
setProjectIdeas(ideasData.data || [])
```

**Recarga después de crear:**
```typescript
// Refresh available ideas list
const ideasRes = await fetch('/api/ideas/disponibles')
const ideasData = await ideasRes.json()
setProjectIdeas(ideasData.data || [])
```

**Razón:** Después de crear proyecto desde una idea, esa idea ya no debe aparecer como disponible.

### ⚠️ Query Params

**Support para `?ideaId=[id]`:**
- Al cargar página con query param `ideaId`, auto-seleccionar esa idea
- Útil para links desde página de ideas: "Convertir en Proyecto"

```typescript
const ideaIdParam = searchParams.get('ideaId')
if (ideaIdParam) {
  const ideaId = parseInt(ideaIdParam)
  if (!isNaN(ideaId)) {
    setSelectedIdeaId(ideaId)
  }
}
```

### ⚠️ Suspense Wrapper

**Razón:** `useSearchParams()` requiere Suspense boundary.

```tsx
<Suspense fallback={<div className="p-6">Cargando...</div>}>
  <CrearProyectoContent />
</Suspense>
```

---

## ARCHIVOS CLAVE

- `page.tsx`: Componente principal (345 líneas)
- `/api/proyectos-estrategicos/generar/route.ts`: Endpoint de generación

---

**Última actualización:** 2026-01-07
**Cambios:** Eliminada redirección automática, agregado mensaje de éxito sin link
**Versión:** 1.1
