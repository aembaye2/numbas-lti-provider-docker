#!/bin/bash

# Diagnostic script for Numbas LTI Provider
# Run this script to check your deployment health

echo "================================================"
echo "Numbas LTI Provider - Diagnostic Tool"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "1. System Requirements"
echo "--------------------"

# Check RAM
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -ge 2 ]; then
    check_pass "RAM: ${TOTAL_RAM}GB (adequate)"
else
    check_warn "RAM: ${TOTAL_RAM}GB (minimum 2GB recommended)"
fi

# Check disk space
DISK_FREE=$(df -h / | awk 'NR==2 {print $4}')
check_pass "Free disk space: $DISK_FREE"

# Check CPU cores
CPU_CORES=$(nproc)
if [ "$CPU_CORES" -ge 2 ]; then
    check_pass "CPU cores: $CPU_CORES"
else
    check_warn "CPU cores: $CPU_CORES (minimum 2 recommended)"
fi

echo ""
echo "2. Docker Installation"
echo "--------------------"

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    check_pass "Docker installed: $DOCKER_VERSION"
else
    check_fail "Docker not installed"
fi

if command -v docker compose &> /dev/null; then
    check_pass "Docker Compose installed"
else
    check_fail "Docker Compose not installed"
fi

echo ""
echo "3. Configuration Files"
echo "--------------------"

if [ -f "settings.env" ]; then
    check_pass "settings.env exists"
    
    # Check if SECRET_KEY is set
    if grep -q "SECRET_KEY=REPLACE_THIS_WITH_GENERATED_SECRET_KEY" settings.env 2>/dev/null; then
        check_fail "SECRET_KEY not generated yet"
    elif grep -q "SECRET_KEY=$" settings.env 2>/dev/null; then
        check_fail "SECRET_KEY is empty"
    else
        check_pass "SECRET_KEY is configured"
    fi
    
    # Check SERVERNAME
    if grep -q "SERVERNAME=numbas.yourdomain.com" settings.env 2>/dev/null; then
        check_warn "SERVERNAME still has default value"
    else
        SERVERNAME=$(grep "^SERVERNAME=" settings.env | cut -d'=' -f2)
        check_pass "SERVERNAME configured: $SERVERNAME"
    fi
    
    # Check passwords
    if grep -q "SUPERUSER_PASSWORD=ChangeThisStrongPassword" settings.env 2>/dev/null; then
        check_fail "Admin password still has default value - SECURITY RISK!"
    else
        check_pass "Admin password has been changed"
    fi
    
else
    check_fail "settings.env not found"
fi

if [ -f "docker-compose.yml" ]; then
    check_pass "docker-compose.yml exists"
else
    check_fail "docker-compose.yml not found"
fi

echo ""
echo "4. SSL Certificates"
echo "--------------------"

if [ -f "files/ssl/numbas-lti.pem" ]; then
    check_pass "SSL certificate exists"
    
    # Check expiration
    EXPIRY=$(openssl x509 -enddate -noout -in files/ssl/numbas-lti.pem | cut -d'=' -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || echo 0)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
    
    if [ "$DAYS_LEFT" -gt 30 ]; then
        check_pass "Certificate expires in $DAYS_LEFT days"
    elif [ "$DAYS_LEFT" -gt 0 ]; then
        check_warn "Certificate expires in $DAYS_LEFT days - renew soon!"
    else
        check_fail "Certificate has expired!"
    fi
else
    check_fail "SSL certificate not found"
fi

if [ -f "files/ssl/numbas-lti.key" ]; then
    check_pass "SSL key exists"
    
    # Check permissions
    PERMS=$(stat -c %a files/ssl/numbas-lti.key 2>/dev/null || echo "unknown")
    if [ "$PERMS" = "600" ]; then
        check_pass "SSL key has correct permissions (600)"
    else
        check_warn "SSL key permissions: $PERMS (should be 600)"
    fi
else
    check_fail "SSL key not found"
fi

echo ""
echo "5. Docker Containers"
echo "--------------------"

if docker compose ps &> /dev/null; then
    
    # Check nginx
    if docker compose ps nginx | grep -q "Up"; then
        check_pass "nginx is running"
    else
        check_fail "nginx is not running"
    fi
    
    # Check postgres
    if docker compose ps postgres | grep -q "Up"; then
        check_pass "postgres is running"
        
        # Check database connection
        if docker compose exec -T postgres pg_isready -U postgres &> /dev/null; then
            check_pass "Database is accepting connections"
        else
            check_fail "Database is not accepting connections"
        fi
    else
        check_fail "postgres is not running"
    fi
    
    # Check redis
    if docker compose ps redis | grep -q "Up"; then
        check_pass "redis is running"
    else
        check_fail "redis is not running"
    fi
    
    # Check daphne
    DAPHNE_COUNT=$(docker compose ps daphne | grep -c "Up" || echo 0)
    if [ "$DAPHNE_COUNT" -gt 0 ]; then
        check_pass "daphne running ($DAPHNE_COUNT instances)"
    else
        check_fail "daphne is not running"
    fi
    
    # Check huey
    HUEY_COUNT=$(docker compose ps huey | grep -c "Up" || echo 0)
    if [ "$HUEY_COUNT" -gt 0 ]; then
        check_pass "huey running ($HUEY_COUNT instances)"
    else
        check_fail "huey is not running"
    fi
    
else
    check_warn "Docker containers not started yet"
fi

echo ""
echo "6. Network & Firewall"
echo "--------------------"

# Check if port 443 is listening
if netstat -tuln 2>/dev/null | grep -q ":443 " || ss -tuln 2>/dev/null | grep -q ":443 "; then
    check_pass "Port 443 (HTTPS) is listening"
else
    check_fail "Port 443 (HTTPS) is not listening"
fi

# Check firewall
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        check_pass "UFW firewall is active"
        
        if ufw status | grep -q "443.*ALLOW"; then
            check_pass "Port 443 allowed in firewall"
        else
            check_fail "Port 443 not allowed in firewall"
        fi
    else
        check_warn "UFW firewall is not active"
    fi
else
    check_warn "UFW not installed (check firewall manually)"
fi

# Test DNS resolution (if SERVERNAME is set)
if [ -f "settings.env" ]; then
    SERVERNAME=$(grep "^SERVERNAME=" settings.env | cut -d'=' -f2)
    if [ ! -z "$SERVERNAME" ] && [ "$SERVERNAME" != "numbas.yourdomain.com" ]; then
        if nslookup "$SERVERNAME" &> /dev/null || host "$SERVERNAME" &> /dev/null; then
            check_pass "DNS resolves for $SERVERNAME"
        else
            check_fail "DNS does not resolve for $SERVERNAME"
        fi
    fi
fi

echo ""
echo "7. Log Analysis"
echo "--------------------"

if docker compose ps &> /dev/null; then
    # Check for recent errors
    ERROR_COUNT=$(docker compose logs --tail=100 2>&1 | grep -i "error" | wc -l)
    if [ "$ERROR_COUNT" -eq 0 ]; then
        check_pass "No errors in recent logs"
    else
        check_warn "$ERROR_COUNT errors found in recent logs"
    fi
fi

echo ""
echo "8. Disk Usage"
echo "--------------------"

# Check Docker disk usage
if command -v docker &> /dev/null; then
    DOCKER_DISK=$(docker system df 2>/dev/null | grep "Total" | awk '{print $4}' || echo "unknown")
    echo "Docker disk usage: $DOCKER_DISK"
fi

# Check volume sizes
echo "Volume sizes:"
docker volume ls -q | grep numbas | while read vol; do
    SIZE=$(docker system df -v 2>/dev/null | grep "$vol" | awk '{print $3}' || echo "unknown")
    echo "  - $vol: $SIZE"
done

echo ""
echo "================================================"
echo "Diagnostic Summary"
echo "================================================"
echo ""

# Overall recommendation
CRITICAL_ISSUES=0

# Count critical issues
[ ! -f "settings.env" ] && CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
[ ! -f "files/ssl/numbas-lti.pem" ] && CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
grep -q "SECRET_KEY=REPLACE_THIS_WITH_GENERATED_SECRET_KEY" settings.env 2>/dev/null && CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
! docker compose ps postgres 2>/dev/null | grep -q "Up" && CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))

if [ "$CRITICAL_ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✓ System appears healthy!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Access your instance at https://$(grep "^SERVERNAME=" settings.env 2>/dev/null | cut -d'=' -f2)"
    echo "2. Log in with your admin credentials"
    echo "3. Review any warnings above"
else
    echo -e "${RED}✗ Found $CRITICAL_ISSUES critical issue(s)${NC}"
    echo ""
    echo "Please fix the errors above before proceeding."
    echo ""
    echo "Quick fixes:"
    echo "- Missing settings.env: cp settings.env.dist settings.env"
    echo "- Missing SSL cert: See DEPLOYMENT_GUIDE.md Section 4"
    echo "- Missing SECRET_KEY: docker compose run --rm numbas-setup python ./get_secret_key"
    echo "- Containers not running: docker compose up -d --scale daphne=4 --scale huey=1"
fi

echo ""
echo "For more help, see:"
echo "  - DEPLOYMENT_GUIDE.md"
echo "  - QUICK_START.md"
echo "  - docker compose logs -f"
echo ""
