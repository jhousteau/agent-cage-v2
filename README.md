# Agent Cage v2

A minimal Docker development environment with Claude Code and GCP tools.

## Quick Start

1. **Start Docker** (if not running):
   ```bash
   # On macOS, start Docker Desktop or:
   open -a Docker
   ```

2. **Build and run the container**:
   ```bash
   docker-compose up -d --build
   ```

3. **Access the container**:
   ```bash
   docker-compose exec dev-container bash
   ```

4. **Stop the container**:
   ```bash
   docker-compose down
   ```

## Features

- **Python 3.11** with Poetry package manager
- **Google Cloud SDK** (gcloud CLI)
- **Node.js** with modern development tools
- **Claude Code** CLI for AI assistance
- **SSH key support** (mount `.ssh/` directory in workspace)
- **Persistent home directory** via Docker volume
- **Development tools**: git, tree, jq, shellcheck, prettier

## Directory Structure

```
/app/           # Your workspace (mounted from current directory)
/home/agent/    # Persistent user home (Docker volume)
```

## SSH Keys

Place your SSH keys in the workspace `.ssh/` directory:
```
mkdir .ssh
cp ~/.ssh/id_* .ssh/
```

The container will automatically configure them on startup.

## Environment Variables

- `ENVIRONMENT`: Set to `dev`, `staging`, or `prod` (default: `dev`)
- `DEV_WORKSPACE`: Workspace path (default: `/app`)

## Ports

- `8000-8002`: Application ports
- `8888`: Jupyter/development servers

## What's Different from v1

This version removes all the infrastructure plumbing and focuses purely on the core development container. No Terraform, no complex scripts, no over-engineering - just a clean Docker environment ready for development.