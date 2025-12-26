# ✨ Numbas LTI Provider - Successfully Deployed!

## 🎉 Deployment Status: RUNNING

Your Numbas LTI Provider is now live and running in this Codespace!

---

## 🌐 How to Access

### In GitHub Codespaces (Current Environment)

1. **Look at the bottom panel** - Find the "PORTS" tab
2. **Find port 443** in the list
3. **Click the globe icon** (🌐) next to port 443 to open in browser
4. **Accept the security warning** (self-signed certificate - normal for local dev)

OR

Simply click on this forwarded URL (it should appear automatically in VS Code)

---

## 🔐 Login Information

**URL**: Check the Ports tab for your forwarded HTTPS URL  
**Username**: `admin`  
**Password**: `ChangeThisStrongPassword123!`

⚠️ **Important**: Change your password after first login!

---

## ✅ What's Running

- ✅ **NGINX** - Web server with SSL (Port 443)
- ✅ **Daphne** - Application server (2 instances)
- ✅ **PostgreSQL** - Database
- ✅ **Redis** - Cache and queue
- ✅ **Huey** - Background worker

---

## 📋 Quick Commands

### Check Status
```bash
docker compose ps
```

### View Logs
```bash
docker compose logs -f           # All services
docker compose logs -f nginx     # Just nginx
docker compose logs -f daphne    # Just app server
```

### Restart Services
```bash
docker compose restart
```

### Stop Everything
```bash
docker compose down
```

### Start Again
```bash
docker compose up -d --scale daphne=2 --scale huey=1
```

### Run Diagnostics
```bash
sudo bash diagnose.sh
```

---

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| [LOCAL_DEPLOYMENT.md](LOCAL_DEPLOYMENT.md) | Local/Codespace deployment guide |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Full VPS deployment guide |
| [QUICK_START.md](QUICK_START.md) | Quick reference |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture |

---

## 🎓 Next Steps

1. **Access the application** via the Ports tab
2. **Log in** with the credentials above
3. **Change your password** (click your username → Settings)
4. **Explore the interface**
   - Create a test resource
   - Try student view
   - Configure LTI settings
5. **Read the docs**: https://docs.numbas.org.uk/lti

---

## 🐛 Troubleshooting

### Can't see port 443 in Ports tab?
```bash
docker compose ps  # Check if nginx is running
docker compose restart nginx
```

### Getting 502 Bad Gateway?
```bash
docker compose logs daphne  # Check for errors
docker compose restart daphne
```

### Need to reset everything?
```bash
docker compose down -v  # Remove all data
sudo bash setup-local.sh  # Start fresh
```

### Security warning in browser?
This is **normal** for self-signed SSL certificates in development!  
Click "Advanced" → "Proceed to localhost" or equivalent.

---

## 🔧 Advanced

### Access Database
```bash
docker compose exec postgres psql -U numbas_lti numbas_lti
```

### View Environment Config
```bash
cat settings.env
```

### Check Resource Usage
```bash
docker stats
```

---

## 📞 Getting Help

1. **Run diagnostics**: `sudo bash diagnose.sh`
2. **Check logs**: `docker compose logs -f`
3. **Read guides**: See documentation links above
4. **Official docs**: https://docs.numbas.org.uk/lti
5. **GitHub Issues**: https://github.com/numbas/numbas-lti-provider/issues

---

## 🎯 Deployment Options

### Current: Local Development
✅ Running in GitHub Codespace  
✅ Self-signed SSL certificate  
✅ Minimal resource usage (2 daphne, 1 huey)

### Want to deploy to a real VPS?
See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for production deployment with:
- Real domain name
- Let's Encrypt SSL
- Production configuration
- Automated backups

---

## 💡 Tips

- **Port forwarding is automatic** in Codespaces
- **Data persists** in Docker volumes (survives container restarts)
- **Self-signed cert is fine** for development
- **Logs are your friend** when troubleshooting
- **Diagnostics script** helps identify issues

---

## 🚀 All Set!

Your Numbas LTI Provider is ready to use. Check the **Ports tab** below to access it!

**Happy testing! 🎉**
