#!/bin/bash

# Get DNS hostname from IT
REGISTRY_HOST=""

# Generate CA, cert, and key

# Generate htpasswd
docker run --entrypoint htpasswd registry:2 -Bbn edbsupport password > auth/htpasswd

# Start registry
docker run -d   -p 5000:5000   --restart=always   --name registry   -v /mnt/docker/auth:/auth   -e "REGISTRY_AUTH=htpasswd"   -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm"   -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd   -v /mnt/docker/certs:/certs   -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt   -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 registry:2

# Set --insecure-registry on all clients

# Start frontend
docker run -d -e ENV_DOCKER_REGISTRY_HOST=${REGISTRY_HOST} -e ENV_DOCKER_REGISTRY_PORT=5000 -e ENV_DOCKER_REGISTRY_USE_SSL=1 -p80:80 konradkleine/docker-registry-frontend:v2
