#!/usr/bin/env node
/**
 * Sincronización bidireccional con Google Calendar
 *
 * Funciones:
 * 1. Leer bloques de trunches (capacidad por área)
 * 2. Leer eventos del calendario personal (compromisos)
 * 3. Calcular disponibilidad real
 * 4. Sincronizar con BD de Mateos
 * 5. Crear eventos desde Mateos en Calendar
 */

const { google } = require('googleapis');
const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

// Configuración
const CREDENTIALS_PATH = path.join(__dirname, '..', '..', 'secrets', 'google-calendar-service-account.json');
const TRUNCHES_CALENDAR_ID = 'c_0c44e02391421207de4f23659eab7603fd098368b04ef8d6d3aaf9ea361d2660@group.calendar.google.com';
const PERSONAL_CALENDAR_ID = 'guillermo@involucrate.uy';

class CalendarSync {
  constructor() {
    this.calendar = null;
  }

  async init() {
    const credentials = JSON.parse(fs.readFileSync(CREDENTIALS_PATH, 'utf8'));
    const auth = new google.auth.GoogleAuth({
      credentials,
      scopes: ['https://www.googleapis.com/auth/calendar'],
    });
    const authClient = await auth.getClient();
    this.calendar = google.calendar({ version: 'v3', auth: authClient });
  }

  /**
   * Lee bloques de tiempo del calendario trunches
   * @param {Date} startDate - Fecha inicial
   * @param {Date} endDate - Fecha final
   */
  async getTrunchesBlocks(startDate, endDate) {
    try {
      const response = await this.calendar.events.list({
        calendarId: TRUNCHES_CALENDAR_ID,
        timeMin: startDate.toISOString(),
        timeMax: endDate.toISOString(),
        singleEvents: true,
        orderBy: 'startTime',
      });

      return response.data.items || [];
    } catch (error) {
      console.error('Error leyendo trunches:', error.message);
      throw error;
    }
  }

  /**
   * Lee eventos del calendario personal (citas, reuniones)
   * @param {Date} startDate - Fecha inicial
   * @param {Date} endDate - Fecha final
   */
  async getPersonalEvents(startDate, endDate) {
    try {
      const response = await this.calendar.events.list({
        calendarId: PERSONAL_CALENDAR_ID,
        timeMin: startDate.toISOString(),
        timeMax: endDate.toISOString(),
        singleEvents: true,
        orderBy: 'startTime',
      });

      return response.data.items || [];
    } catch (error) {
      console.error('Error leyendo calendario personal:', error.message);
      throw error;
    }
  }

  /**
   * Calcula tiempo disponible por día
   * Cruza bloques de trunches con eventos del calendario personal
   */
  async calculateAvailability(startDate, endDate) {
    const trunchesBlocks = await this.getTrunchesBlocks(startDate, endDate);
    const personalEvents = await this.getPersonalEvents(startDate, endDate);

    const availability = {};

    // Procesar bloques de trunches (capacidad disponible)
    trunchesBlocks.forEach(block => {
      const start = new Date(block.start.dateTime || block.start.date);
      const end = new Date(block.end.dateTime || block.end.date);
      const dateKey = start.toISOString().split('T')[0];

      if (!availability[dateKey]) {
        availability[dateKey] = {
          date: dateKey,
          trunchesBlocks: [],
          personalEvents: [],
          totalCapacityHours: 0,
          occupiedHours: 0,
        };
      }

      const durationHours = (end - start) / (1000 * 60 * 60);
      availability[dateKey].trunchesBlocks.push({
        summary: block.summary,
        start: start.toISOString(),
        end: end.toISOString(),
        durationHours,
      });
      availability[dateKey].totalCapacityHours += durationHours;
    });

    // Procesar eventos personales (tiempo ocupado)
    personalEvents.forEach(event => {
      const start = new Date(event.start.dateTime || event.start.date);
      const end = new Date(event.end.dateTime || event.end.date);
      const dateKey = start.toISOString().split('T')[0];

      if (!availability[dateKey]) {
        availability[dateKey] = {
          date: dateKey,
          trunchesBlocks: [],
          personalEvents: [],
          totalCapacityHours: 0,
          occupiedHours: 0,
        };
      }

      const durationHours = (end - start) / (1000 * 60 * 60);
      availability[dateKey].personalEvents.push({
        summary: event.summary,
        start: start.toISOString(),
        end: end.toISOString(),
        durationHours,
      });
      availability[dateKey].occupiedHours += durationHours;
    });

    // Calcular horas disponibles
    Object.keys(availability).forEach(dateKey => {
      const day = availability[dateKey];
      day.availableHours = day.totalCapacityHours - day.occupiedHours;
      day.utilizationPercent = day.totalCapacityHours > 0
        ? (day.occupiedHours / day.totalCapacityHours * 100).toFixed(1)
        : 0;
    });

    return availability;
  }

  /**
   * Crea un evento en el calendario personal
   * @param {Object} eventData - Datos del evento
   */
  async createPersonalEvent(eventData) {
    try {
      const event = {
        summary: eventData.summary,
        description: eventData.description || '',
        start: {
          dateTime: eventData.start,
          timeZone: 'America/Argentina/Buenos_Aires',
        },
        end: {
          dateTime: eventData.end,
          timeZone: 'America/Argentina/Buenos_Aires',
        },
        colorId: eventData.colorId || '7',
      };

      const response = await this.calendar.events.insert({
        calendarId: PERSONAL_CALENDAR_ID,
        requestBody: event,
      });

      console.log(`✅ Evento creado: ${eventData.summary}`);
      return response.data;
    } catch (error) {
      console.error('Error creando evento:', error.message);
      throw error;
    }
  }

  /**
   * Sincroniza bloques planificados de la BD con Google Calendar
   */
  async syncPlannedBlocksToCalendar() {
    try {
      // Obtener bloques pendientes de sincronizar
      const bloques = await prisma.$queryRaw`
        SELECT * FROM bloques_tiempo_planificados
        WHERE sincronizado_calendar = false
        AND fecha >= CURRENT_DATE
        ORDER BY fecha, hora_inicio
        LIMIT 50
      `;

      console.log(`📅 Sincronizando ${bloques.length} bloques con Calendar...`);

      for (const bloque of bloques) {
        const startDateTime = new Date(`${bloque.fecha}T${bloque.hora_inicio}`);
        const endDateTime = new Date(`${bloque.fecha}T${bloque.hora_fin}`);

        // Obtener nombre del área o proyecto
        let summary = bloque.descripcion_libre || 'Bloque de tiempo';
        if (bloque.area_vida_id) {
          const area = await prisma.areasVida.findUnique({
            where: { id: bloque.area_vida_id }
          });
          if (area) summary = `[${area.nombre}] ${summary}`;
        }

        const eventData = {
          summary,
          description: `Tipo: ${bloque.tipo_bloque}\nCreado desde Mateos`,
          start: startDateTime.toISOString(),
          end: endDateTime.toISOString(),
          colorId: this.getColorForBlockType(bloque.tipo_bloque),
        };

        const calendarEvent = await this.createPersonalEvent(eventData);

        // Actualizar BD con el ID del evento de Calendar
        await prisma.$executeRaw`
          UPDATE bloques_tiempo_planificados
          SET google_calendar_event_id = ${calendarEvent.id},
              sincronizado_calendar = true
          WHERE id = ${bloque.id}
        `;
      }

      console.log(`✅ ${bloques.length} bloques sincronizados`);
    } catch (error) {
      console.error('Error en sincronización:', error);
      throw error;
    }
  }

  /**
   * Obtiene color de Calendar según tipo de bloque
   */
  getColorForBlockType(tipo) {
    const colorMap = {
      'tarea_estrategica': '9', // Azul
      'tarea_recurrente': '2', // Verde
      'proyecto_foco': '11', // Rojo
      'buffer': '8', // Gris
      'reunion': '5', // Amarillo
      'compromiso': '4', // Naranja
      'otro': '7', // Celeste
    };
    return colorMap[tipo] || '7';
  }

  /**
   * Genera reporte de disponibilidad
   */
  async printAvailabilityReport(days = 7) {
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + days);

    console.log('\n📊 REPORTE DE DISPONIBILIDAD\n');
    console.log(`Período: ${startDate.toLocaleDateString()} - ${endDate.toLocaleDateString()}\n`);

    const availability = await this.calculateAvailability(startDate, endDate);

    Object.keys(availability).sort().forEach(dateKey => {
      const day = availability[dateKey];
      const date = new Date(dateKey);
      const dayName = date.toLocaleDateString('es-UY', { weekday: 'long' });

      console.log(`\n📅 ${dayName} ${dateKey}`);
      console.log(`   Capacidad total: ${day.totalCapacityHours.toFixed(1)}h`);
      console.log(`   Tiempo ocupado: ${day.occupiedHours.toFixed(1)}h`);
      console.log(`   ✅ Disponible: ${day.availableHours.toFixed(1)}h (${100 - day.utilizationPercent}%)`);

      if (day.trunchesBlocks.length > 0) {
        console.log(`   Bloques en trunches:`);
        day.trunchesBlocks.forEach(block => {
          const start = new Date(block.start);
          const end = new Date(block.end);
          console.log(`     • ${block.summary}: ${start.toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' })} - ${end.toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' })} (${block.durationHours.toFixed(1)}h)`);
        });
      }

      if (day.personalEvents.length > 0) {
        console.log(`   Eventos confirmados:`);
        day.personalEvents.forEach(event => {
          const start = new Date(event.start);
          const end = new Date(event.end);
          console.log(`     🔴 ${event.summary}: ${start.toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' })} - ${end.toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' })} (${event.durationHours.toFixed(1)}h)`);
        });
      }
    });

    console.log('\n');
  }
}

// CLI
async function main() {
  const command = process.argv[2] || 'report';

  const sync = new CalendarSync();
  await sync.init();

  switch (command) {
    case 'report':
      const days = parseInt(process.argv[3]) || 7;
      await sync.printAvailabilityReport(days);
      break;

    case 'sync':
      await sync.syncPlannedBlocksToCalendar();
      break;

    case 'availability':
      const startDate = new Date();
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + 7);
      const availability = await sync.calculateAvailability(startDate, endDate);
      console.log(JSON.stringify(availability, null, 2));
      break;

    default:
      console.log('Uso:');
      console.log('  node calendar-sync.js report [días]    - Muestra reporte de disponibilidad');
      console.log('  node calendar-sync.js sync              - Sincroniza bloques planificados a Calendar');
      console.log('  node calendar-sync.js availability      - JSON de disponibilidad');
  }

  await prisma.$disconnect();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = CalendarSync;
