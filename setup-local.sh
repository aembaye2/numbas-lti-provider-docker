#!/bin/bash

# Local deployment script for Numbas LTI Provider
# For use in GitHub Codespaces or local Docker environment

set -e

echo "================================================"
echo "Numbas LTI Provider - Local Setup"
echo "================================================"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

echo "✓ Docker is available"
echo ""

# Step 1: Generate SSL Certificate
echo "Step 1: Generating Self-Signed SSL Certificate"
echo "--------------------"

mkdir -p files/ssl

if [ -f "files/ssl/numbas-lti.pem" ] && [ -f "files/ssl/numbas-lti.key" ]; then
    echo "✓ SSL certificates already exist"
else
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout files/ssl/numbas-lti.key \
      -out files/ssl/numbas-lti.pem \
      -subj "/C=US/ST=State/L=City/O=Dev/CN=localhost" \
      2>/dev/null
    
    chmod 644 files/ssl/numbas-lti.pem
    chmod 600 files/ssl/numbas-lti.key
    echo "✓ Self-signed SSL certificates generated"
fi

echo ""

# Step 2: Check configuration
echo "Step 2: Checking Configuration"
echo "--------------------"

if [ -f "settings.env" ]; then
    echo "✓ settings.env exists"
    
    # Check if SECRET_KEY needs to be generated
    if grep -q "SECRET_KEY=REPLACE_THIS_WITH_GENERATED_SECRET_KEY" settings.env 2>/dev/null || \
       grep -q "SECRET_KEY=$" settings.env 2>/dev/null; then
        NEED_SECRET_KEY=true
    else
        NEED_SECRET_KEY=false
        echo "✓ SECRET_KEY is already configured"
    fi
else
    echo "❌ settings.env not found"
    exit 1
fi

echo ""

# Step 3: Build Docker Image
echo "Step 3: Building Docker Image"
echo "--------------------"

docker build . -t numbas/numbas-lti-provider
echo "✓ Docker image built successfully"

echo ""

# Step 4: Generate Secret Key if needed
if [ "$NEED_SECRET_KEY" = true ]; then
    echo "Step 4: Generating Secret Key"
    echo "--------------------"
    
    echo "Generating Django secret key..."
    SECRET_KEY=$(docker compose run --rm numbas-setup python ./get_secret_key 2>/dev/null | grep -v "Creating" | grep -v "Removing" | tail -1)
    
    if [ ! -z "$SECRET_KEY" ]; then
        # Escape special characters for sed
        ESCAPED_KEY=$(echo "$SECRET_KEY" | sed 's/[\/&]/\\&/g')
        sed -i "s/SECRET_KEY=REPLACE_THIS_WITH_GENERATED_SECRET_KEY/SECRET_KEY=$ESCAPED_KEY/" settings.env
        sed -i "s/SECRET_KEY=$/SECRET_KEY=$ESCAPED_KEY/" settings.env
        echo "✓ Secret key generated and saved"
    else
        echo "⚠ Could not generate secret key automatically"
        echo "Please run: docker compose run --rm numbas-setup python ./get_secret_key"
        echo "And add the result to settings.env manually"
    fi
else
    echo "Step 4: Secret Key"
    echo "--------------------"
    echo "✓ Secret key already configured (skipping)"
fi

echo ""

# Step 5: Initialize Database
echo "Step 5: Initializing Database"
echo "--------------------"

echo "Running installation script..."
docker compose run --rm numbas-setup python ./install
echo "✓ Database initialized"

echo ""

# Step 6: Start Services
echo "Step 6: Starting Services"
echo "--------------------"

docker compose up -d --scale daphne=2 --scale huey=1
echo "✓ Services started"

echo ""

# Wait a moment for services to start
echo "Waiting for services to be ready..."
sleep 5

echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""

# Get admin credentials
ADMIN_USER=$(grep "^SUPERUSER_USER=" settings.env | cut -d'=' -f2)
ADMIN_PASS=$(grep "^SUPERUSER_PASSWORD=" settings.env | cut -d'=' -f2)

echo "Your Numbas LTI Provider is now running!"
echo ""

# Check if in Codespaces
if [ ! -z "$CODESPACE_NAME" ]; then
    echo "🌐 Access URL:"
    echo "   Look in the 'Ports' tab below and find port 443"
    echo "   Click the globe icon to open in browser"
    echo "   Or visit: https://$CODESPACE_NAME-443.app.github.dev"
    echo ""
else
    echo "🌐 Access URL:"
    echo "   https://localhost"
    echo "   (You'll see a security warning - this is normal for self-signed certificates)"
    echo ""
fi

echo "🔐 Login Credentials:"
echo "   Username: $ADMIN_USER"
echo "   Password: $ADMIN_PASS"
echo ""

echo "⚠️  Important: Change your password after first login!"
echo ""

echo "📋 Useful Commands:"
echo "   View logs:     docker compose logs -f"
echo "   Check status:  docker compose ps"
echo "   Stop services: docker compose down"
echo "   Restart:       docker compose restart"
echo ""

echo "📖 Documentation:"
echo "   Local guide:   LOCAL_DEPLOYMENT.md"
echo "   Full guide:    DEPLOYMENT_GUIDE.md"
echo "   Quick ref:     QUICK_START.md"
echo ""

echo "🔍 Run diagnostics:"
echo "   sudo bash diagnose.sh"
echo ""

echo "================================================"
echo "Happy testing! 🎉"
echo "================================================"
