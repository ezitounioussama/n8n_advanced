#!/bin/bash
# Backup n8n workflows and data
# This script backs up the n8n data volume to a tar.gz file

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/n8n_backup_${TIMESTAMP}.tar.gz"

echo "🚀 Starting n8n backup..."

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Check if n8n container is running
if ! docker compose ps n8n > /dev/null 2>&1; then
    echo "❌ Error: n8n container is not running. Please start it first with: docker compose up -d"
    exit 1
fi

echo "📦 Creating backup of n8n data volume..."

# Create a temporary directory for the backup
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: ${TEMP_DIR}"

# Copy data from the volume to the temporary directory
docker run --rm \
    -v n8n_advanced_n8n_data:/data \
    -v "${TEMP_DIR}:/backup" \
    alpine:latest \
    sh -c "cp -r /data/* /backup/ 2>/dev/null || echo 'No data to copy'"

# Check if there's any data to backup
if [ -z "$(ls -A "${TEMP_DIR}" 2>/dev/null)" ]; then
    echo "⚠️  Warning: No data found in n8n volume. This might be the first run."
    echo "   Make sure n8n has been started at least once."
fi

# Create tar.gz archive
echo "📦 Creating archive..."
tar -czf "${BACKUP_FILE}" -C "${TEMP_DIR}" . 2>/dev/null || tar -czf "${BACKUP_FILE}" -C "${TEMP_DIR}" *

# Clean up temporary directory
rm -rf "${TEMP_DIR}"

# Verify backup file was created
if [ -f "${BACKUP_FILE}" ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    echo "✅ Backup completed successfully!"
    echo "📁 Backup file: ${BACKUP_FILE}"
    echo "📊 Backup size: ${BACKUP_SIZE}"
    echo ""
    echo "💡 To restore this backup, run:"
    echo "   ./scripts/restore.sh ${BACKUP_FILE}"
else
    echo "❌ Error: Backup file was not created"
    exit 1
fi

# Keep only the last 5 backups
echo ""
echo "🧹 Cleaning up old backups (keeping last 5)..."
ls -t "${BACKUP_DIR}"/n8n_backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm -f

echo "✅ Backup process completed!"