# Numbas LTI Provider - Architecture & Flow

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          INTERNET                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTPS (Port 443)
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                        YOUR VPS                                  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    DOCKER COMPOSE                           │ │
│  │                                                             │ │
│  │  ┌─────────────┐                                           │ │
│  │  │   NGINX     │  SSL Termination & Reverse Proxy          │ │
│  │  │   (Port     │  - Handles HTTPS                          │ │
│  │  │   443)      │  - Serves static files                    │ │
│  │  └──────┬──────┘  - Routes to Daphne                       │ │
│  │         │                                                   │ │
│  │         │ HTTP (Internal)                                  │ │
│  │         │                                                   │ │
│  │  ┌──────▼──────┐                                           │ │
│  │  │   DAPHNE    │  Django/ASGI Server (x4 by default)       │ │
│  │  │   (8700)    │  - Handles web requests                   │ │
│  │  │  ┌────────┐ │  - Manages LTI sessions                   │ │
│  │  │  │ Django │ │  - Serves Numbas content                  │ │
│  │  │  └───┬────┘ │                                           │ │
│  │  └──────┼──────┘                                           │ │
│  │         │                                                   │ │
│  │         ├────────┐                                         │ │
│  │         │        │                                         │ │
│  │  ┌──────▼──┐  ┌─▼────────┐                                │ │
│  │  │ POSTGRES│  │  REDIS   │                                │ │
│  │  │  (5432) │  │  (6379)  │                                │ │
│  │  │         │  │          │                                │ │
│  │  │ Database│  │  Cache & │                                │ │
│  │  │ Storage │  │  Queue   │                                │ │
│  │  └─────────┘  └──┬───────┘                                │ │
│  │                   │                                         │ │
│  │            ┌──────▼──────┐                                 │ │
│  │            │    HUEY     │  Background Task Worker         │ │
│  │            │             │  - Processes async tasks        │ │
│  │            │             │  - Generates reports            │ │
│  │            │             │  - Sends score updates          │ │
│  │            └─────────────┘                                 │ │
│  │                                                             │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Volumes (Persistent Storage):                                  │
│  ├── numbas_data/        - Media files, uploads                 │
│  ├── postgres_data/      - Database files                       │
│  └── redis_data/         - Cache data                           │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## 🔄 Request Flow

### 1. Student Access Flow

```
Student Browser
      │
      │ 1. HTTPS Request
      ▼
   NGINX (Port 443)
      │
      │ 2. SSL Decryption
      │ 3. Proxy to Daphne
      ▼
   DAPHNE (Port 8700)
      │
      │ 4. Django Processes Request
      │ 5. Check Authentication
      ▼
   POSTGRES
      │
      │ 6. Fetch User Data
      │ 7. Load Exam Content
      ▼
   DAPHNE
      │
      │ 8. Render Response
      ▼
   NGINX
      │
      │ 9. HTTPS Response
      ▼
Student Browser
```

### 2. LTI Integration Flow

```
Learning Platform (Moodle/Canvas/etc)
      │
      │ 1. LTI Launch Request
      │    (with OAuth signature)
      ▼
   NGINX → DAPHNE
      │
      │ 2. Validate OAuth
      │ 3. Create/Update User
      │ 4. Start Session
      ▼
   POSTGRES
      │
      │ 5. Store Context
      ▼
   DAPHNE
      │
      │ 6. Redirect to Exam
      ▼
   Student Browser
```

### 3. Score Reporting Flow

```
Student Submits Answer
      │
      ▼
   DAPHNE
      │
      │ 1. Save Attempt
      ▼
   POSTGRES
      │
      │ 2. Calculate Score
      │ 3. Queue Report Job
      ▼
   REDIS
      │
      │ 4. Job Queued
      ▼
   HUEY Worker
      │
      │ 5. Process Job
      │ 6. Send Score via LTI
      ▼
Learning Platform
```

## 📦 Component Details

### NGINX
- **Role**: SSL termination, static file serving, reverse proxy
- **Ports**: 443 (HTTPS external), proxies to Daphne:8700
- **Config**: `/files/nginx/templates/default.conf.template`
- **Scaling**: 1 instance (no need to scale)

### Daphne (Django ASGI Server)
- **Role**: Web application server
- **Ports**: 8700 (internal only)
- **Instances**: 4 by default (adjust with `--scale daphne=N`)
- **When to scale**: Increase for more concurrent users

### Huey (Background Worker)
- **Role**: Asynchronous task processing
- **Tasks**: Score reporting, email sending, report generation
- **Instances**: 1 by default (increase for heavy usage)
- **When to scale**: If tasks are slow or backing up

### PostgreSQL
- **Role**: Primary database
- **Ports**: 5432 (internal only)
- **Storage**: Docker volume (persistent)
- **Scaling**: 1 instance (database doesn't scale horizontally)

### Redis
- **Role**: Cache and task queue
- **Ports**: 6379 (internal only)
- **Storage**: Docker volume
- **Scaling**: 1 instance

## 🗄️ Data Storage

### PostgreSQL Database
```
Tables:
├── users               - User accounts
├── contexts            - LTI contexts (courses)
├── resources           - Exams/activities
├── attempts            - Student attempts
├── scorm_elements      - Attempt data
└── discounts           - Scoring adjustments
```

### Docker Volumes
```
numbas-lti-provider-docker_numbas/
├── numbas-lti-static/  - CSS, JS, images
├── numbas-lti-media/   - User uploads, generated reports
└── www/                - Error pages

numbas-lti-provider-docker_postgres/
└── [PostgreSQL data files]

numbas-lti-provider-docker_redis/
└── [Redis data files]
```

## 🔒 Security Layers

```
Layer 1: SSL/TLS Encryption (NGINX)
         ↓
Layer 2: Firewall (UFW/iptables)
         ↓
Layer 3: Django Authentication
         ↓
Layer 4: LTI OAuth Signature Validation
         ↓
Layer 5: Database Access Control
         ↓
Layer 6: Container Isolation (Docker)
```

## 🚀 Scaling Strategies

### Vertical Scaling (Single VPS)
```
Light Load:  daphne=2, huey=1  (2GB RAM)
Medium Load: daphne=4, huey=1  (4GB RAM)
High Load:   daphne=8, huey=2  (8GB RAM)
```

### Horizontal Scaling (Multiple VPS)
```
Option 1: Load Balancer
         ↓
    ┌────┼────┐
    │    │    │
  VPS1 VPS2 VPS3  (each running daphne)
    │    │    │
    └────┼────┘
         ↓
   Shared Database VPS
```

## 📊 Resource Requirements

### Minimum (Testing)
- CPU: 2 cores
- RAM: 2GB
- Disk: 20GB
- Users: < 50 concurrent

### Recommended (Production)
- CPU: 4 cores
- RAM: 4-8GB
- Disk: 50GB SSD
- Users: 100-200 concurrent

### High Performance
- CPU: 8+ cores
- RAM: 16GB+
- Disk: 100GB SSD
- Users: 500+ concurrent
- Consider: Separate database server

## 🔍 Monitoring Points

### Health Checks
```bash
# Container Health
docker compose ps

# Resource Usage
docker stats

# Database Connections
docker compose exec postgres psql -U numbas_lti -c "SELECT count(*) FROM pg_stat_activity;"

# Redis Memory
docker compose exec redis redis-cli INFO memory

# Disk Usage
df -h
docker system df
```

### Log Locations
```
Application Logs:  docker compose logs daphne
Web Server Logs:   docker compose logs nginx
Database Logs:     docker compose logs postgres
Worker Logs:       docker compose logs huey
All Logs:          docker compose logs -f
```

## 🛠️ Maintenance Tasks

### Daily
- Monitor disk space
- Check error logs
- Verify backups

### Weekly
- Review performance metrics
- Check SSL certificate expiry
- Update Docker images (if needed)

### Monthly
- Database optimization
- Clear old log files
- Review security updates

### Quarterly
- Major version upgrades
- Backup restore test
- Security audit

## 📈 Performance Optimization

### Database
```sql
-- Regular maintenance
VACUUM ANALYZE;

-- Index optimization
REINDEX DATABASE numbas_lti;
```

### Nginx
```nginx
# Enable gzip compression (already in template)
gzip on;
gzip_types text/css application/javascript;

# Cache static files (already configured)
location /static {
    expires 30d;
}
```

### Docker
```json
// /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

## 🔄 Upgrade Path

```
Current Version
      │
      │ 1. Backup
      ▼
   Stop Containers
      │
      │ 2. Pull Changes
      ▼
   Rebuild Image
      │
      │ 3. Run Migrations
      ▼
   Start Containers
      │
      │ 4. Verify
      ▼
   Updated Version
```

## 📞 Support Resources

- Architecture Questions: https://github.com/numbas/numbas-lti-provider/discussions
- Performance Issues: Check scaling configuration
- Database Problems: Review PostgreSQL logs
- Network Issues: Check firewall and DNS

---

This architecture provides a robust, scalable solution for deploying Numbas LTI Provider!
