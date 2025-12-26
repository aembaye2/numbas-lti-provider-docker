# 🚀 Local/Codespace Deployment Guide

## Deploy Numbas LTI in GitHub Codespaces or Local Docker

This guide is for deploying Numbas LTI Provider **locally** in GitHub Codespaces or on your local machine, not on a VPS.

## ✨ Quick Deploy (Automated)

```bash
# You're already in the right directory!
# Run the local setup script
sudo bash setup-local.sh
```

This will automatically:
- ✅ Generate self-signed SSL certificate
- ✅ Configure for localhost
- ✅ Build Docker image
- ✅ Set up database
- ✅ Start all services

**Time: ~5 minutes**

---

## 📋 Manual Local Deployment

### Step 1: Generate SSL Certificate (Self-Signed)

```bash
# Create SSL directory
mkdir -p files/ssl

# Generate self-signed certificate for localhost
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout files/ssl/numbas-lti.key \
  -out files/ssl/numbas-lti.pem \
  -subj "/C=US/ST=State/L=City/O=Dev/CN=localhost"

# Set proper permissions
chmod 644 files/ssl/numbas-lti.pem
chmod 600 files/ssl/numbas-lti.key
```

### Step 2: Configure Environment

```bash
# The settings.env file is already configured for localhost!
# But you should update the admin password:
nano settings.env
```

Update these values in `settings.env`:
- `SUPERUSER_PASSWORD` - Change from default
- `POSTGRES_PASSWORD` - Change from default (or keep the generated one)

The following are already set correctly for localhost:
- `SERVERNAME=localhost`
- `INSTANCE_NAME=Numbas LTI (Local Dev)`

### Step 3: Build Docker Image

```bash
docker build . -t numbas/numbas-lti-provider
```

### Step 4: Generate Secret Key

```bash
SECRET_KEY=$(docker compose run --rm numbas-setup python ./get_secret_key 2>/dev/null | tail -1)
sed -i "s/SECRET_KEY=REPLACE_THIS_WITH_GENERATED_SECRET_KEY/SECRET_KEY=$SECRET_KEY/" settings.env
```

Or manually:
```bash
docker compose run --rm numbas-setup python ./get_secret_key
# Copy the output and paste into settings.env
```

### Step 5: Run Installation

```bash
docker compose run --rm numbas-setup python ./install
```

### Step 6: Start Services

```bash
docker compose up -d --scale daphne=2 --scale huey=1
```

### Step 7: Access the Application

#### In GitHub Codespaces:
When you start the services, VS Code will show a notification about forwarded ports. Click on the "Ports" tab at the bottom and find port 443. Click the globe icon to open it in your browser.

Or use the built-in browser:
```bash
# The URL will be shown in the Ports tab
# It will look like: https://xyz-443.app.github.dev
```

#### On Local Machine:
```bash
# Open in browser (you'll get a security warning for self-signed cert)
# Click "Advanced" → "Proceed to localhost"
open https://localhost
# or
xdg-open https://localhost  # Linux
# or just navigate to https://localhost in your browser
```

---

## 🔍 Check Status

```bash
# Check if all containers are running
docker compose ps

# View logs
docker compose logs -f

# Run diagnostics
sudo bash diagnose.sh
```

---

## 🌐 Accessing in GitHub Codespaces

GitHub Codespaces automatically forwards ports, but you need to configure it for HTTPS:

### Method 1: Port Forwarding (Recommended)

1. After starting services, click the **"Ports"** tab at the bottom of VS Code
2. Find port **443**
3. Right-click → **Port Visibility** → **Public** (if you want to share)
4. Click the **globe icon** to open in browser
5. Accept the security warning (self-signed certificate)

### Method 2: Direct Access

```bash
# Get your Codespace URL
echo "Your app is at: https://$CODESPACE_NAME-443.app.github.dev"
```

### Method 3: Simple Browser Preview

```bash
# Open in VS Code's simple browser
# Port forwarding happens automatically
```

---

## 🔒 About Self-Signed Certificates

When you access the application, you'll see a security warning because we're using a self-signed SSL certificate.

**This is normal for local development!**

To proceed:
- **Chrome/Edge**: Click "Advanced" → "Proceed to localhost (unsafe)"
- **Firefox**: Click "Advanced" → "Accept the Risk and Continue"
- **Safari**: Click "Show Details" → "visit this website"

---

## 📊 Resource Usage for Local Dev

For local development, use minimal resources:

```bash
# Light configuration (saves resources)
docker compose up -d --scale daphne=2 --scale huey=1
```

---

## 🛠️ Common Commands

### Start/Stop
```bash
# Start
docker compose up -d --scale daphne=2 --scale huey=1

# Stop
docker compose down

# Restart
docker compose restart
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f daphne
docker compose logs -f nginx
```

### Check Status
```bash
docker compose ps
docker stats
```

### Reset Everything
```bash
# Stop and remove everything
docker compose down -v

# Start fresh
docker build . -t numbas/numbas-lti-provider
docker compose run --rm numbas-setup python ./install
docker compose up -d --scale daphne=2 --scale huey=1
```

---

## 🐛 Troubleshooting

### Can't Access Application

**Issue**: Port 443 not accessible in Codespaces

**Solution**:
1. Check Ports tab - is port 443 forwarded?
2. Click the globe icon next to port 443
3. If no ports showing, restart containers: `docker compose restart`

### Security Warning Won't Go Away

**Issue**: Browser blocks self-signed certificate

**Solution**: This is expected! Click "Advanced" and proceed anyway. This is safe for local development.

### 502 Bad Gateway

**Solution**:
```bash
docker compose ps  # Check if daphne is running
docker compose restart daphne
docker compose logs daphne  # Check for errors
```

### Database Connection Errors

**Solution**:
```bash
docker compose ps postgres  # Check if running
docker compose logs postgres
# If needed, recreate:
docker compose down -v
docker compose up -d --scale daphne=2 --scale huey=1
```

---

## 💻 Development Tips

### 1. Persistent Data

Data is stored in Docker volumes:
```bash
docker volume ls | grep numbas
```

### 2. View Database

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U numbas_lti numbas_lti

# List tables
\dt

# Exit
\q
```

### 3. Django Admin

Access Django admin at: `https://localhost/admin/`

### 4. Change Log Level

Edit `settings.env`:
```bash
LOGLEVEL=DEBUG  # For more verbose logging
```

Then restart:
```bash
docker compose restart
```

---

## 🔄 Updating

```bash
# Pull latest changes
git pull

# Rebuild
docker build . --no-cache -t numbas/numbas-lti-provider

# Migrate
docker compose run --rm numbas-setup python ./install

# Restart
docker compose down
docker compose up -d --scale daphne=2 --scale huey=1
```

---

## 📝 Default Credentials

After setup:
- **URL**: `https://localhost` (or Codespace forwarded URL)
- **Username**: `admin` (or what you set in settings.env)
- **Password**: Check `settings.env` → `SUPERUSER_PASSWORD`

⚠️ **Change the password after first login!**

---

## 🎯 Next Steps

1. Log in to the admin interface
2. Create a test resource
3. Try the student view
4. Explore the documentation: https://docs.numbas.org.uk/lti

---

## 🆘 Need Help?

1. Run diagnostics: `sudo bash diagnose.sh`
2. Check logs: `docker compose logs -f`
3. Check the main guides: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## ⚡ Quick Reference

```bash
# Full setup (one command)
sudo bash setup-local.sh

# Check status
docker compose ps

# View logs
docker compose logs -f

# Stop everything
docker compose down

# Start everything
docker compose up -d --scale daphne=2 --scale huey=1

# Reset database
docker compose down -v
docker compose run --rm numbas-setup python ./install
```

---

**Ready?** Run `sudo bash setup-local.sh` and you'll be up in minutes!
