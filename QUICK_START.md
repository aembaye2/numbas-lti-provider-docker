# Quick Start Guide - Numbas LTI Provider

## 🚀 Fastest Way to Deploy (Automated)

```bash
# SSH into your VPS
ssh root@your-vps-ip

# Clone the repository
cd /opt
git clone https://github.com/numbas/numbas-lti-provider-docker.git
cd numbas-lti-provider-docker

# Run the automated setup script
sudo bash setup.sh
```

The script will:
- ✅ Install Docker and prerequisites
- ✅ Generate SSL certificate (Let's Encrypt or self-signed)
- ✅ Configure all environment variables
- ✅ Build Docker image
- ✅ Generate secret key
- ✅ Set up database
- ✅ Configure firewall
- ✅ Start all services

**Time: ~10-15 minutes**

---

## 📋 Manual Installation (Step by Step)

### Prerequisites
1. VPS with Ubuntu 20.04+ or Debian 11+
2. Domain name pointing to your VPS
3. 2GB RAM, 2 CPU cores minimum

### Quick Steps

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | sh

# 2. Clone repository
cd /opt
git clone https://github.com/numbas/numbas-lti-provider-docker.git
cd numbas-lti-provider-docker

# 3. Get SSL certificate
apt install certbot
certbot certonly --standalone -d numbas.yourdomain.com
mkdir -p files/ssl
cp /etc/letsencrypt/live/numbas.yourdomain.com/fullchain.pem files/ssl/numbas-lti.pem
cp /etc/letsencrypt/live/numbas.yourdomain.com/privkey.pem files/ssl/numbas-lti.key

# 4. Configure environment (edit settings.env file)
cp settings.env.dist settings.env
nano settings.env  # Update values

# 5. Build and setup
docker build . -t numbas/numbas-lti-provider
docker compose run --rm numbas-setup python ./get_secret_key  # Copy this to settings.env
docker compose run --rm numbas-setup python ./install

# 6. Start services
docker compose up -d --scale daphne=4 --scale huey=1
```

---

## 🔧 Configuration Checklist

Edit `settings.env` and update these values:

- [ ] `SERVERNAME` - Your domain (e.g., numbas.yourdomain.com)
- [ ] `INSTANCE_NAME` - Display name
- [ ] `SUPERUSER_USER` - Admin username
- [ ] `SUPERUSER_PASSWORD` - Strong password
- [ ] `DEFAULT_FROM_EMAIL` - Email address
- [ ] `SUPPORT_URL` - Support contact
- [ ] `POSTGRES_PASSWORD` - Database password
- [ ] `SECRET_KEY` - Generated key (from get_secret_key script)

---

## 🎯 Essential Commands

### Service Management
```bash
# Start
docker compose up -d --scale daphne=4 --scale huey=1

# Stop
docker compose down

# Restart
docker compose restart

# Status
docker compose ps
```

### Logs
```bash
# All logs
docker compose logs -f

# Specific service
docker compose logs -f nginx
docker compose logs -f daphne
docker compose logs -f postgres
```

### Backup
```bash
# Database backup
docker compose exec postgres pg_dump -U numbas_lti numbas_lti > backup.sql

# Restore
cat backup.sql | docker compose exec -T postgres psql -U numbas_lti numbas_lti
```

### SSL Certificate Renewal (Let's Encrypt)
```bash
certbot renew
cp /etc/letsencrypt/live/YOUR_DOMAIN/fullchain.pem files/ssl/numbas-lti.pem
cp /etc/letsencrypt/live/YOUR_DOMAIN/privkey.pem files/ssl/numbas-lti.key
docker compose restart nginx
```

---

## 🐛 Troubleshooting

### Can't access via HTTPS
```bash
# Check DNS
nslookup numbas.yourdomain.com

# Check firewall
ufw status
ufw allow 443/tcp

# Check nginx logs
docker compose logs nginx
```

### 502 Bad Gateway
```bash
# Check daphne status
docker compose ps daphne

# Restart daphne
docker compose restart daphne

# Check logs
docker compose logs daphne
```

### Database connection errors
```bash
# Check postgres
docker compose ps postgres
docker compose logs postgres

# Verify password in settings.env
```

### SSL errors
```bash
# Check certificate files
ls -la files/ssl/

# Fix permissions
chmod 644 files/ssl/numbas-lti.pem
chmod 600 files/ssl/numbas-lti.key

# Restart nginx
docker compose restart nginx
```

---

## 🔒 Security Checklist

- [ ] Changed default admin password
- [ ] Changed database password
- [ ] Using strong passwords (16+ characters)
- [ ] SSL certificate properly configured
- [ ] Firewall configured (only ports 22, 80, 443)
- [ ] SSH key authentication enabled
- [ ] Regular backups scheduled
- [ ] System updates enabled

---

## 📊 Performance Tuning

### Low traffic (default)
```bash
docker compose up -d --scale daphne=2 --scale huey=1
```

### Medium traffic
```bash
docker compose up -d --scale daphne=4 --scale huey=1
```

### High traffic
```bash
docker compose up -d --scale daphne=8 --scale huey=2
```

---

## 📞 Getting Help

- Full guide: See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- Documentation: https://docs.numbas.org.uk/lti
- Issues: https://github.com/numbas/numbas-lti-provider/issues

---

## 📁 File Structure

```
numbas-lti-provider-docker/
├── docker-compose.yml          # Docker services configuration
├── Dockerfile                  # Docker image definition
├── settings.env               # Your configuration (DO NOT commit!)
├── settings.env.dist          # Template for settings
├── setup.sh                   # Automated setup script
├── DEPLOYMENT_GUIDE.md        # Detailed deployment guide
├── QUICK_START.md            # This file
└── files/
    ├── ssl/
    │   ├── numbas-lti.pem    # SSL certificate
    │   └── numbas-lti.key    # SSL private key
    └── numbas-lti-provider/
        ├── get_secret_key     # Generate Django secret key
        ├── install            # Installation script
        └── settings.py        # Django settings
```

---

## ✅ Post-Installation

After successful installation:

1. Navigate to `https://your-domain.com`
2. Log in with your admin credentials
3. Change your password immediately
4. Configure your LTI settings
5. Set up backups
6. Test with a sample activity

**Remember**: The application will automatically start on system reboot!
