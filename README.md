# n8n Minimal Docker Setup

A clean, minimal Docker setup for n8n workflow automation with persistent data storage.

## Features

- **Minimal setup**: Uses official n8n Docker image with SQLite (no external database required)
- **Persistent storage**: All workflows, credentials, and executions are saved in Docker volumes
- **Easy backup/restore**: Built-in scripts for backing up and restoring your data
- **Production-ready**: Includes health checks and proper container management
- **Lightweight**: No Redis or external database required by default

## Quick Start

### 1. Setup

```bash
# Clone or navigate to this directory
cd /home/kirito/Documents/n8n_advanced

# Copy environment file and configure
cp .env.example .env

# Edit .env to set your configuration
# IMPORTANT: Generate secure keys for production!
# Generate with: openssl rand -base64 32
nano .env
```

### 2. Start n8n

```bash
# Start n8n in detached mode
docker compose up -d

# View logs
docker compose logs -f
```

### 3. Access n8n

Open your browser and go to: `http://localhost:5678`

## Configuration

### Environment Variables

Edit the `.env` file to configure n8n:

- `N8N_HOST`: Hostname for n8n (default: localhost)
- `N8N_PORT`: Port for n8n (default: 5678)
- `N8N_PROTOCOL`: Protocol (http or https)
- `GENERIC_TIMEZONE`: Timezone (default: UTC)
- `N8N_ENCRYPTION_KEY`: Encryption key for sensitive data (generate with `openssl rand -base64 32`)
- `N8N_JWT_SECRET`: JWT secret for authentication (generate with `openssl rand -base64 32`)
- `N8N_BASIC_AUTH_ACTIVE`: Enable basic authentication (true/false)
- `N8N_BASIC_AUTH_USER`: Username for basic auth
- `N8N_BASIC_AUTH_PASSWORD`: Password for basic auth
- `N8N_CONCURRENCY`: Maximum concurrent executions (default: 10)

### Optional: Redis for Queue Mode

For scaling and queue-based execution, add Redis:

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

# Update n8n service environment
environment:
  # ... other settings
  N8N_QUEUE_BULL_REDIS_HOST: redis
  N8N_QUEUE_BULL_REDIS_PORT: 6379
  EXECUTIONS_MODE: queue
```

### Optional: MongoDB for External Database

For external database (instead of SQLite):

```yaml
# Add to docker-compose.yml
mongodb:
  image: mongo:7
  restart: always
  volumes:
    - mongodb_data:/data/db
  networks:
    - n8n-network

# Update n8n service environment
environment:
  # ... other settings
  DB_TYPE: mongodb
  DB_MONGODB_CONNECTION_URL: ${MONGODB_CONNECTION_URL}
```

## Data Persistence

All n8n data is stored in a Docker volume named `n8n_data`:

- Workflows
- Credentials
- Executions
- Settings
- Custom nodes (if installed)

### Volume Location

To find where Docker stores the volume data:

```bash
docker volume inspect n8n_advanced_n8n_data
```

## Backup and Restore

### Backup

Create a backup of all n8n data:

```bash
./scripts/backup.sh
```

This creates a `.tar.gz` file in the `backups/` directory with a timestamp.

### Restore

Restore from a backup:

```bash
./scripts/restore.sh ./backups/n8n_backup_YYYYMMDD_HHMMSS.tar.gz
```

**Note**: The restore script will stop n8n, overwrite existing data, and restart n8n.

### Automated Backups

For automated backups, add a cron job:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /home/kirito/Documents/n8n_advanced && ./scripts/backup.sh >> /var/log/n8n-backup.log 2>&1
```

## Management Commands

```bash
# Start n8n
docker compose up -d

# Stop n8n
docker compose down

# View logs
docker compose logs -f

# Restart n8n
docker compose restart

# Update to latest n8n version
docker compose pull
docker compose up -d

# Check container status
docker compose ps

# View n8n version
docker compose exec n8n n8n --version
```

## Security Best Practices

1. **Generate secure keys**: Always generate `N8N_ENCRYPTION_KEY` and `N8N_JWT_SECRET` using `openssl rand -base64 32`
2. **Use HTTPS**: Configure n8n to use HTTPS in production
3. **Enable authentication**: Use basic auth or user management
4. **Restrict access**: Use firewall rules to restrict access to n8n
5. **Regular backups**: Set up automated backups
6. **Keep updated**: Regularly update to the latest n8n version

## Troubleshooting

### n8n won't start

```bash
# Check logs
docker compose logs n8n

# Check if port is already in use
netstat -tulpn | grep 5678

# Try starting with more verbose logging
docker compose run --rm n8n n8n start --verbose
```

### Permission issues

If you encounter permission issues:

```bash
# Fix volume permissions
docker run --rm -v n8n_advanced_n8n_data:/data alpine:latest sh -c "chmod -R 755 /data"
```

### Out of disk space

```bash
# Clean up unused Docker resources
docker system prune -a

# Remove old backups (keep last 5)
ls -t ./backups/n8n_backup_*.tar.gz | tail -n +6 | xargs rm -f
```

## Migration from Previous Setup

If you're migrating from a previous n8n setup:

1. **Stop old n8n**: `docker compose -f old-docker-compose.yml down`
2. **Backup old data**: Use the old setup's backup method
3. **Start new n8n**: `docker compose up -d`
4. **Restore data**: `./scripts/restore.sh <backup-file>`

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community Forum](https://community.n8n.io/)
- [n8n GitHub](https://github.com/n8n-io/n8n)

## License

n8n is available under the Sustainable Use License. See the [n8n license](https://github.com/n8n-io/n8n/blob/master/LICENSE.md) for details.