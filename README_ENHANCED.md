# Numbas LTI Provider - VPS Deployment Package

This enhanced repository provides everything you need to deploy the Numbas LTI Provider on your own VPS with minimal hassle.

## 🎯 What's Included

- **Automated Setup Script** - One command deployment
- **Complete Deployment Guide** - Step-by-step instructions
- **Quick Start Guide** - Fast reference for common tasks
- **Diagnostic Tool** - Health check and troubleshooting
- **Pre-configured Environment** - Sensible defaults

## 🚀 Quick Start (Recommended)

### Automated Installation

The easiest way to get started:

```bash
# SSH into your VPS
ssh root@your-vps-ip

# Clone this repository
cd /opt
git clone https://github.com/numbas/numbas-lti-provider-docker.git
cd numbas-lti-provider-docker

# Run the automated setup script
sudo bash setup.sh
```

**That's it!** The script will handle everything:
- Docker installation
- SSL certificate setup
- Configuration
- Database initialization
- Service startup

**Time required:** ~10-15 minutes

### Manual Installation

If you prefer manual control, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions.

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [QUICK_START.md](QUICK_START.md) | Fast reference for installation and common tasks |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Comprehensive deployment guide with troubleshooting |
| [README_ORIGINAL.md](README.md) | Original Numbas documentation |

## 🛠️ Included Tools

### Setup Script (`setup.sh`)
Automated installation wizard that:
- Installs all prerequisites
- Configures SSL certificates (Let's Encrypt or self-signed)
- Sets up environment variables
- Initializes database
- Starts all services

### Diagnostic Script (`diagnose.sh`)
Health check tool that verifies:
- System requirements
- Docker installation
- Configuration files
- SSL certificates
- Container status
- Network connectivity
- Recent errors

Run it anytime: `sudo bash diagnose.sh`

### Pre-configured Environment (`settings.env`)
Ready-to-use configuration file with sensible defaults. Just update:
- Your domain name
- Admin credentials
- Email settings

## 📋 Prerequisites

- **VPS Requirements:**
  - Ubuntu 20.04+ or Debian 11+
  - 2GB RAM minimum (4GB recommended)
  - 2 CPU cores minimum
  - 20GB disk space

- **Domain:** 
  - A domain or subdomain pointing to your VPS IP
  - DNS A record configured

- **Access:**
  - Root or sudo access to VPS
  - SSH access

## ⚡ Installation Methods

### Method 1: Automated (Recommended)
```bash
sudo bash setup.sh
```
Perfect for: First-time users, quick deployments

### Method 2: Manual Installation
Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)  
Perfect for: Custom configurations, production environments

### Method 3: Quick Manual
Follow [QUICK_START.md](QUICK_START.md)  
Perfect for: Experienced users who know what they're doing

## 🔧 Common Tasks

### Check System Health
```bash
sudo bash diagnose.sh
```

### View Logs
```bash
docker compose logs -f
```

### Start Services
```bash
docker compose up -d --scale daphne=4 --scale huey=1
```

### Stop Services
```bash
docker compose down
```

### Backup Database
```bash
docker compose exec postgres pg_dump -U numbas_lti numbas_lti > backup_$(date +%Y%m%d).sql
```

### Renew SSL Certificate
```bash
certbot renew
cp /etc/letsencrypt/live/YOUR_DOMAIN/fullchain.pem files/ssl/numbas-lti.pem
cp /etc/letsencrypt/live/YOUR_DOMAIN/privkey.pem files/ssl/numbas-lti.key
docker compose restart nginx
```

## 🐛 Troubleshooting

### Quick Diagnostics
```bash
sudo bash diagnose.sh
```

### Common Issues

**Can't access website:**
- Check DNS: `nslookup your-domain.com`
- Check firewall: `sudo ufw status`
- Check containers: `docker compose ps`

**502 Bad Gateway:**
```bash
docker compose restart daphne
docker compose logs daphne
```

**SSL Errors:**
```bash
ls -la files/ssl/
chmod 644 files/ssl/numbas-lti.pem
chmod 600 files/ssl/numbas-lti.key
docker compose restart nginx
```

For more solutions, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting)

## 🔒 Security Checklist

After installation:
- [ ] Change default admin password
- [ ] Use strong database password
- [ ] Configure firewall (ports 22, 80, 443 only)
- [ ] Set up regular backups
- [ ] Enable automatic security updates
- [ ] Configure SSL with Let's Encrypt
- [ ] Review `settings.env` for sensitive data

## 📊 Performance Tuning

### Low Traffic (< 50 concurrent users)
```bash
docker compose up -d --scale daphne=2 --scale huey=1
```

### Medium Traffic (50-200 concurrent users)
```bash
docker compose up -d --scale daphne=4 --scale huey=1
```

### High Traffic (> 200 concurrent users)
```bash
docker compose up -d --scale daphne=8 --scale huey=2
```

## 🔄 Upgrading

```bash
cd /opt/numbas-lti-provider-docker
git pull
docker build . --no-cache -t numbas/numbas-lti-provider
docker compose run --rm numbas-setup python ./install
docker compose down
docker compose up -d --scale daphne=4 --scale huey=1
```

## 📁 Repository Structure

```
numbas-lti-provider-docker/
├── setup.sh                    # 🚀 Automated setup script
├── diagnose.sh                 # 🔍 Diagnostic tool
├── settings.env                # ⚙️ Your configuration (pre-filled)
├── settings.env.dist           # 📝 Configuration template
├── QUICK_START.md             # ⚡ Quick reference guide
├── DEPLOYMENT_GUIDE.md        # 📖 Complete deployment guide
├── docker-compose.yml         # 🐳 Docker services
├── Dockerfile                 # 🐳 Image definition
└── files/
    ├── ssl/                   # 🔒 SSL certificates
    │   ├── numbas-lti.pem
    │   └── numbas-lti.key
    └── numbas-lti-provider/
        ├── get_secret_key
        ├── install
        └── settings.py
```

## 🎓 Learning Resources

- **Official Documentation:** https://docs.numbas.org.uk/lti
- **Administrator Guide:** https://docs.numbas.org.uk/lti/admin/
- **Instructor Guide:** https://docs.numbas.org.uk/lti/instructor/
- **GitHub Issues:** https://github.com/numbas/numbas-lti-provider/issues

## 💬 Getting Help

1. **Run diagnostics:** `sudo bash diagnose.sh`
2. **Check logs:** `docker compose logs -f`
3. **Review guides:** See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
4. **Community support:** https://github.com/numbas/Numbas/discussions
5. **Report issues:** https://github.com/numbas/numbas-lti-provider/issues

## 📝 License

The Numbas LTI provider is licensed under the Apache License 2.0.

## 🙏 Credits

- **Original Project:** [Numbas LTI Provider](https://github.com/numbas/numbas-lti-provider)
- **Docker Implementation:** [Numbas LTI Provider Docker](https://github.com/numbas/numbas-lti-provider-docker)
- **Enhanced Deployment Package:** Community contribution for easier VPS deployment

## ⭐ Next Steps

After successful installation:

1. **Access your instance:** `https://your-domain.com`
2. **Log in** with your admin credentials
3. **Change password** immediately
4. **Configure LTI settings** for your learning platform
5. **Create a test activity**
6. **Set up backups**
7. **Review security settings**

---

**Questions?** Start with [QUICK_START.md](QUICK_START.md) or run `sudo bash diagnose.sh` to check your setup!
