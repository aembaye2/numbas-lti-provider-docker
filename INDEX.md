# 📚 Numbas LTI Provider - Documentation Index

Welcome to the complete deployment package for Numbas LTI Provider on VPS!

## 🎯 Start Here

**New to Numbas LTI?** → Read [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) first!

**Ready to deploy?** → Use [QUICK_START.md](QUICK_START.md)

**Want details?** → See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

## 📖 Documentation Structure

### Getting Started

| Document | Purpose | Time to Read |
|----------|---------|--------------|
| [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) | Overview & quick reference | 5 min |
| [QUICK_START.md](QUICK_START.md) | Fast installation & commands | 10 min |
| [README_ENHANCED.md](README_ENHANCED.md) | Main documentation hub | 15 min |

### Detailed Guides

| Document | Purpose | Time to Read |
|----------|---------|--------------|
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Complete step-by-step guide | 30 min |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture & design | 20 min |
| [README.md](README.md) | Original Numbas documentation | 10 min |

### Reference

| Document | Purpose |
|----------|---------|
| [INDEX.md](INDEX.md) | This file - navigation hub |
| [settings.env](settings.env) | Configuration file (pre-filled) |
| [docker-compose.yml](docker-compose.yml) | Docker services definition |

## 🛠️ Tools & Scripts

### Automated Tools

| Script | Purpose | Usage |
|--------|---------|-------|
| [setup.sh](setup.sh) | Full automated installation | `sudo bash setup.sh` |
| [diagnose.sh](diagnose.sh) | Health check & diagnostics | `sudo bash diagnose.sh` |
| [backup.sh](backup.sh) | Backup database & config | `sudo bash backup.sh` |

### How They Work Together

```
setup.sh
  ↓
  Installs everything automatically
  ↓
diagnose.sh
  ↓
  Checks if installation is healthy
  ↓
backup.sh
  ↓
  Creates regular backups
```

## 🚀 Deployment Paths

Choose your path based on your experience level:

### Path 1: Beginner (Automated)
```
1. Read DEPLOYMENT_SUMMARY.md
2. Run: sudo bash setup.sh
3. Follow prompts
4. Done! (~15 minutes)
```

### Path 2: Intermediate (Semi-Automated)
```
1. Read QUICK_START.md
2. Edit settings.env
3. Run setup commands manually
4. Use diagnose.sh to verify
```

### Path 3: Advanced (Manual)
```
1. Read DEPLOYMENT_GUIDE.md thoroughly
2. Customize all configurations
3. Manual step-by-step deployment
4. Full control over every aspect
```

## 📋 Common Tasks Quick Reference

### Installation
```bash
# Automated
sudo bash setup.sh

# Manual
# See QUICK_START.md or DEPLOYMENT_GUIDE.md
```

### Health Check
```bash
sudo bash diagnose.sh
```

### View Logs
```bash
docker compose logs -f
```

### Backup
```bash
sudo bash backup.sh
```

### Restart
```bash
docker compose restart
```

### Stop/Start
```bash
docker compose down
docker compose up -d --scale daphne=4 --scale huey=1
```

## 🔍 Finding Information

### Need to know HOW to...

| Task | Document | Section |
|------|----------|---------|
| Install from scratch | DEPLOYMENT_GUIDE.md | Installation |
| Configure SSL | DEPLOYMENT_GUIDE.md | Step 4 |
| Set environment variables | DEPLOYMENT_GUIDE.md | Step 5 |
| Backup database | QUICK_START.md | Backup |
| Troubleshoot errors | DEPLOYMENT_GUIDE.md | Troubleshooting |
| Scale for more users | ARCHITECTURE.md | Scaling Strategies |
| Understand architecture | ARCHITECTURE.md | All sections |

### Need to understand WHY...

| Question | Document | Section |
|----------|----------|---------|
| Why 4 daphne instances? | ARCHITECTURE.md | Component Details |
| Why NGINX and Daphne? | ARCHITECTURE.md | System Architecture |
| Why separate volumes? | ARCHITECTURE.md | Data Storage |
| Why Huey worker? | ARCHITECTURE.md | Component Details |
| Security best practices? | DEPLOYMENT_GUIDE.md | Security |

## 🎓 Learning Path

For complete understanding, read in this order:

1. **DEPLOYMENT_SUMMARY.md** - Get overview
2. **ARCHITECTURE.md** - Understand design
3. **DEPLOYMENT_GUIDE.md** - Learn deployment
4. **QUICK_START.md** - Reference commands
5. **README_ENHANCED.md** - Full context

Total time: ~1.5 hours

## 🔧 Configuration Files

### Core Configuration
- **settings.env** - Your main configuration (EDIT THIS!)
- **docker-compose.yml** - Service definitions (no changes needed)
- **Dockerfile** - Image definition (no changes needed)

### Generated/Optional
- **files/ssl/numbas-lti.pem** - SSL certificate
- **files/ssl/numbas-lti.key** - SSL private key

### Templates
- **settings.env.dist** - Configuration template (reference only)

## 📊 By User Type

### System Administrators

Priority reading:
1. DEPLOYMENT_GUIDE.md - Full deployment process
2. ARCHITECTURE.md - Understanding the system
3. DEPLOYMENT_SUMMARY.md - Quick reference

Key files:
- settings.env
- backup.sh
- diagnose.sh

### DevOps Engineers

Priority reading:
1. ARCHITECTURE.md - System design
2. docker-compose.yml - Service configuration
3. DEPLOYMENT_GUIDE.md - Deployment automation

Key concerns:
- Scaling strategies
- Monitoring
- Backup & recovery

### Developers

Priority reading:
1. ARCHITECTURE.md - Technical architecture
2. README.md - Original documentation
3. Official docs: https://docs.numbas.org.uk/lti

Key files:
- Dockerfile
- docker-compose.yml
- files/numbas-lti-provider/

### End Users (Instructors)

Priority reading:
1. Official instructor guide: https://docs.numbas.org.uk/lti/instructor/

Not in this package:
- End user documentation is at docs.numbas.org.uk

## 🆘 Troubleshooting Guide

### Problem Categories

| Issue Type | First Check | Document | Tool |
|------------|-------------|----------|------|
| Installation failed | Run diagnose.sh | DEPLOYMENT_GUIDE.md | diagnose.sh |
| Can't access site | Check DNS & firewall | DEPLOYMENT_GUIDE.md | diagnose.sh |
| 502 Error | Check daphne logs | QUICK_START.md | docker compose logs |
| SSL errors | Verify certificates | DEPLOYMENT_GUIDE.md | openssl verify |
| Performance issues | Check resources | ARCHITECTURE.md | docker stats |
| Database errors | Check postgres logs | DEPLOYMENT_GUIDE.md | docker compose logs |

### Quick Fixes

```bash
# Most common fix - restart services
docker compose restart

# If that doesn't work - full restart
docker compose down
docker compose up -d --scale daphne=4 --scale huey=1

# Still broken? Check diagnostics
sudo bash diagnose.sh

# Check logs for errors
docker compose logs -f | grep -i error
```

## 🔒 Security Checklist

From [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#security-best-practices):

- [ ] Changed default passwords
- [ ] SSL certificate installed
- [ ] Firewall configured
- [ ] Regular backups scheduled
- [ ] System updates enabled
- [ ] Strong passwords used
- [ ] settings.env not in git
- [ ] SSH keys configured

## 📈 Performance Tuning

See [ARCHITECTURE.md](ARCHITECTURE.md#scaling-strategies) for:
- Scaling guidelines by user count
- Resource requirements
- Optimization tips

## 🔄 Maintenance Schedule

| Frequency | Tasks | Document |
|-----------|-------|----------|
| Daily | Check logs, monitor disk | ARCHITECTURE.md |
| Weekly | Run diagnostics | diagnose.sh |
| Monthly | Backup, updates | backup.sh |
| Quarterly | Full system review | DEPLOYMENT_GUIDE.md |

## 📞 Getting Help

### Self-Service (Do This First!)
1. Run `sudo bash diagnose.sh`
2. Check logs: `docker compose logs -f`
3. Search this documentation
4. Review troubleshooting sections

### External Resources
- **Official Docs**: https://docs.numbas.org.uk/lti
- **GitHub Issues**: https://github.com/numbas/numbas-lti-provider/issues
- **Discussions**: https://github.com/numbas/Numbas/discussions
- **Community**: Numbas user forums

## ✅ Verification Checklist

After deployment, verify:

- [ ] `sudo bash diagnose.sh` shows all green
- [ ] Can access https://your-domain.com
- [ ] Can log in as admin
- [ ] No errors in logs
- [ ] All containers running
- [ ] Backup works
- [ ] SSL certificate valid

## 🎯 Quick Navigation

**Just want to install?** → [QUICK_START.md](QUICK_START.md)

**Need step-by-step?** → [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

**Want to understand?** → [ARCHITECTURE.md](ARCHITECTURE.md)

**Having problems?** → Run `diagnose.sh` → Check [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting)

**Need commands?** → [QUICK_START.md](QUICK_START.md) or [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)

---

## 📝 Document Versions

All documentation in this package is designed to work together. If you're reading one document and it references another, the information is complementary, not redundant.

**Last Updated**: December 2024

**Compatible With**:
- Numbas LTI Provider: v3.x and v4.x
- Docker: 24.x+
- Ubuntu: 20.04+, 22.04+, 24.04+
- Debian: 11+, 12+

---

**Ready to begin?** Start with [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)!

**Need help?** Run `sudo bash diagnose.sh` first!
