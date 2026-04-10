#!/bin/bash

set -e

COMPANY_NAME="${COMPANY_NAME:-onlyoffice}"
PRODUCT_NAME="${PRODUCT_NAME:-documentserver}"
DS_ROOT="/app/${COMPANY_NAME}/${PRODUCT_NAME}"
DATA_DIR="/var/www/${COMPANY_NAME}/${PRODUCT_NAME}/Data"
LOG_DIR="/var/log/${COMPANY_NAME}"
LIB_DIR="/var/lib/${COMPANY_NAME}"
CERT_DIR="/etc/letsencrypt/live/${COMPANY_NAME}"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en

mkdir -p "${DATA_DIR}"
mkdir -p "${LOG_DIR}"
mkdir -p "${LIB_DIR}"
mkdir -p "${DATA_DIR}/cache"
mkdir -p "${DATA_DIR}/certs"
mkdir -p "${DATA_DIR}/logs"
mkdir -p "${DATA_DIR}/tmp"
mkdir -p "/var/run/${COMPANY_NAME}"
mkdir -p "/var/lock/${COMPANY_NAME}"

chown -R ${COMPANY_NAME}:${COMPANY_NAME} "${DATA_DIR}"
chown -R ${COMPANY_NAME}:${COMPANY_NAME} "${LOG_DIR}"
chown -R ${COMPANY_NAME}:${COMPANY_NAME} "${LIB_DIR}"

echo "Starting PostgreSQL..."
service postgresql start
sleep 2

echo "Initializing database..."
sudo -u postgres psql -c "CREATE USER ${COMPANY_NAME} WITH password '${COMPANY_NAME}';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE ${COMPANY_NAME} OWNER ${COMPANY_NAME};" 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER ${COMPANY_NAME} WITH SUPERUSER;" 2>/dev/null || true

SCHEMA_FILE="${DS_ROOT}/server/schema/postgresql/createdb.sql"
if [ -f "${SCHEMA_FILE}" ]; then
    echo "Loading schema..."
    PGPASSWORD=${COMPANY_NAME} psql -h localhost -p 5432 -U ${COMPANY_NAME} -d ${COMPANY_NAME} -f "${SCHEMA_FILE}" 2>/dev/null || true
fi

service postgresql stop

echo "Checking SSL certificate..."
if [ -f "${CERT_DIR}/fullchain.pem" ] && [ -f "${CERT_DIR}/privkey.pem" ]; then
    echo "SSL certificate found, enabling HTTPS..."
    ENABLE_SSL=true
else
    echo "No SSL certificate found, using HTTP only..."
    ENABLE_SSL=false
fi

if [ "${ENABLE_SSL}" = "true" ]; then
    cat > /etc/nginx/conf.d/ds-ssl.conf << 'EOF'
server {
    listen 0.0.0.0:443 ssl http2;
    server_name _;

    ssl_certificate /etc/letsencrypt/live/onlyoffice/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/onlyoffice/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    server_tokens off;

    root /app/onlyoffice/documentserver;

    gzip on;
    gzip_static on;
    gzip_types text/plain text/css application/json application/javascript text/xml font/opentype application/font-woff application/vnd.ms-fontobject image/svg+xml;
    gzip_proxied any;
    gzip_vary on;
    gzip_comp_level 5;

    client_max_body_size 32m;
    expires -1;

    location / {
        index index.html;
        try_files $uri $uri/ =404;
    }

    location /docx/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /xlsx/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /pptx/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /docxf/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /oform/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ConvertService/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /FileConverter/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    rm -f /etc/nginx/conf.d/ds.conf
else
    cat > /etc/nginx/conf.d/ds.conf << 'EOF'
server {
    listen 0.0.0.0:80;
    server_name _;

    server_tokens off;

    root /app/onlyoffice/documentserver;

    gzip on;
    gzip_static on;
    gzip_types text/plain text/css application/json application/javascript text/xml font/opentype application/font-woff application/vnd.ms-fontobject image/svg+xml;
    gzip_proxied any;
    gzip_vary on;
    gzip_comp_level 5;

    client_max_body_size 32m;
    expires -1;

    location / {
        index index.html;
        try_files $uri $uri/ =404;
    }

    location /docx/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /xlsx/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /pptx/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /docxf/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /oform/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ConvertService/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /FileConverter/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    rm -f /etc/nginx/conf.d/ds-ssl.conf
fi

echo "Starting supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
