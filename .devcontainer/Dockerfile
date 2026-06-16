# Or use a Dockerfile or Docker Compose file. More info: https://containers.dev/guide/dockerfile
FROM mcr.microsoft.com/devcontainers/base:resolute

RUN apt-get update && apt-get install -y \
    acpica-tools \
    && rm -rf /var/lib/apt/lists/*

