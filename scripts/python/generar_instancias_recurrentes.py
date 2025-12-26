#!/usr/bin/env python3
"""
Script para generar instancias de tareas recurrentes
Sistema Mateos - Gestión de Tiempo y Tareas
Autor: Sistema Mateos
Fecha: 2025-12-24

Este script:
1. Lee todas las tareas_recurrentes activas
2. Genera instancias_tareas_recurrentes para el rango de fechas especificado
3. Respeta el patrón de recurrencia de cada tarea
4. Evita duplicados
"""

import os
import sys
import logging
from datetime import datetime, timedelta, date, time
from typing import List, Dict, Any, Optional
import json

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
except ImportError:
    print("Error: psycopg2 no está instalado")
    print("Instalar con: pip install psycopg2-binary")
    sys.exit(1)

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('/home/azureuser/mateos/logs/generar_instancias.log')
    ]
)
logger = logging.getLogger(__name__)


class GeneradorInstancias:
    """Generador de instancias de tareas recurrentes"""

    def __init__(self, database_url: Optional[str] = None):
        """
        Inicializa el generador

        Args:
            database_url: URL de conexión a PostgreSQL (formato: postgresql://user:pass@host:port/db)
                         Si no se proporciona, se lee de la variable de entorno DATABASE_URL
        """
        self.database_url = database_url or os.getenv('DATABASE_URL')
        if not self.database_url:
            raise ValueError("Se requiere DATABASE_URL en variable de entorno o como parámetro")

        self.conn = None
        self.cursor = None

    def conectar(self):
        """Establece conexión con la base de datos"""
        try:
            self.conn = psycopg2.connect(self.database_url)
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            logger.info("Conexión establecida con la base de datos")
        except Exception as e:
            logger.error(f"Error al conectar a la base de datos: {e}")
            raise

    def desconectar(self):
        """Cierra la conexión con la base de datos"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        logger.info("Conexión cerrada")

    def obtener_tareas_recurrentes_activas(self) -> List[Dict[str, Any]]:
        """
        Obtiene todas las tareas recurrentes activas

        Returns:
            Lista de diccionarios con los datos de las tareas
        """
        query = """
            SELECT
                id,
                nombre,
                patron_recurrencia,
                duracion_estimada_minutos
            FROM tareas_recurrentes
            WHERE activa = true
            ORDER BY id
        """
        self.cursor.execute(query)
        tareas = self.cursor.fetchall()
        logger.info(f"Se encontraron {len(tareas)} tareas recurrentes activas")
        return tareas

    def calcular_fechas_segun_patron(
        self,
        patron: Dict[str, Any],
        fecha_desde: date,
        fecha_hasta: date
    ) -> List[date]:
        """
        Calcula las fechas en las que debe generarse una instancia según el patrón

        Args:
            patron: Diccionario con el patrón de recurrencia
            fecha_desde: Fecha de inicio del rango
            fecha_hasta: Fecha de fin del rango

        Returns:
            Lista de fechas calculadas
        """
        tipo = patron.get('tipo')
        intervalo = patron.get('intervalo', 1)
        fecha_inicio_patron = datetime.strptime(patron.get('fechaInicio'), '%Y-%m-%d').date()
        fecha_fin_patron = None
        if patron.get('fechaFin'):
            fecha_fin_patron = datetime.strptime(patron.get('fechaFin'), '%Y-%m-%d').date()

        # Ajustar fecha_desde para no generar antes del inicio del patrón
        fecha_desde = max(fecha_desde, fecha_inicio_patron)

        # Ajustar fecha_hasta si hay fecha de fin en el patrón
        if fecha_fin_patron:
            fecha_hasta = min(fecha_hasta, fecha_fin_patron)

        fechas = []

        if tipo == 'diaria':
            fechas = self._calcular_diaria(fecha_desde, fecha_hasta, intervalo)

        elif tipo == 'semanal':
            dias_semana = patron.get('diasSemana', [])
            fechas = self._calcular_semanal(fecha_desde, fecha_hasta, dias_semana, intervalo)

        elif tipo == 'mensual':
            dia_mes = patron.get('diaMes', 1)
            fechas = self._calcular_mensual(fecha_desde, fecha_hasta, dia_mes, intervalo)

        elif tipo == 'personalizada':
            logger.warning(f"Patrón personalizado no implementado aún: {patron}")
            fechas = []

        else:
            logger.error(f"Tipo de patrón desconocido: {tipo}")
            fechas = []

        return fechas

    def _calcular_diaria(self, fecha_desde: date, fecha_hasta: date, intervalo: int) -> List[date]:
        """Calcula fechas para recurrencia diaria"""
        fechas = []
        fecha_actual = fecha_desde

        while fecha_actual <= fecha_hasta:
            fechas.append(fecha_actual)
            fecha_actual += timedelta(days=intervalo)

        return fechas

    def _calcular_semanal(
        self,
        fecha_desde: date,
        fecha_hasta: date,
        dias_semana: List[int],
        intervalo: int
    ) -> List[date]:
        """
        Calcula fechas para recurrencia semanal

        Args:
            dias_semana: Lista de días (1=lun, 2=mar, ..., 7=dom)
        """
        if not dias_semana:
            return []

        fechas = []
        fecha_actual = fecha_desde

        # Encontrar el lunes de la semana de fecha_desde
        dias_hasta_lunes = fecha_actual.weekday()  # 0=lun, 6=dom
        lunes_semana = fecha_actual - timedelta(days=dias_hasta_lunes)

        while lunes_semana <= fecha_hasta:
            # Generar para cada día de la semana especificado
            for dia_semana in dias_semana:
                # Convertir de formato 1-7 (lun-dom) a 0-6 (lun-dom)
                offset_dia = dia_semana - 1
                fecha_generada = lunes_semana + timedelta(days=offset_dia)

                # Solo agregar si está en el rango
                if fecha_desde <= fecha_generada <= fecha_hasta:
                    fechas.append(fecha_generada)

            # Siguiente semana según intervalo
            lunes_semana += timedelta(weeks=intervalo)

        return sorted(fechas)

    def _calcular_mensual(
        self,
        fecha_desde: date,
        fecha_hasta: date,
        dia_mes: int,
        intervalo: int
    ) -> List[date]:
        """Calcula fechas para recurrencia mensual"""
        fechas = []

        # Empezar desde el mes de fecha_desde
        anio_actual = fecha_desde.year
        mes_actual = fecha_desde.month

        while True:
            try:
                # Intentar crear la fecha con el día especificado
                fecha_generada = date(anio_actual, mes_actual, dia_mes)

                if fecha_generada > fecha_hasta:
                    break

                if fecha_generada >= fecha_desde:
                    fechas.append(fecha_generada)

            except ValueError:
                # El día no existe en este mes (ej: 31 de febrero)
                logger.debug(f"Día {dia_mes} no existe en {mes_actual}/{anio_actual}")

            # Avanzar al siguiente mes según intervalo
            mes_actual += intervalo
            while mes_actual > 12:
                mes_actual -= 12
                anio_actual += 1

            # Verificar que no nos pasemos del año límite
            if anio_actual > fecha_hasta.year + 1:
                break

        return fechas

    def existe_instancia(self, tarea_id: int, fecha: date) -> bool:
        """
        Verifica si ya existe una instancia para una tarea en una fecha

        Args:
            tarea_id: ID de la tarea recurrente
            fecha: Fecha a verificar

        Returns:
            True si existe, False si no
        """
        query = """
            SELECT EXISTS(
                SELECT 1
                FROM instancias_tareas_recurrentes
                WHERE tarea_recurrente_id = %s
                AND fecha_programada = %s
            )
        """
        self.cursor.execute(query, (tarea_id, fecha))
        return self.cursor.fetchone()['exists']

    def crear_instancia(
        self,
        tarea_id: int,
        fecha: date,
        patron: Dict[str, Any]
    ) -> bool:
        """
        Crea una instancia de tarea recurrente

        Args:
            tarea_id: ID de la tarea recurrente
            fecha: Fecha programada
            patron: Patrón de recurrencia (para obtener hora preferida)

        Returns:
            True si se creó exitosamente, False si hubo error
        """
        try:
            hora_inicio = None
            hora_fin = None

            # Obtener hora preferida del patrón si existe
            if 'horaPreferida' in patron and patron['horaPreferida']:
                hora_inicio_str = patron['horaPreferida']
                hora_inicio = datetime.strptime(hora_inicio_str, '%H:%M').time()

            query = """
                INSERT INTO instancias_tareas_recurrentes
                    (tarea_recurrente_id, fecha_programada, hora_inicio, hora_fin)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (tarea_recurrente_id, fecha_programada) DO NOTHING
            """
            self.cursor.execute(query, (tarea_id, fecha, hora_inicio, hora_fin))
            return True

        except Exception as e:
            logger.error(f"Error al crear instancia para tarea {tarea_id} en {fecha}: {e}")
            return False

    def generar_instancias(
        self,
        fecha_desde: date,
        fecha_hasta: date,
        commit: bool = True
    ) -> Dict[str, int]:
        """
        Genera instancias de todas las tareas recurrentes activas

        Args:
            fecha_desde: Fecha de inicio del rango
            fecha_hasta: Fecha de fin del rango
            commit: Si se debe hacer commit de los cambios

        Returns:
            Diccionario con estadísticas de la generación
        """
        stats = {
            'tareas_procesadas': 0,
            'instancias_creadas': 0,
            'instancias_existentes': 0,
            'errores': 0
        }

        logger.info(f"Generando instancias desde {fecha_desde} hasta {fecha_hasta}")

        tareas = self.obtener_tareas_recurrentes_activas()

        for tarea in tareas:
            tarea_id = tarea['id']
            nombre = tarea['nombre']
            patron = tarea['patron_recurrencia']

            logger.info(f"Procesando tarea: {nombre} (ID: {tarea_id})")

            try:
                # Calcular fechas según patrón
                fechas = self.calcular_fechas_segun_patron(patron, fecha_desde, fecha_hasta)
                logger.info(f"  Se calcularon {len(fechas)} fechas")

                for fecha in fechas:
                    # Verificar si ya existe
                    if self.existe_instancia(tarea_id, fecha):
                        stats['instancias_existentes'] += 1
                        logger.debug(f"  Instancia ya existe para {fecha}")
                        continue

                    # Crear instancia
                    if self.crear_instancia(tarea_id, fecha, patron):
                        stats['instancias_creadas'] += 1
                        logger.debug(f"  Instancia creada para {fecha}")
                    else:
                        stats['errores'] += 1

                stats['tareas_procesadas'] += 1

            except Exception as e:
                logger.error(f"Error procesando tarea {nombre}: {e}")
                stats['errores'] += 1

        # Commit de cambios
        if commit:
            self.conn.commit()
            logger.info("Cambios guardados en la base de datos")

        # Log de estadísticas
        logger.info("=" * 50)
        logger.info("RESUMEN DE GENERACIÓN")
        logger.info("=" * 50)
        logger.info(f"Tareas procesadas: {stats['tareas_procesadas']}")
        logger.info(f"Instancias creadas: {stats['instancias_creadas']}")
        logger.info(f"Instancias ya existentes: {stats['instancias_existentes']}")
        logger.info(f"Errores: {stats['errores']}")
        logger.info("=" * 50)

        return stats


def main():
    """Función principal"""
    import argparse

    parser = argparse.ArgumentParser(
        description='Genera instancias de tareas recurrentes'
    )
    parser.add_argument(
        '--desde',
        type=str,
        help='Fecha desde (formato: YYYY-MM-DD). Default: hoy',
        default=None
    )
    parser.add_argument(
        '--hasta',
        type=str,
        help='Fecha hasta (formato: YYYY-MM-DD). Default: 2 semanas desde hoy',
        default=None
    )
    parser.add_argument(
        '--semanas',
        type=int,
        help='Número de semanas adelante desde hoy (alternativa a --hasta)',
        default=2
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='No guardar cambios (modo prueba)'
    )

    args = parser.parse_args()

    # Calcular fechas
    fecha_desde = date.today()
    if args.desde:
        fecha_desde = datetime.strptime(args.desde, '%Y-%m-%d').date()

    if args.hasta:
        fecha_hasta = datetime.strptime(args.hasta, '%Y-%m-%d').date()
    else:
        fecha_hasta = fecha_desde + timedelta(weeks=args.semanas)

    # Ejecutar generador
    generador = GeneradorInstancias()

    try:
        generador.conectar()
        stats = generador.generar_instancias(
            fecha_desde,
            fecha_hasta,
            commit=not args.dry_run
        )

        if args.dry_run:
            logger.info("Modo DRY-RUN: No se guardaron cambios")

        # Código de salida según resultados
        if stats['errores'] > 0:
            sys.exit(1)
        else:
            sys.exit(0)

    except Exception as e:
        logger.error(f"Error fatal: {e}")
        sys.exit(1)

    finally:
        generador.desconectar()


if __name__ == '__main__':
    main()
