#!/bin/sh
set -e

# Render.com provides PORT environment variable
# Nginx default configuration uses port 80
# We need to replace the port in the nginx configuration if PORT is set

export PORT="${PORT:-80}"

echo "Starting nginx on port $PORT..."

# envsubst will replace $PORT in the template with the actual environment variable
# and output to /etc/nginx/conf.d/default.conf
envsubst '$PORT' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

# Execute the CMD from the Dockerfile
exec "$@"
