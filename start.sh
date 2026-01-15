#!/bin/bash
# Quick start script for n8n

set -e

echo "🚀 Starting n8n Docker Setup..."

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "✅ Created .env file"
    echo ""
    echo "⚠️  IMPORTANT: Please edit .env file to configure n8n before starting!"
    echo "   - Generate secure encryption keys"
    echo "   - Set up authentication if needed"
    echo "   - Configure timezone and other settings"
    echo ""
    echo "   Then run this script again."
    exit 0
fi

# Check if encryption key is set
if grep -q "N8N_ENCRYPTION_KEY=$" .env || grep -q "N8N_ENCRYPTION_KEY=\$" .env; then
    echo "⚠️  WARNING: N8N_ENCRYPTION_KEY is not set in .env"
    echo "   Generate one with: openssl rand -base64 32"
    echo "   And add it to your .env file"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Please set up .env file first"
        exit 1
    fi
fi

# Check if JWT secret is set
if grep -q "N8N_JWT_SECRET=$" .env || grep -q "N8N_JWT_SECRET=\$" .env; then
    echo "⚠️  WARNING: N8N_JWT_SECRET is not set in .env"
    echo "   Generate one with: openssl rand -base64 32"
    echo "   And add it to your .env file"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Please set up .env file first"
        exit 1
    fi
fi

echo "📦 Pulling latest n8n image..."
docker compose pull

echo "🔄 Starting n8n container..."
docker compose up -d

echo "⏳ Waiting for n8n to start..."
sleep 10

# Check if n8n is running
if docker compose ps n8n | grep -q "Up"; then
    echo "✅ n8n is running!"
    echo ""
    echo "📊 Access n8n at: http://localhost:5678"
    echo ""
    echo "💡 Useful commands:"
    echo "   ./start.sh          - Start n8n"
    echo "   ./scripts/backup.sh - Backup your data"
    echo "   docker compose logs -f - View logs"
    echo "   docker compose down - Stop n8n"
    echo ""
    echo "📖 For more information, see README.md"
else
    echo "❌ Failed to start n8n. Check logs with: docker compose logs n8n"
    exit 1
fi