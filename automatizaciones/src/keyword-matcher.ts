import { distance } from 'fastest-levenshtein';
import { TipoMensaje, DetectionResult } from './types';

// ============================================
// Configuración de Keywords
// ============================================

interface KeywordConfig {
  word: string;
  tipo: TipoMensaje;
}

const KEYWORDS: KeywordConfig[] = [
  { word: 'teo', tipo: 'tarea' },
  { word: 'juan', tipo: 'registro' },
  { word: 'ide', tipo: 'idea' },
  { word: 'compa', tipo: 'compromiso' },
  { word: 'proy', tipo: 'proyecto' },
];

// Umbral de similitud (60% = 0.6)
const THRESHOLD = parseFloat(process.env.CONFIDENCE_THRESHOLD || '0.6');

// ============================================
// Funciones de Fuzzy Matching
// ============================================

/**
 * Calcula similitud entre dos strings usando Levenshtein distance
 * @returns Número entre 0-1, donde 1 = idénticos, 0 = completamente diferentes
 */
function calculateSimilarity(str1: string, str2: string): number {
  const maxLength = Math.max(str1.length, str2.length);
  if (maxLength === 0) return 1.0;

  const dist = distance(str1.toLowerCase(), str2.toLowerCase());
  return 1 - dist / maxLength;
}

/**
 * Detecta el tipo de mensaje según la primera palabra de la transcripción
 * Usa fuzzy matching para tolerar errores de transcripción
 */
export function detectTipoFromTranscription(transcripcion: string): DetectionResult {
  // Extraer primera palabra
  const palabras = transcripcion.trim().split(/\s+/);

  if (palabras.length === 0) {
    console.log('⚠️ Transcripción vacía');
    return {
      tipo: 'sin_clasificar',
      textoLimpio: transcripcion,
      confianza: 0,
    };
  }

  const primeraPalabra = palabras[0].toLowerCase();

  // Comparar con cada keyword
  let bestMatch: { keyword: string; tipo: TipoMensaje; similarity: number } | null = null;

  for (const kw of KEYWORDS) {
    const similarity = calculateSimilarity(primeraPalabra, kw.word);

    if (similarity >= THRESHOLD) {
      if (!bestMatch || similarity > bestMatch.similarity) {
        bestMatch = {
          keyword: kw.word,
          tipo: kw.tipo,
          similarity,
        };
      }
    }
  }

  // Si encontró match, remover primera palabra
  if (bestMatch) {
    const textoLimpio = palabras.slice(1).join(' ').trim();

    console.log(
      `✅ Keyword detectada: "${primeraPalabra}" → "${bestMatch.keyword}" (${Math.round(
        bestMatch.similarity * 100
      )}% similar) → tipo: ${bestMatch.tipo}`
    );

    return {
      tipo: bestMatch.tipo,
      textoLimpio: textoLimpio || transcripcion, // Fallback si no hay más texto
      confianza: bestMatch.similarity,
      keywordDetectada: bestMatch.keyword,
    };
  }

  // No match
  console.log(`⚠️ Keyword no detectada en: "${primeraPalabra}"`);
  return {
    tipo: 'sin_clasificar',
    textoLimpio: transcripcion,
    confianza: 0,
  };
}

/**
 * Función de prueba para ver cómo coinciden diferentes palabras
 */
export function testKeywordMatching(testWord: string): void {
  console.log(`\n🧪 Testing: "${testWord}"`);
  for (const kw of KEYWORDS) {
    const similarity = calculateSimilarity(testWord.toLowerCase(), kw.word);
    const match = similarity >= THRESHOLD ? '✅' : '❌';
    console.log(`  ${match} ${kw.word}: ${Math.round(similarity * 100)}%`);
  }
}
