#!/bin/bash
# Database Backup Script for MATEOS V2
# Creates timestamped backups of asistente_db

set -e

BACKUP_DIR="/home/azureuser/mateos/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/asistente_db_backup_$TIMESTAMP.sql"
MAX_BACKUPS=7  # Keep last 7 backups

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "🔄 Starting database backup..."
echo "📁 Backup location: $BACKUP_FILE"

# Create backup
docker-compose -f /home/azureuser/mateos/docker-compose.yml exec -T postgres-db \
  pg_dump -U asistente asistente_db > "$BACKUP_FILE"

# Compress backup
gzip "$BACKUP_FILE"
BACKUP_FILE="$BACKUP_FILE.gz"

# Get file size
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "✅ Backup created successfully: $SIZE"

# Clean up old backups (keep only last MAX_BACKUPS)
echo "🧹 Cleaning up old backups (keeping last $MAX_BACKUPS)..."
cd "$BACKUP_DIR"
ls -t asistente_db_backup_*.sql.gz | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f

REMAINING=$(ls -1 asistente_db_backup_*.sql.gz 2>/dev/null | wc -l)
echo "📦 Total backups retained: $REMAINING"

echo "✅ Backup process completed!"
