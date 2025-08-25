# Simple GCP Development Container
FROM python:3.11-slim

# Set shell for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install all system dependencies, security tools, and Google Cloud SDK in single layer
# This prevents Docker layer caching issues that can cause gcloud installation failures
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    openssh-client \
    build-essential \
    nodejs \
    npm \
    wget \
    gnupg \
    lsb-release \
    tree \
    jq \
    shellcheck \
    apt-transport-https \
    ca-certificates \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y google-cloud-cli \
    && gcloud version \
    && which gcloud \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js tools globally (consolidated into single layer)
RUN npm install -g \
    prettier@latest \
    yaml-lint@latest \
    markdownlint-cli@latest \
    @anthropic-ai/claude-code@latest

# Create non-root user first
RUN groupadd --gid 1000 agent && \
    useradd --uid 1000 --gid agent --shell /bin/bash --create-home agent

# Install Poetry as agent user and ensure directory permissions
USER agent
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    mkdir -p /home/agent/.local/bin
USER root

# Set working directory
WORKDIR /app
RUN chown agent:agent /app

# Copy and setup entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create Claude config directory with proper permissions
RUN mkdir -p /home/agent/.config/claude /home/agent/.local/state/claude && \
    chown -R agent:agent /home/agent

USER agent

# Default development environment
ENV ENVIRONMENT=dev \
    PYTHONPATH=/app \
    PATH="/home/agent/.local/bin:$PATH" \
    DEV_WORKSPACE=/app \
    POETRY_HOME="/home/agent/.local"

EXPOSE 8000 8001 8002 8888

# Health check to ensure container is running properly
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python3 -c "import sys; sys.exit(0)" || exit 1

# Set entrypoint for initialization
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command to keep container running
CMD ["bash", "-c", "echo 'GCP Development Environment Ready' && while true; do sleep 30; done"]