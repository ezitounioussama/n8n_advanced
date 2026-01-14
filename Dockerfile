FROM node:24-bullseye-slim

USER root

# Install ffmpeg and a minimal init (dumb-init) for proper signal handling
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	 ffmpeg \
	 dumb-init \
	 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Install n8n globally. Allow overriding the version with build-arg N8N_VERSION
ARG N8N_VERSION=latest
RUN npm install -g n8n@${N8N_VERSION}

# Create a non-root user to match the official image behavior
RUN useradd --system --uid 1000 --create-home --home-dir /home/node node || true
WORKDIR /home/node

USER node

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["n8n"]