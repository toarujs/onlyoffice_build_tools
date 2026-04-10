#!/bin/bash

set -e

COMPANY_NAME="${COMPANY_NAME:-onlyoffice}"
PRODUCT_NAME="${PRODUCT_NAME:-documentserver}"
DS_ROOT="/app/${COMPANY_NAME}/${PRODUCT_NAME}"
DATA_DIR="/var/www/${COMPANY_NAME}/${PRODUCT_NAME}/Data"
LOG_DIR="/var/log/${COMPANY_NAME}"
LIB_DIR="/var/lib/${COMPANY_NAME}"

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

if [ ! -f "${DATA_DIR}/settings.json" ]; then
    if [ -f "${DS_ROOT}/server/Common/config/database.json" ]; then
        cp "${DS_ROOT}/server/Common/config/database.json" "${DATA_DIR}/settings.json"
    fi
fi

echo "Starting PostgreSQL..."
service postgresql start
sleep 2

echo "Starting Redis..."
service redis-server start
sleep 1

echo "Starting RabbitMQ..."
service rabbitmq-server start
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

echo "Stopping services for supervisor..."
service postgresql stop || true
service redis-server stop || true
service rabbitmq-server stop || true

echo "Starting supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
