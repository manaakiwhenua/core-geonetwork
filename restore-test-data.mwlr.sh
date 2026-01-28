#!/bin/bash
set -euo pipefail

# =============================================================================
# restore-test-data.mwlr.sh
# Restore test data into local Docker Compose development environment
# =============================================================================

# --- CONFIG ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TGZ="$SCRIPT_DIR/test-data.tgz"
BACKUP_DIR="/tmp/metaspace-backup"

# Container names (from docker-compose.yml)
GEONETWORK_CONTAINER="core-geonetwork-geonetwork-1"
DATABASE_CONTAINER="postgres-mwlr"

# Database config (from docker-compose.yml)
DB_NAME="gn"
DB_USER="postgres"

# GeoNetwork data path (from docker-compose.yml volume mount)
GN_DATA_PATH="/var/lib/geonetwork/data"

# --- Check prerequisites ---
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed or not in PATH"
    exit 1
fi

if [ ! -f "$BACKUP_TGZ" ]; then
    echo "Error: Backup file not found: $BACKUP_TGZ"
    exit 1
fi

# --- Check containers are running ---
echo "Checking containers are running..."
if ! docker ps --format '{{.Names}}' | grep -q "^${DATABASE_CONTAINER}$"; then
    echo "Error: Database container '$DATABASE_CONTAINER' is not running"
    echo "Run 'docker compose up -d' first"
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${GEONETWORK_CONTAINER}$"; then
    echo "Error: GeoNetwork container '$GEONETWORK_CONTAINER' is not running"
    echo "Run 'docker compose up -d' first"
    exit 1
fi

# --- Unpack backup ---
echo "Unpacking backup archive..."
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
tar -xvzf "$BACKUP_TGZ" -C "$BACKUP_DIR"

# --- Detect extracted backup directory ---
EXTRACTED_DIR=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
if [ -z "$EXTRACTED_DIR" ]; then
    echo "Error: Could not find extracted backup directory in $BACKUP_DIR"
    exit 1
fi
echo "Found backup data in: $EXTRACTED_DIR"

# --- Restore catalogue-data (idempotent) ---
echo "Restoring catalogue-data..."
if [ -d "$EXTRACTED_DIR/catalogue-data" ]; then
    echo "Deleting contents of $GN_DATA_PATH in GeoNetwork container to ensure idempotency..."
    docker exec "$GEONETWORK_CONTAINER" sh -c "rm -rf ${GN_DATA_PATH}/* ${GN_DATA_PATH}/.[!.]* ${GN_DATA_PATH}/..?* 2>/dev/null || true"
    
    echo "Copying catalogue-data to container..."
    # Copy contents into the data directory
    docker cp "$EXTRACTED_DIR/catalogue-data/." "$GEONETWORK_CONTAINER:$GN_DATA_PATH/"
    echo "Catalogue data restored."
else
    echo "Warning: $EXTRACTED_DIR/catalogue-data doesn't exist, skipping catalogue-data restore"
fi

# --- Restore database ---
echo "Restoring database..."
if [ -f "$EXTRACTED_DIR/geonetwork.sql" ]; then
    echo "First lines of SQL backup (for verification):"
    head -n 10 "$EXTRACTED_DIR/geonetwork.sql"
    
    echo "Terminating all connections to $DB_NAME..."
    docker exec "$DATABASE_CONTAINER" \
        psql -U "$DB_USER" -d postgres -c \
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();" \
        || true
    
    echo "Dropping and recreating database $DB_NAME..."
    docker exec "$DATABASE_CONTAINER" \
        psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
    
    if docker exec "$DATABASE_CONTAINER" \
        psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"; then
        echo "Database $DB_NAME created."
    else
        echo "Failed to create database $DB_NAME!"
        exit 1
    fi
    
    echo "Copying SQL file into database container..."
    if docker cp "$EXTRACTED_DIR/geonetwork.sql" "$DATABASE_CONTAINER:/tmp/geonetwork.sql"; then
        echo "SQL file copied successfully."
    else
        echo "Failed to copy SQL file to container!"
        exit 1
    fi
    
    echo "Restoring database from SQL file..."
    if docker exec "$DATABASE_CONTAINER" \
        bash -c "psql -U $DB_USER $DB_NAME < /tmp/geonetwork.sql"; then
        echo "Database restore completed successfully."
    else
        echo "Database restore failed! See output above."
        exit 1
    fi
    
    # Clean up SQL file from container
    docker exec "$DATABASE_CONTAINER" rm -f /tmp/geonetwork.sql
else
    echo "Error: $EXTRACTED_DIR/geonetwork.sql doesn't exist in local filesystem"
    exit 1
fi

# --- Restart GeoNetwork container ---
echo "Restarting GeoNetwork container..."
docker restart "$GEONETWORK_CONTAINER"

# --- Cleanup ---
echo "Cleaning up temporary files..."
rm -rf "$BACKUP_DIR"

echo ""
echo "============================================"
echo "Restore complete!"
echo "============================================"
echo ""
echo "GeoNetwork should be available at: http://localhost:8086/geonetwork"
echo "You may need to wait a moment for it to fully start."
