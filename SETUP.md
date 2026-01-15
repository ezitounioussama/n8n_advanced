# n8n Setup Guide

## What Changed

This workspace has been refactored to use a **minimal, production-ready** n8n setup:

### ✅ What's New

1. **Minimal Docker Setup**
   - Uses official n8n Docker image (no custom Dockerfile needed)
   - SQLite database (no external database required)
   - Single container deployment

2. **Persistent Data Storage**
   - All workflows, credentials, and executions stored in Docker volume `n8n_data`
   - Data persists even when container is removed
   - Easy backup and restore

3. **Backup & Restore Scripts**
   - `scripts/backup.sh` - Create timestamped backups
   - `scripts/restore.sh` - Restore from backup
   - Automatic cleanup of old backups (keeps last 5)

4. **Simplified Configuration**
   - Single `.env` file for all settings
   - Environment variables for easy customization
   - Optional Redis and MongoDB support

5. **Health Checks**
   - Built-in health check for n8n container
   - Automatic restart on failure

### 🗑️ What Was Removed

- Custom Dockerfile (using official image)
- Redis service (optional, can be added back)
- MongoDB Atlas configuration (using SQLite by default)
- Task runners configuration (simplified setup)
- Complex scripts folder (replaced with simple backup/restore)

## Quick Start

### 1. Initial Setup

```bash
cd /home/kirito/Documents/n8n_advanced

# Create environment file
cp .env.example .env

# Edit .env to configure n8n
# IMPORTANT: Generate secure keys!
# openssl rand -base64 32
nano .env
```

### 2. Start n8n

```bash
# Using the quick start script
./start.sh

# Or manually
docker compose up -d
```

### 3. Access n8n

Open browser: `http://localhost:5678`

## Data Persistence

Your data is stored in a Docker volume named `n8n_data`. This includes:

- ✅ All workflows
- ✅ All credentials
- ✅ Execution history
- ✅ User settings
- ✅ Custom nodes (if installed)

### Volume Management

```bash
# View volume details
docker volume inspect n8n_advanced_n8n_data

# List all volumes
docker volume ls

# Remove volume (WARNING: deletes all data!)
docker volume rm n8n_advanced_n8n_data
```

## Backup Strategy

### Manual Backup

```bash
./scripts/backup.sh
```

Creates: `backups/n8n_backup_YYYYMMDD_HHMMSS.tar.gz`

### Automated Backups (Cron)

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /home/kirito/Documents/n8n_advanced && ./scripts/backup.sh >> /var/log/n8n-backup.log 2>&1
```

### Restore

```bash
./scripts/restore.sh ./backups/n8n_backup_YYYYMMDD_HHMMSS.tar.gz
```

## Scaling Options

### Option 1: Add Redis (Queue Mode)

For better performance and queue management:

```yaml
# Add to docker-compose.yml
redis:
  image: redis:7-alpine
  restart: always
  command: redis-server --appendonly yes
  volumes:
    - redis_data:/data
  networks:
    - n8n-network

# Update n8n service
environment:
  N8N_QUEUE_BULL_REDIS_HOST: redis
  N8N_QUEUE_BULL_REDIS_PORT: 6379
  EXECUTIONS_MODE: queue
```

### Option 2: Add MongoDB (External Database)

For larger deployments:

```yaml
# Add to docker-compose.yml
mongodb:
  image: mongo:7
  restart: always
  volumes:
    - mongodb_data:/data/db
  networks:
    - n8n-network

# Update n8n service
environment:
  DB_TYPE: mongodb
  DB_MONGODB_CONNECTION_URL: ${MONGODB_CONNECTION_URL}
```

## Security Checklist

- [ ] Generate `N8N_ENCRYPTION_KEY` with `openssl rand -base64 32`
- [ ] Generate `N8N_JWT_SECRET` with `openssl rand -base64 32`
- [ ] Enable basic authentication or user management
- [ ] Use HTTPS in production (reverse proxy)
- [ ] Restrict network access (firewall)
- [ ] Set up regular backups
- [ ] Keep n8n updated
- [ ] Monitor logs for issues

## Common Tasks

### Update n8n

```bash
docker compose pull
docker compose up -d
```

### View Logs

```bash
docker compose logs -f
```

### Restart n8n

```bash
docker compose restart
```

### Stop n8n

```bash
docker compose down
```

### Check Status

```bash
docker compose ps
```

## Troubleshooting

### n8n won't start

```bash
# Check logs
docker compose logs n8n

# Check if port is in use
netstat -tulpn | grep 5678

# Try with verbose logging
docker compose run --rm n8n n8n start --verbose
```

### Permission Issues

```bash
# Fix volume permissions
docker run --rm -v n8n_advanced_n8n_data:/data alpine:latest sh -c "chmod -R 755 /data"
```

### Out of Disk Space

```bash
# Clean up Docker
docker system prune -a

# Remove old backups
ls -t ./backups/n8n_backup_*.tar.gz | tail -n +6 | xargs rm -f
```

### Migration from Old Setup

If you had a previous n8n setup:

1. Stop old n8n: `docker compose -f old-compose.yml down`
2. Backup old data using old method
3. Start new n8n: `docker compose up -d`
4. Restore data: `./scripts/restore.sh <backup-file>`

## File Structure

```
n8n_advanced/
├── .env.example          # Environment template
├── .env                  # Your configuration (create from .env.example)
├── .gitignore            # Git ignore rules
├── README.md             # Main documentation
├── SETUP.md              # This file
├── docker-compose.yml    # Docker configuration
├── start.sh              # Quick start script
├── backups/              # Backup files (created automatically)
└── scripts/
    ├── backup.sh         # Backup script
    └── restore.sh        # Restore script
```

## Environment Variables Reference

### Required (Generate Securely)

- `N8N_ENCRYPTION_KEY`: Encryption key for sensitive data
- `N8N_JWT_SECRET`: JWT secret for authentication

### Server Configuration

- `N8N_HOST`: Hostname (default: localhost)
- `N8N_PORT`: Port (default: 5678)
- `N8N_PROTOCOL`: Protocol (http/https)
- `WEBHOOK_URL`: Webhook URL
- `GENERIC_TIMEZONE`: Timezone (default: UTC)

### Authentication

- `N8N_BASIC_AUTH_ACTIVE`: Enable basic auth (true/false)
- `N8N_BASIC_AUTH_USER`: Username
- `N8N_BASIC_AUTH_PASSWORD`: Password

### Performance

- `N8N_CONCURRENCY`: Max concurrent executions (default: 10)

### Optional (Redis)

- `N8N_QUEUE_BULL_REDIS_HOST`: Redis host
- `N8N_QUEUE_BULL_REDIS_PORT`: Redis port

### Optional (MongoDB)

- `MONGODB_CONNECTION_URL`: MongoDB connection string

## Support

- **Documentation**: https://docs.n8n.io/
- **Community**: https://community.n8n.io/
- **GitHub**: https://github.com/n8n-io/n8n

## Notes

- This setup uses **SQLite** by default (no external database needed)
- All data is stored in Docker volume `n8n_data`
- Backups are created as `.tar.gz` files in `backups/` directory
- The setup is production-ready but can be scaled with Redis/MongoDB
- Always generate secure keys for production use