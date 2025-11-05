export default function Home() {
  return (
    <main style={{ padding: '2rem', fontFamily: 'system-ui, sans-serif' }}>
      <h1>API de Transcripción</h1>
      <p>API para procesar notas de voz de Telegram y transcribirlas usando Whisper.</p>

      <h2>Endpoints disponibles:</h2>
      <ul>
        <li><code>GET /api/health</code> - Health check</li>
        <li><code>POST /api/process-audio</code> - Procesar audio</li>
      </ul>

      <h2>Estado del servicio:</h2>
      <p>
        <a href="/api/health" target="_blank" style={{ color: '#0070f3' }}>
          Ver estado del servicio
        </a>
      </p>
    </main>
  );
}
