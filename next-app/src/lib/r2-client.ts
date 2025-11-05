import { S3Client } from '@aws-sdk/client-s3';
import { Upload } from '@aws-sdk/lib-storage';
import { logger } from './logger';
import { R2UploadResult, UploadOptions } from '@/types';

// S3 Client lazy initialization
let s3Client: S3Client | null = null;

function getS3Client(): S3Client {
  if (s3Client) return s3Client;

  // Validar variables de entorno
  const requiredEnvVars = [
    'R2_ACCOUNT_ID',
    'R2_ACCESS_KEY',
    'R2_SECRET_KEY',
    'R2_BUCKET_NAME',
  ] as const;

  requiredEnvVars.forEach(envVar => {
    if (!process.env[envVar]) {
      throw new Error(`Missing required environment variable: ${envVar}`);
    }
  });

  const R2_ENDPOINT = `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;

  s3Client = new S3Client({
    region: 'auto',
    endpoint: R2_ENDPOINT,
    credentials: {
      accessKeyId: process.env.R2_ACCESS_KEY!,
      secretAccessKey: process.env.R2_SECRET_KEY!,
    },
  });

  return s3Client;
}

export async function uploadToR2(
  buffer: Buffer,
  options: UploadOptions
): Promise<R2UploadResult> {
  const { filename, contentType } = options;
  const year = new Date().getFullYear();
  const month = String(new Date().getMonth() + 1).padStart(2, '0');
  const key = `audios/${year}/${month}/${filename}`;

  try {
    logger.info('Uploading to R2', { key, size: buffer.length });

    const client = getS3Client();

    const upload = new Upload({
      client,
      params: {
        Bucket: process.env.R2_BUCKET_NAME!,
        Key: key,
        Body: buffer,
        ContentType: contentType,
      },
    });

    await upload.done();

    // URL pública (ajustar según configuración de R2)
    const R2_ENDPOINT = `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
    const publicUrl = `${R2_ENDPOINT}/${process.env.R2_BUCKET_NAME}/${key}`;

    logger.info('Upload to R2 completed', { key, url: publicUrl });

    return {
      url: publicUrl,
      key,
      bucket: process.env.R2_BUCKET_NAME!,
    };
  } catch (error) {
    logger.error('Error uploading to R2', {
      error: error instanceof Error ? error.message : 'Unknown error',
      key,
    });
    throw new Error(`R2 upload failed: ${error instanceof Error ? error.message : 'Unknown'}`);
  }
}
