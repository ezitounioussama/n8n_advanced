#!/usr/bin/env bash
set -e

# Try docker-compose first
if command -v docker-compose >/dev/null 2>&1 || docker compose version >/dev/null 2>&1; then
  echo "Attempting docker compose command (if you use compose)..."
  if docker compose ps -q n8n >/dev/null 2>&1; then
    echo "Running chown via docker compose..."
    docker compose exec --user root n8n chown -R node:node /home/node || true
  fi
fi

# Fallback: find a running container with 'n8n' in the name
CONTAINER=$(docker ps --filter "name=n8n" --format "{{.Names}}" | head -n1)
if [ -z "$CONTAINER" ]; then
  echo "No container with name containing 'n8n' found. Listing running containers:"
  docker ps
  exit 1
fi

echo "Using container: $CONTAINER"

echo "Running chown -R node:node /home/node as root inside the container..."
docker exec --user root "$CONTAINER" chown -R node:node /home/node || true

echo "Done. Verifying permissions and ffmpeg (if present):"
docker exec --user root "$CONTAINER" ls -ld /home/node || true

docker exec --user root "$CONTAINER" ffmpeg -version || echo "ffmpeg not found or command failed"

echo "If you still have permission issues you can alternatively run:
  docker exec --user root $CONTAINER chmod -R 777 /home/node"
