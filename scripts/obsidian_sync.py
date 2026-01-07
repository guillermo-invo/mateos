#!/usr/bin/env python3
"""
Script de sincronización Obsidian -> PostgreSQL
Parsea el archivo PLAN_ESTRATEGICO_Q1_2026.md y sincroniza con la base de datos.
"""

import re
import psycopg2
from datetime import datetime
from typing import List, Dict, Optional, Tuple
import sys

# Configuración de la base de datos
DB_CONFIG = {
    'host': 'localhost',
    'port': 8833,
    'database': 'asistente_db_dev',
    'user': 'asistente',
    'password': 'n8npass'
}

# Ruta al archivo markdown
OBSIDIAN_FILE = '/home/azureuser/obsidian/ObsidianGfork/Areas/Trabajo/Involucra/PLAN_ESTRATEGICO_Q1_2026.md'


class ProyectoParser:
    """Parser para extraer proyectos, tareas y subtareas del markdown."""

    def __init__(self, filepath: str):
        self.filepath = filepath
        self.content = self._read_file()

    def _read_file(self) -> str:
        """Lee el archivo markdown."""
        with open(self.filepath, 'r', encoding='utf-8') as f:
            return f.read()

    def parse_proyectos(self) -> List[Dict]:
        """
        Extrae todos los proyectos del documento.
        Busca patrones como: ## 📘 PROYECTO 1: MOTOR BÁSICO INVOLUCRATE
        """
        proyectos = []

        # Pattern para proyectos CORE
        proyecto_pattern = r'## ([📘📗📙📕]) PROYECTO (\d+|[A-Z]\d+|O\d+): (.+?)\n\n\*\*ID:\*\* `(.+?)`\n\*\*Objetivo:\*\* (.+?)\n'

        matches = re.finditer(proyecto_pattern, self.content, re.MULTILINE)

        for match in matches:
            emoji, numero, nombre, codigo, objetivo = match.groups()

            # Extraer información adicional
            start_pos = match.end()
            next_proyecto = self.content.find('\n## ', start_pos)
            if next_proyecto == -1:
                next_proyecto = len(self.content)

            proyecto_content = self.content[match.start():next_proyecto]

            # Extraer prioridad
            prioridad_match = re.search(r'\*\*Prioridad:\*\* ([🔴🟡🟢]) (.+)', proyecto_content)
            prioridad = prioridad_match.group(2) if prioridad_match else 'MEDIA'

            # Mapear prioridad a tipo de estado
            estado_map = {
                'CRÍTICA': 'activo',
                'BLOQUEANTE': 'activo',
                'ALTA': 'activo',
                'MEDIA': 'idea',
                'BAJA': 'idea'
            }
            estado = estado_map.get(prioridad, 'idea')

            proyectos.append({
                'nombre': nombre.strip(),
                'codigo': codigo.strip(),
                'descripcion': f"{emoji} {nombre}",
                'objetivo': objetivo.strip(),
                'prioridad': prioridad,
                'estado': estado,
                'content': proyecto_content,
                'start_pos': match.start(),
                'end_pos': next_proyecto
            })

        return proyectos

    def parse_tareas(self, proyecto: Dict) -> List[Dict]:
        """Extrae tareas de un proyecto."""
        tareas = []
        proyecto_content = proyecto['content']

        # Pattern para tareas: ### T1.1: ENGRANAJE 1 - OFERTA
        tarea_pattern = r'### (T[\d\.]+): (.+?)\n'

        matches = list(re.finditer(tarea_pattern, proyecto_content, re.MULTILINE))

        for i, match in enumerate(matches):
            codigo, nombre = match.groups()

            # Encontrar el contenido de la tarea
            start_pos = match.end()
            if i + 1 < len(matches):
                end_pos = matches[i + 1].start()
            else:
                # Buscar el siguiente proyecto o fin del documento
                end_pos = len(proyecto_content)

            tarea_content = proyecto_content[start_pos:end_pos]

            # Extraer objetivo si existe
            objetivo_match = re.search(r'\*\*Objetivo:\*\* (.+)', tarea_content)
            objetivo = objetivo_match.group(1) if objetivo_match else ''

            tareas.append({
                'codigo': codigo.strip(),
                'nombre': nombre.strip(),
                'descripcion': objetivo,
                'orden': i + 1,
                'content': tarea_content,
                'proyecto_codigo': proyecto['codigo']
            })

        return tareas

    def parse_subtareas(self, tarea: Dict) -> List[Dict]:
        """Extrae subtareas de una tarea."""
        subtareas = []
        tarea_content = tarea['content']

        # Pattern para subtareas: #### ST1.1.1: Auditoría y limpieza
        subtarea_pattern = r'#### (ST[\d\.]+): (.+?)\n((?:- \[[ x]\] .+\n)+)'

        matches = re.finditer(subtarea_pattern, tarea_content, re.MULTILINE)

        for match in matches:
            codigo, titulo, items_text = match.groups()

            # Parsear los checkboxes
            items = re.findall(r'- \[([ x])\] (.+)', items_text)

            # Extraer esfuerzo
            esfuerzo_match = re.search(r'\*\*Esfuerzo:\*\* (\d+(?:\.\d+)?)h', items_text)
            tiempo_estimado_minutos = None
            if esfuerzo_match:
                horas = float(esfuerzo_match.group(1))
                tiempo_estimado_minutos = int(horas * 60)

            # La subtarea está completada si TODOS los checkboxes están marcados
            todos_completados = all(item[0] == 'x' for item in items) if items else False

            subtareas.append({
                'codigo': codigo.strip(),
                'titulo': titulo.strip(),
                'completada': todos_completados,
                'tiempo_estimado_minutos': tiempo_estimado_minutos,
                'tarea_codigo': tarea['codigo'],
                'items': items
            })

        return subtareas


class DatabaseSync:
    """Sincroniza los datos parseados con PostgreSQL."""

    def __init__(self, db_config: Dict):
        self.db_config = db_config
        self.conn = None
        self.cur = None

    def connect(self):
        """Conecta a la base de datos."""
        try:
            self.conn = psycopg2.connect(**self.db_config)
            self.cur = self.conn.cursor()
            print("✓ Conectado a PostgreSQL")
        except Exception as e:
            print(f"✗ Error conectando a PostgreSQL: {e}")
            sys.exit(1)

    def close(self):
        """Cierra la conexión."""
        if self.cur:
            self.cur.close()
        if self.conn:
            self.conn.close()
        print("✓ Conexión cerrada")

    def sync_proyecto(self, proyecto: Dict) -> int:
        """Inserta o actualiza un proyecto y retorna su ID."""
        try:
            # Verificar si existe
            self.cur.execute(
                "SELECT id FROM proyectos_estrategicos WHERE nombre = %s",
                (proyecto['nombre'],)
            )
            existing = self.cur.fetchone()

            if existing:
                # Actualizar
                proyecto_id = existing[0]
                self.cur.execute("""
                    UPDATE proyectos_estrategicos
                    SET descripcion = %s,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = %s
                """, (proyecto['descripcion'], proyecto_id))
                print(f"  ↻ Actualizado proyecto: {proyecto['nombre']}")
            else:
                # Insertar
                self.cur.execute("""
                    INSERT INTO proyectos_estrategicos
                    (nombre, descripcion, estado, created_at, updated_at)
                    VALUES (%s, %s, %s::\"TipoEstadoProyecto\", CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    RETURNING id
                """, (proyecto['nombre'], proyecto['descripcion'], proyecto['estado']))
                proyecto_id = self.cur.fetchone()[0]
                print(f"  + Creado proyecto: {proyecto['nombre']}")

            self.conn.commit()
            return proyecto_id

        except Exception as e:
            self.conn.rollback()
            print(f"  ✗ Error en proyecto '{proyecto['nombre']}': {e}")
            raise

    def sync_tarea(self, tarea: Dict, proyecto_id: int) -> int:
        """Inserta o actualiza una tarea y retorna su ID."""
        try:
            # Verificar si existe
            self.cur.execute(
                "SELECT id FROM tareas_estrategicas WHERE nombre = %s AND proyecto_id = %s",
                (tarea['nombre'], proyecto_id)
            )
            existing = self.cur.fetchone()

            if existing:
                # Actualizar
                tarea_id = existing[0]
                self.cur.execute("""
                    UPDATE tareas_estrategicas
                    SET descripcion = %s,
                        orden = %s,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = %s
                """, (tarea['descripcion'], tarea['orden'], tarea_id))
                print(f"    ↻ Actualizada tarea: {tarea['nombre']}")
            else:
                # Insertar
                self.cur.execute("""
                    INSERT INTO tareas_estrategicas
                    (proyecto_id, nombre, descripcion, orden, estado, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, 'por_hacer'::\"TipoEstadoTarea\", CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    RETURNING id
                """, (proyecto_id, tarea['nombre'], tarea['descripcion'], tarea['orden']))
                tarea_id = self.cur.fetchone()[0]
                print(f"    + Creada tarea: {tarea['nombre']}")

            self.conn.commit()
            return tarea_id

        except Exception as e:
            self.conn.rollback()
            print(f"    ✗ Error en tarea '{tarea['nombre']}': {e}")
            raise

    def sync_subtarea(self, subtarea: Dict, tarea_id: int):
        """Inserta o actualiza una subtarea."""
        try:
            # Verificar si existe
            self.cur.execute(
                "SELECT id, completada FROM subtareas WHERE titulo = %s AND tarea_estrategica_id = %s",
                (subtarea['titulo'], tarea_id)
            )
            existing = self.cur.fetchone()

            if existing:
                # Actualizar solo si el estado de completada cambió
                subtarea_id, completada_actual = existing
                if completada_actual != subtarea['completada']:
                    self.cur.execute("""
                        UPDATE subtareas
                        SET completada = %s,
                            tiempo_estimado_minutos = %s,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE id = %s
                    """, (subtarea['completada'], subtarea['tiempo_estimado_minutos'], subtarea_id))
                    estado = "✓" if subtarea['completada'] else "○"
                    print(f"      {estado} Actualizada subtarea: {subtarea['titulo']}")
            else:
                # Insertar
                self.cur.execute("""
                    INSERT INTO subtareas
                    (tarea_estrategica_id, titulo, completada, tiempo_estimado_minutos, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    RETURNING id
                """, (tarea_id, subtarea['titulo'], subtarea['completada'], subtarea['tiempo_estimado_minutos']))
                estado = "✓" if subtarea['completada'] else "○"
                print(f"      {estado} Creada subtarea: {subtarea['titulo']}")

            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"      ✗ Error en subtarea '{subtarea['titulo']}': {e}")
            raise


def main():
    """Función principal."""
    print("=" * 80)
    print("SINCRONIZACIÓN OBSIDIAN → POSTGRESQL")
    print("=" * 80)
    print()

    # Parsear el archivo
    print("📄 Parseando archivo markdown...")
    parser = ProyectoParser(OBSIDIAN_FILE)
    proyectos = parser.parse_proyectos()
    print(f"✓ Encontrados {len(proyectos)} proyectos")
    print()

    # Conectar a la base de datos
    db = DatabaseSync(DB_CONFIG)
    db.connect()
    print()

    # Sincronizar cada proyecto
    total_tareas = 0
    total_subtareas = 0

    for proyecto in proyectos:
        print(f"📦 Proyecto: {proyecto['nombre']}")
        proyecto_id = db.sync_proyecto(proyecto)

        # Sincronizar tareas del proyecto
        tareas = parser.parse_tareas(proyecto)
        total_tareas += len(tareas)

        for tarea in tareas:
            tarea_id = db.sync_tarea(tarea, proyecto_id)

            # Sincronizar subtareas de la tarea
            subtareas = parser.parse_subtareas(tarea)
            total_subtareas += len(subtareas)

            for subtarea in subtareas:
                db.sync_subtarea(subtarea, tarea_id)

        print()

    # Cerrar conexión
    db.close()

    # Resumen
    print("=" * 80)
    print("RESUMEN DE SINCRONIZACIÓN")
    print("=" * 80)
    print(f"✓ Proyectos sincronizados: {len(proyectos)}")
    print(f"✓ Tareas sincronizadas: {total_tareas}")
    print(f"✓ Subtareas sincronizadas: {total_subtareas}")
    print()
    print("🎉 Sincronización completada exitosamente!")


if __name__ == '__main__':
    main()
