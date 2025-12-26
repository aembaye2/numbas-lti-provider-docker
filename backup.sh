#!/bin/bash

# Automated backup script for Numbas LTI Provider
# This script backs up the database and important files

set -e

# Configuration
BACKUP_DIR="/opt/numbas-backups"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_DIR="/opt/numbas-lti-provider-docker"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "Numbas LTI Provider - Backup Script"
echo "================================================"
echo ""
echo "Date: $(date)"
echo "Backup directory: $BACKUP_DIR"
echo ""

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Change to project directory
cd "$PROJECT_DIR" || exit 1

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo -e "${RED}Error: Docker containers are not running${NC}"
    exit 1
fi

# 1. Backup Database
echo "1. Backing up PostgreSQL database..."
docker compose exec -T postgres pg_dump -U numbas_lti numbas_lti > "$BACKUP_DIR/numbas_db_$DATE.sql"
if [ $? -eq 0 ]; then
    DB_SIZE=$(du -h "$BACKUP_DIR/numbas_db_$DATE.sql" | cut -f1)
    echo -e "${GREEN}✓${NC} Database backup completed: $DB_SIZE"
    
    # Compress database backup
    gzip "$BACKUP_DIR/numbas_db_$DATE.sql"
    COMPRESSED_SIZE=$(du -h "$BACKUP_DIR/numbas_db_$DATE.sql.gz" | cut -f1)
    echo -e "${GREEN}✓${NC} Database backup compressed: $COMPRESSED_SIZE"
else
    echo -e "${RED}✗${NC} Database backup failed"
fi

# 2. Backup Docker volumes
echo ""
echo "2. Backing up Docker volumes..."
VOLUMES=$(docker volume ls -q | grep "numbas-lti-provider-docker" || true)

if [ ! -z "$VOLUMES" ]; then
    for volume in $VOLUMES; do
        echo "  - Backing up volume: $volume"
        docker run --rm \
            -v "$volume:/data" \
            -v "$BACKUP_DIR:/backup" \
            ubuntu tar czf "/backup/${volume}_$DATE.tar.gz" /data
        
        if [ $? -eq 0 ]; then
            VOLUME_SIZE=$(du -h "$BACKUP_DIR/${volume}_$DATE.tar.gz" | cut -f1)
            echo -e "  ${GREEN}✓${NC} Volume backup completed: $VOLUME_SIZE"
        else
            echo -e "  ${RED}✗${NC} Volume backup failed"
        fi
    done
else
    echo -e "${YELLOW}⚠${NC} No Docker volumes found"
fi

# 3. Backup configuration files
echo ""
echo "3. Backing up configuration files..."
tar czf "$BACKUP_DIR/config_$DATE.tar.gz" \
    settings.env \
    docker-compose.yml \
    files/ssl/ \
    2>/dev/null || true

if [ $? -eq 0 ]; then
    CONFIG_SIZE=$(du -h "$BACKUP_DIR/config_$DATE.tar.gz" | cut -f1)
    echo -e "${GREEN}✓${NC} Configuration backup completed: $CONFIG_SIZE"
else
    echo -e "${RED}✗${NC} Configuration backup failed"
fi

# 4. Clean up old backups
echo ""
echo "4. Cleaning up old backups (older than $RETENTION_DAYS days)..."
DELETED_COUNT=$(find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
DELETED_COUNT=$((DELETED_COUNT + $(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)))

if [ $DELETED_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Removed $DELETED_COUNT old backup files"
else
    echo -e "${GREEN}✓${NC} No old backups to remove"
fi

# 5. Generate backup summary
echo ""
echo "================================================"
echo "Backup Summary"
echo "================================================"
echo ""

# List all backups for today
TODAY=$(date +%Y%m%d)
TODAYS_BACKUPS=$(find "$BACKUP_DIR" -name "*$TODAY*" 2>/dev/null)

if [ ! -z "$TODAYS_BACKUPS" ]; then
    echo "Today's backups:"
    find "$BACKUP_DIR" -name "*$TODAY*" -exec ls -lh {} \; | awk '{print "  - " $9 " (" $5 ")"}'
else
    echo "No backups found for today"
fi

echo ""

# Total backup size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo "Total backup directory size: $TOTAL_SIZE"

# Count of all backups
TOTAL_BACKUPS=$(find "$BACKUP_DIR" -type f | wc -l)
echo "Total backup files: $TOTAL_BACKUPS"

echo ""
echo -e "${GREEN}Backup completed successfully!${NC}"
echo ""
echo "To restore from this backup:"
echo "  Database:  gunzip < $BACKUP_DIR/numbas_db_$DATE.sql.gz | docker compose exec -T postgres psql -U numbas_lti numbas_lti"
echo "  Config:    tar xzf $BACKUP_DIR/config_$DATE.tar.gz"
echo ""
