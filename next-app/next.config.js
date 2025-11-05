/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  experimental: {
    serverComponentsExternalPackages: ['@prisma/client', 'prisma'],
  },
  logging: {
    fetches: {
      fullUrl: true,
    },
  },
  // Increase API route body size limit for audio files
  api: {
    bodyParser: {
      sizeLimit: '50mb',
    },
  },
}

module.exports = nextConfig
