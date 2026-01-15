#!/bin/bash
# Restore n8n workflows and data from backup
# This script restores the n8n data volume from a tar.gz backup file

set -e

if [ $# -eq 0 ]; then
    echo "❌ Error: No backup file specified"
    echo ""
    echo "Usage: $0 <backup_file.tar.gz>"
    echo ""
    echo "Example:"
    echo "  $0 ./backups/n8n_backup_20240115_120000.tar.gz"
    echo ""
    echo "Available backups:"
    ls -1 ./backups/n8n_backup_*.tar.gz 2>/dev/null || echo "  No backups found"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "❌ Error: Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

echo "🚀 Starting n8n restore from: ${BACKUP_FILE}"
echo ""

# Confirm restore
read -p "⚠️  This will overwrite existing n8n data. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Restore cancelled"
    exit 0
fi

# Check if n8n container is running
if docker compose ps n8n > /dev/null 2>&1; then
    echo "🛑 Stopping n8n container..."
    docker compose stop n8n
    STOPPED=true
else
    STOPPED=false
fi

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d)
echo "📦 Extracting backup to temporary directory: ${TEMP_DIR}"

# Extract backup
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# Check if extraction was successful
if [ ! -d "${TEMP_DIR}" ] || [ -z "$(ls -A "${TEMP_DIR}" 2>/dev/null)" ]; then
    echo "❌ Error: Failed to extract backup or backup is empty"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Stop any containers using the volume
echo "🧹 Cleaning up existing volume data..."
docker run --rm \
    -v n8n_advanced_n8n_data:/data \
    alpine:latest \
    sh -c "rm -rf /data/*" 2>/dev/null || true

# Restore data to volume
echo "🔄 Restoring data to volume..."
docker run --rm \
    -v n8n_advanced_n8n_data:/data \
    -v "${TEMP_DIR}:/backup" \
    alpine:latest \
    sh -c "cp -r /backup/* /data/"

# Clean up temporary directory
rm -rf "${TEMP_DIR}"

# Fix permissions if needed
echo "🔧 Fixing permissions..."
docker run --rm \
    -v n8n_advanced_n8n_data:/data \
    alpine:latest \
    sh -c "chmod -R 755 /data" 2>/dev/null || true

# Restart n8n if it was running
if [ "$STOPPED" = true ]; then
    echo "🔄 Restarting n8n container..."
    docker compose start n8n
    echo "⏳ Waiting for n8n to start..."
    sleep 10
fi

echo ""
echo "✅ Restore completed successfully!"
echo ""
echo "📊 Restored from: ${BACKUP_FILE}"
echo ""
echo "💡 To verify the restore, check the n8n logs:"
echo "   docker compose logs -f n8n"
echo ""
echo "💡 To access n8n:"
echo "   Open http://localhost:5678 in your browser"