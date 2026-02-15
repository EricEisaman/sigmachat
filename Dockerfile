# Stage 1: Builder
FROM ghcr.io/cirruslabs/flutter:stable as builder

# Install system dependencies
# These layers will be cached unless the commands change
RUN sudo apt update && sudo apt install -y \
    curl \
    wget \
    jq \
    build-essential \
    && sudo rm -rf /var/lib/apt/lists/*

# Install Rust (Nightly)
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu

# Install yq
WORKDIR /tmp
RUN wget https://github.com/mikefarah/yq/releases/download/v4.40.5/yq_linux_amd64.tar.gz && \
    tar -xzvf ./yq_linux_amd64.tar.gz && \
    mv yq_linux_amd64 /usr/bin/yq && \
    rm yq_linux_amd64.tar.gz

WORKDIR /app

# Copy dependency definitions and scripts to cache them separate from source code
# If pubspec.yaml, scripts/, or web/ don't change, this step is cached!
COPY pubspec.yaml pubspec.lock ./
COPY scripts ./scripts
COPY web ./web

# Prepare web: installs heavy Rust dependencies and compiles native executor
RUN mkdir -p web/assets/vodozemac && ./scripts/prepare-web.sh

# Copy config if exists, otherwise use sample
COPY config.sample.json ./config.json

# Copy the rest of the source code
# This layer changes frequently (when you edit lib/ code)
COPY . .

# Build the web application
RUN flutter build web --dart-define=FLUTTER_WEB_CANVASKIT_URL=canvaskit/ --release --source-maps

# Stage 2: Production (Nginx)
FROM nginx:alpine

# Install gettext for envsubst
RUN apk add --no-cache gettext wget

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy build artifacts from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx configuration template
# Nginx 1.19+ automatically runs envsubst on files in /etc/nginx/templates/
# But we use our own entrypoint for more control if needed
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Copy custom entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port (Render sets PORT env var)
EXPOSE 80

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD sh -c 'PORT=${PORT:-80}; wget --no-verbose --tries=1 --spider http://localhost:$PORT/health 2>/dev/null || exit 1'

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
