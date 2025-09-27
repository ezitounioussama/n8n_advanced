# n8n Advanced Docker Setup

This is an advanced n8n Docker setup with task runners, PostgreSQL database, Redis caching, and queue-based execution.

## Features

- **Official n8n Docker image** with task runners enabled
- **MongoDB Atlas** cloud database for production-ready data persistence
- **Redis** for caching and queue management
- **Queue-based execution** with separate worker processes
- **Task runners** for JavaScript code execution
- **Health checks** for all services
- **Volume management** for persistent data
- **Scalable workers** configuration

## Quick Start

1. **Set up MongoDB Atlas:**

   - Create account at [MongoDB Atlas](https://cloud.mongodb.com)
   - Create a new cluster (free tier available)
   - Create database user with readWrite permissions
   - Configure network access (0.0.0.0/0 for development)
   - Get connection string from "Connect your application"

2. **Configure environment:**

   - Copy `.env` file is already created with instructions
   - Add your MongoDB Atlas connection string to `MONGODB_CONNECTION_URL`
   - Generate encryption keys for `N8N_ENCRYPTION_KEY` and `N8N_JWT_SECRET`
   - Adjust other settings as needed

3. **Generate encryption keys (Important for production):**

   ```bash
   # Generate encryption key
   openssl rand -base64 32

   # Generate JWT secret
   openssl rand -base64 32
   ```

4. **Start the services:**

   ```bash
   docker-compose up -d
   ```

5. **Access n8n:**
   Open your browser and go to `http://localhost:5678`

## MongoDB Atlas Setup Guide

### Step 1: Create MongoDB Atlas Account

1. Go to [MongoDB Atlas](https://cloud.mongodb.com)
2. Sign up for a free account
3. Verify your email address

### Step 2: Create a Cluster

1. Click "Build a Database"
2. Choose "M0 Sandbox" (Free tier)
3. Select your preferred cloud provider and region
4. Name your cluster (e.g., "n8n-cluster")
5. Click "Create Cluster"

### Step 3: Create Database User

1. Go to "Database Access" in the left sidebar
2. Click "Add New Database User"
3. Choose "Password" authentication
4. Set username (e.g., "n8n_user")
5. Generate a secure password (save it securely!)
6. Under "Database User Privileges":
   - Choose "Built-in Role"
   - Select "Read and write to any database"
7. Click "Add User"

### Step 4: Configure Network Access

1. Go to "Network Access" in the left sidebar
2. Click "Add IP Address"
3. For development: Click "Allow Access from Anywhere" (0.0.0.0/0)
4. For production: Add specific IP addresses
5. Click "Confirm"

### Step 5: Get Connection String

1. Go to "Database" in the left sidebar
2. Click "Connect" on your cluster
3. Choose "Connect your application"
4. Select "Node.js" as driver
5. Copy the connection string
6. Replace `<password>` with your database user password
7. Replace `myFirstDatabase` with `n8n`

### Step 6: Update Environment File

Add your connection string to the `.env` file:

```
MONGODB_CONNECTION_URL=mongodb+srv://n8n_user:your_password@n8n-cluster.abc12.mongodb.net/n8n?retryWrites=true&w=majority
```

## Environment Variables

### Required for Production

- `MONGODB_CONNECTION_URL`: MongoDB Atlas connection string
- `N8N_ENCRYPTION_KEY`: 32-character base64 key for data encryption
- `N8N_JWT_SECRET`: 32-character base64 key for JWT tokens

### Optional Configuration

- `N8N_HOST`: Hostname for n8n (default: localhost)
- `N8N_PORT`: Port for n8n (default: 5678)
- `N8N_PROTOCOL`: Protocol (http/https, default: http)
- `WEBHOOK_URL`: URL for webhooks (default: http://localhost:5678)
- `GENERIC_TIMEZONE`: Timezone (default: UTC)
- `N8N_WORKER_REPLICAS`: Number of worker instances (default: 2)

### Task Runner Configuration

- `N8N_RUNNERS_ENABLED`: Enable task runners (default: true)
- `N8N_RUNNERS_MAX_CONCURRENCY`: Max concurrent tasks (default: 5)
- `N8N_RUNNERS_TASK_TIMEOUT`: Task timeout in seconds (default: 60)

## Services

### n8n (Main Service)

- **Port:** 5678
- **Purpose:** Main n8n web interface and API
- **Dependencies:** PostgreSQL, Redis

### n8n-worker

- **Purpose:** Executes workflows in queue mode
- **Scaling:** Configured via `N8N_WORKER_REPLICAS`
- **Dependencies:** MongoDB Atlas, Redis

### MongoDB Atlas

- **Purpose:** Cloud-hosted primary database for n8n data
- **Managed:** Fully managed by MongoDB Atlas
- **Scaling:** Automatic scaling available

### redis

- **Port:** 6379 (internal)
- **Purpose:** Queue management and caching
- **Volume:** `redis_data`

## Volumes

- `n8n_data`: Main n8n application data
- `n8n_binary_data`: Binary files uploaded to workflows
- `redis_data`: Redis persistence files

Note: Database is hosted on MongoDB Atlas, so no local database volume needed.

## Directory Structure

```
├── docker-compose.yml     # Main compose file
├── Dockerfile.old         # Original custom build file (reference only)
├── Dockerfile.simple      # Simple customization example
├── docker-entrypoint.sh   # Container entry point (reference)
├── n8n-task-runners.json  # Task runner configuration (reference)
├── .env                   # Environment configuration
├── .env.example           # Environment template
├── custom-certificates/   # Custom SSL certificates
├── backups/               # Workflow/credential backups
├── logs/                  # Application logs
└── custom-nodes/          # Custom n8n nodes
```

**Note:** This setup now uses the official n8n Docker image (`docker.n8n.io/n8nio/n8n`) instead of building from source. The original `Dockerfile` expected pre-compiled n8n source code and has been moved to `Dockerfile.old` for reference.

## Management Commands

### Start services

```bash
docker-compose up -d
```

### Stop services

```bash
docker-compose down
```

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f n8n
docker-compose logs -f n8n-worker
```

### Scale workers

```bash
docker-compose up -d --scale n8n-worker=4
```

### Backup data

```bash
# Backup n8n data
docker run --rm -v n8n_advanced_n8n_data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/n8n_data_backup.tar.gz -C /data .

# MongoDB Atlas backups are handled automatically by Atlas
# You can configure automated backups in the Atlas dashboard
# Manual backups can be created from Atlas UI or using mongodump with connection string
```

### Restore data

```bash
# Restore n8n data
docker run --rm -v n8n_advanced_n8n_data:/data -v $(pwd)/backups:/backup alpine tar xzf /backup/n8n_data_backup.tar.gz -C /data

# MongoDB Atlas restores can be done from Atlas dashboard
# Point-in-time recovery available with Atlas clusters
```

## Security Considerations

1. **Change default passwords** in the `.env` file
2. **Generate secure encryption keys** using OpenSSL
3. **Use HTTPS** in production by setting `N8N_PROTOCOL=https`
4. **Limit network access** using Docker networks
5. **Regular backups** of database and n8n data
6. **Update base images** regularly for security patches

## Troubleshooting

### Check service health

```bash
docker-compose ps
```

### Check specific service logs

```bash
docker-compose logs n8n
docker-compose logs n8n-worker
docker-compose logs redis
```

### Pull latest images and restart

```bash
docker-compose pull
docker-compose up -d
```

### Reset everything (WARNING: Data loss)

```bash
docker-compose down -v
docker-compose up -d
```

### Common Issues

**Error: "COPY ./compiled /app/": not found**

- This happens when using the old Dockerfile that expects compiled source code
- Solution: The docker-compose.yml has been updated to use the official n8n image
- Make sure you're using the latest docker-compose.yml from this setup

**MongoDB Connection Issues**

- Verify your MongoDB Atlas connection string in the `.env` file
- Check that your IP address is whitelisted in MongoDB Atlas Network Access
- Ensure the database user has proper permissions (readWrite role)

## Production Deployment

For production deployment, consider:

1. **Use external databases** instead of containerized ones
2. **Set up SSL/TLS** with proper certificates
3. **Configure monitoring** and alerting
4. **Set up log aggregation**
5. **Use Docker Swarm or Kubernetes** for orchestration
6. **Regular security updates** and patches
7. **Network security** with firewalls and VPNs
