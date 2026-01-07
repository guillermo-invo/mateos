#!/usr/bin/env node
/**
 * Script de prueba para Google Calendar API
 * Verifica conexión y lee eventos de ambos calendarios
 */

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Configuración
const CREDENTIALS_PATH = path.join(__dirname, '..', '..', 'secrets', 'google-calendar-service-account.json');
const TRUNCHES_CALENDAR_ID = 'c_0c44e02391421207de4f23659eab7603fd098368b04ef8d6d3aaf9ea361d2660@group.calendar.google.com';
const PERSONAL_CALENDAR_ID = 'guillermo@involucrate.uy';

async function testCalendarConnection() {
  try {
    console.log('🔄 Verificando credenciales...');

    // Cargar credenciales
    if (!fs.existsSync(CREDENTIALS_PATH)) {
      throw new Error(`Archivo de credenciales no encontrado: ${CREDENTIALS_PATH}`);
    }

    const credentials = JSON.parse(fs.readFileSync(CREDENTIALS_PATH, 'utf8'));
    console.log(`✅ Credenciales cargadas: ${credentials.client_email}`);

    // Autenticar con Google
    const auth = new google.auth.GoogleAuth({
      credentials,
      scopes: ['https://www.googleapis.com/auth/calendar'],
    });

    const authClient = await auth.getClient();
    const calendar = google.calendar({ version: 'v3', auth: authClient });

    console.log('✅ Autenticación exitosa\n');

    // Fecha de inicio y fin para la búsqueda (próximos 7 días)
    const now = new Date();
    const nextWeek = new Date();
    nextWeek.setDate(now.getDate() + 7);

    // Probar calendario TRUNCHES
    console.log('📅 Probando calendario TRUNCHES (bloques de tiempo por área)...');
    console.log(`   ID: ${TRUNCHES_CALENDAR_ID}`);

    try {
      const trunchesResponse = await calendar.events.list({
        calendarId: TRUNCHES_CALENDAR_ID,
        timeMin: now.toISOString(),
        timeMax: nextWeek.toISOString(),
        maxResults: 10,
        singleEvents: true,
        orderBy: 'startTime',
      });

      const trunchesEvents = trunchesResponse.data.items || [];
      console.log(`✅ Conexión exitosa - ${trunchesEvents.length} eventos encontrados\n`);

      if (trunchesEvents.length > 0) {
        console.log('   Eventos en TRUNCHES:');
        trunchesEvents.forEach((event, index) => {
          const start = event.start.dateTime || event.start.date;
          const end = event.end.dateTime || event.end.date;
          console.log(`   ${index + 1}. ${event.summary || '(Sin título)'}`);
          console.log(`      📅 ${start} → ${end}`);
        });
        console.log('');
      } else {
        console.log('   ℹ️  No hay eventos en los próximos 7 días\n');
      }
    } catch (error) {
      console.error(`❌ Error al acceder a calendario TRUNCHES:`, error.message);
      if (error.code === 404) {
        console.error('   💡 El calendario no existe o no está compartido con el service account');
      } else if (error.code === 403) {
        console.error('   💡 Sin permisos. Verificar que compartiste el calendario con:', credentials.client_email);
      }
      console.log('');
    }

    // Probar calendario PERSONAL
    console.log('📅 Probando calendario PERSONAL (citas, reuniones, tareas)...');
    console.log(`   ID: ${PERSONAL_CALENDAR_ID}`);

    try {
      const personalResponse = await calendar.events.list({
        calendarId: PERSONAL_CALENDAR_ID,
        timeMin: now.toISOString(),
        timeMax: nextWeek.toISOString(),
        maxResults: 10,
        singleEvents: true,
        orderBy: 'startTime',
      });

      const personalEvents = personalResponse.data.items || [];
      console.log(`✅ Conexión exitosa - ${personalEvents.length} eventos encontrados\n`);

      if (personalEvents.length > 0) {
        console.log('   Eventos en PERSONAL:');
        personalEvents.forEach((event, index) => {
          const start = event.start.dateTime || event.start.date;
          const end = event.end.dateTime || event.end.date;
          console.log(`   ${index + 1}. ${event.summary || '(Sin título)'}`);
          console.log(`      📅 ${start} → ${end}`);
        });
        console.log('');
      } else {
        console.log('   ℹ️  No hay eventos en los próximos 7 días\n');
      }
    } catch (error) {
      console.error(`❌ Error al acceder a calendario PERSONAL:`, error.message);
      if (error.code === 404) {
        console.error('   💡 El calendario no existe o no está compartido con el service account');
      } else if (error.code === 403) {
        console.error('   💡 Sin permisos. Verificar que compartiste el calendario con:', credentials.client_email);
      }
      console.log('');
    }

    // Resumen
    console.log('═══════════════════════════════════════════════════');
    console.log('✅ Prueba completada');
    console.log('═══════════════════════════════════════════════════');

  } catch (error) {
    console.error('\n❌ Error general:', error.message);
    console.error(error);
    process.exit(1);
  }
}

// Ejecutar
testCalendarConnection();
