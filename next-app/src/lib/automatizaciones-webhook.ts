import { logger } from './logger';

interface WebhookPayload {
  transcripcionId: number;
  texto: string;
  archivoUrl?: string;
  fecha: string;
}

/**
 * Llama al webhook de automatizaciones para procesar la transcripción con IA
 * @param payload - Datos de la transcripción
 * @returns true si se llamó exitosamente, false si falló (no lanza error)
 */
export async function notifyAutomatizaciones(payload: WebhookPayload): Promise<boolean> {
  const webhookUrl = process.env.WEBHOOK_AUTOMATIZACIONES_URL;

  // Si no está configurado, no hacer nada (modo desarrollo sin automatizaciones)
  if (!webhookUrl) {
    logger.warn('WEBHOOK_AUTOMATIZACIONES_URL no configurado, saltando notificación');
    return false;
  }

  try {
    logger.info('Notificando a automatizaciones', {
      transcripcionId: payload.transcripcionId,
      webhookUrl,
    });

    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(10000), // Timeout de 10 segundos
    });

    if (!response.ok) {
      const errorText = await response.text().catch(() => 'No response body');
      logger.error('Webhook de automatizaciones falló', {
        status: response.status,
        statusText: response.statusText,
        body: errorText,
      });
      return false;
    }

    const result = await response.json();
    logger.info('Webhook de automatizaciones exitoso', { result });
    return true;

  } catch (error) {
    // No propagamos el error, solo lo logueamos
    // El procesamiento de audio debe continuar aunque falle el webhook
    logger.error('Error llamando webhook de automatizaciones', {
      error: error instanceof Error ? error.message : 'Unknown error',
      transcripcionId: payload.transcripcionId,
    });
    return false;
  }
}
