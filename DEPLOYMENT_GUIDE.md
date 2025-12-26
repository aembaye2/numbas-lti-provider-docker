# Complete Deployment Guide for Numbas LTI Provider on VPS

This guide will walk you through deploying the Numbas LTI provider on your VPS step-by-step.

## Prerequisites

### 1. VPS Requirements
- Ubuntu 20.04+ or Debian 11+ (recommended)
- Minimum 2GB RAM, 2 CPU cores
- At least 20GB disk space
- Root or sudo access

### 2. Domain Setup
- A domain name pointing to your VPS IP address
- DNS A record: `numbas.yourdomain.com` → `your.vps.ip.address`

## Step-by-Step Installation

### Step 1: Connect to Your VPS

```bash
ssh root@your-vps-ip
# or
ssh your-username@your-vps-ip
```

### Step 2: Update System and Install Docker

```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker installation
sudo docker --version
sudo docker compose version
```

### Step 3: Clone the Repository

```bash
# Install git if not already installed
sudo apt install -y git

# Clone the repository
cd /opt
sudo git clone https://github.com/numbas/numbas-lti-provider-docker.git
cd numbas-lti-provider-docker
```

### Step 4: Obtain SSL Certificate

You have two options for SSL certificates:

#### Option A: Using Let's Encrypt (Recommended - Free)

```bash
# Install Certbot
sudo apt install -y certbot

# Obtain certificate (replace with your domain)
sudo certbot certonly --standalone -d numbas.yourdomain.com

# Create SSL directory
sudo mkdir -p files/ssl

# Copy certificates
sudo cp /etc/letsencrypt/live/numbas.yourdomain.com/fullchain.pem files/ssl/numbas-lti.pem
sudo cp /etc/letsencrypt/live/numbas.yourdomain.com/privkey.pem files/ssl/numbas-lti.key

# Set proper permissions
sudo chmod 644 files/ssl/numbas-lti.pem
sudo chmod 600 files/ssl/numbas-lti.key
```

**Note**: To renew Let's Encrypt certificates (every 90 days):
```bash
sudo certbot renew
sudo cp /etc/letsencrypt/live/numbas.yourdomain.com/fullchain.pem /opt/numbas-lti-provider-docker/files/ssl/numbas-lti.pem
sudo cp /etc/letsencrypt/live/numbas.yourdomain.com/privkey.pem /opt/numbas-lti-provider-docker/files/ssl/numbas-lti.key
sudo docker compose restart nginx
```

#### Option B: Using Self-Signed Certificate (Testing Only)

```bash
# Create SSL directory
sudo mkdir -p files/ssl

# Generate self-signed certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout files/ssl/numbas-lti.key \
  -out files/ssl/numbas-lti.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=numbas.yourdomain.com"
```

### Step 5: Configure Environment Variables

```bash
# Copy the environment file (already done - we created settings.env)
# Edit the settings.env file
sudo nano settings.env
```

**Update these values in settings.env:**

1. **SERVERNAME**: Your domain name (e.g., `numbas.yourdomain.com`)
2. **INSTANCE_NAME**: Display name for your instance
3. **SUPERUSER_USER**: Admin username (default: `admin`)
4. **SUPERUSER_PASSWORD**: Strong password for admin account
5. **DEFAULT_FROM_EMAIL**: Email address for system emails
6. **SUPPORT_URL**: Support contact (e.g., `mailto:support@yourdomain.com`)
7. **POSTGRES_PASSWORD**: Strong database password
8. **SECRET_KEY**: Will be generated in next step

### Step 6: Build Docker Image

```bash
sudo docker build . -t numbas/numbas-lti-provider
```

This may take 5-10 minutes.

### Step 7: Generate Secret Key

```bash
sudo docker compose run --rm numbas-setup python ./get_secret_key
```

Copy the generated key and paste it into `settings.env` for the `SECRET_KEY` variable:

```bash
sudo nano settings.env
# Find the line: SECRET_KEY=REPLACE_THIS_WITH_GENERATED_SECRET_KEY
# Replace with your generated key
```

### Step 8: Run Installation Script

```bash
sudo docker compose run --rm numbas-setup python ./install
```

This will:
- Set up the database
- Run migrations
- Create the superuser account
- Initialize the system

### Step 9: Configure Firewall

```bash
# If using UFW (Ubuntu Firewall)
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp  # Optional, for HTTP redirect
sudo ufw allow 22/tcp  # SSH
sudo ufw enable
sudo ufw status
```

### Step 10: Start the Application

```bash
# Start all services
sudo docker compose up -d --scale daphne=4 --scale huey=1

# Check status
sudo docker compose ps

# View logs
sudo docker compose logs -f
```

### Step 11: Verify Installation

1. Open your browser and navigate to: `https://numbas.yourdomain.com`
2. You should see the Numbas LTI provider login page
3. Log in with your superuser credentials

## Post-Installation Configuration

### Set Up Automatic Startup

The containers are configured with `restart: always`, so they will automatically start on system reboot.

### Set Up Log Rotation

Create `/etc/docker/daemon.json`:

```bash
sudo nano /etc/docker/daemon.json
```

Add:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Restart Docker:
```bash
sudo systemctl restart docker
sudo docker compose up -d --scale daphne=4 --scale huey=1
```

### Monitor the Application

```bash
# View all container logs
sudo docker compose logs -f

# View specific service logs
sudo docker compose logs -f daphne
sudo docker compose logs -f nginx
sudo docker compose logs -f postgres

# Check container status
sudo docker compose ps

# Check resource usage
sudo docker stats
```

## Useful Commands

### Starting/Stopping

```bash
# Stop all services
sudo docker compose down

# Start all services
sudo docker compose up -d --scale daphne=4 --scale huey=1

# Restart specific service
sudo docker compose restart nginx
```

### Backups

```bash
# Backup database
sudo docker compose exec postgres pg_dump -U numbas_lti numbas_lti > backup_$(date +%Y%m%d).sql

# Backup volumes
sudo docker run --rm -v numbas-lti-provider-docker_numbas:/data -v $(pwd):/backup ubuntu tar czf /backup/numbas-data-$(date +%Y%m%d).tar.gz /data
```

### Restore Database

```bash
# Stop services
sudo docker compose down

# Start only database
sudo docker compose up -d postgres

# Wait for database to be ready
sleep 10

# Restore
cat backup_YYYYMMDD.sql | sudo docker compose exec -T postgres psql -U numbas_lti numbas_lti

# Start all services
sudo docker compose up -d --scale daphne=4 --scale huey=1
```

### Upgrading

```bash
cd /opt/numbas-lti-provider-docker

# Pull latest changes
sudo git pull

# Rebuild image
sudo docker build . --no-cache -t numbas/numbas-lti-provider

# Run migrations
sudo docker compose run --rm numbas-setup python ./install

# Restart services
sudo docker compose down
sudo docker compose up -d --scale daphne=4 --scale huey=1
```

## Troubleshooting

### Issue: Can't access via HTTPS

**Check:**
1. DNS is properly configured: `nslookup numbas.yourdomain.com`
2. Firewall allows port 443: `sudo ufw status`
3. Nginx is running: `sudo docker compose ps nginx`
4. Check nginx logs: `sudo docker compose logs nginx`

### Issue: SSL certificate errors

**Solution:**
```bash
# Verify certificate files exist
ls -la files/ssl/

# Check permissions
sudo chmod 644 files/ssl/numbas-lti.pem
sudo chmod 600 files/ssl/numbas-lti.key

# Restart nginx
sudo docker compose restart nginx
```

### Issue: Database connection errors

**Solution:**
```bash
# Check if postgres is running
sudo docker compose ps postgres

# Check postgres logs
sudo docker compose logs postgres

# Verify password in settings.env matches
sudo nano settings.env
```

### Issue: "502 Bad Gateway"

**Solution:**
```bash
# Check if daphne containers are running
sudo docker compose ps daphne

# Check daphne logs
sudo docker compose logs daphne

# Restart daphne
sudo docker compose restart daphne
```

### Issue: Out of memory

**Solution:**
```bash
# Check memory usage
free -h
sudo docker stats

# Reduce number of daphne workers
sudo docker compose up -d --scale daphne=2 --scale huey=1
```

## Security Best Practices

1. **Change default passwords** - Update `SUPERUSER_PASSWORD` and `POSTGRES_PASSWORD`
2. **Keep system updated** - Run `sudo apt update && sudo apt upgrade` regularly
3. **Monitor logs** - Regularly check logs for suspicious activity
4. **Backup regularly** - Set up automated backups of database and volumes
5. **Use strong passwords** - At least 16 characters with mixed case, numbers, and symbols
6. **Limit SSH access** - Use SSH keys instead of passwords, disable root login
7. **Keep Docker updated** - Update Docker regularly for security patches

## Performance Tuning

### For High Traffic

Increase the number of daphne workers:
```bash
sudo docker compose up -d --scale daphne=8 --scale huey=2
```

### Database Optimization

Add to postgres service in docker-compose.yml:
```yaml
environment:
  - POSTGRES_SHARED_BUFFERS=256MB
  - POSTGRES_EFFECTIVE_CACHE_SIZE=1GB
```

## Support

- Documentation: https://docs.numbas.org.uk/lti
- GitHub Issues: https://github.com/numbas/numbas-lti-provider/issues
- Community Forum: https://github.com/numbas/Numbas/discussions

## License

The Numbas LTI provider is licensed under the Apache License 2.0.
