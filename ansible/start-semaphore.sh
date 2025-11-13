#!/bin/bash

# Ansible Semaphore Startup Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================"
echo "Ansible Semaphore - Startup Script"
echo "======================================"
echo ""

# Check if .env.semaphore exists
if [ ! -f ".env.semaphore" ]; then
    echo "⚠️  .env.semaphore not found!"
    echo ""
    echo "Creating from template..."
    cp .env.semaphore.example .env.semaphore

    # Generate random passwords
    POSTGRES_PASS=$(openssl rand -base64 24)
    ADMIN_PASS=$(openssl rand -base64 16)
    ENCRYPTION_KEY=$(openssl rand -base64 32)

    # Update .env.semaphore with generated values
    sed -i.bak "s/your_secure_postgres_password_here/$POSTGRES_PASS/" .env.semaphore
    sed -i.bak "s/your_secure_admin_password_here/$ADMIN_PASS/" .env.semaphore
    sed -i.bak "s/your-32-character-secret-key-for-encryption-here-change-this/$ENCRYPTION_KEY/" .env.semaphore
    rm .env.semaphore.bak

    echo "✅ Generated secure passwords in .env.semaphore"
    echo ""
    echo "📝 Your Semaphore Admin Credentials:"
    echo "   Username: admin"
    echo "   Password: $ADMIN_PASS"
    echo ""
    echo "⚠️  SAVE THESE CREDENTIALS - you won't see them again!"
    echo ""
    read -p "Press Enter to continue..."
fi

# Load environment variables
source .env.semaphore

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "🐳 Starting Ansible Semaphore..."
echo ""

# Start services
docker-compose -f semaphore-docker-compose.yml up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
if docker-compose -f semaphore-docker-compose.yml ps | grep -q "Up"; then
    echo ""
    echo "✅ Ansible Semaphore is running!"
    echo ""
    echo "======================================"
    echo "📊 Access Information"
    echo "======================================"
    echo "Web UI: http://localhost:3001"
    echo "Username: admin"
    echo "Password: [Check .env.semaphore file]"
    echo ""
    echo "======================================"
    echo "📚 Quick Commands"
    echo "======================================"
    echo "View logs:    docker-compose -f semaphore-docker-compose.yml logs -f"
    echo "Stop:         docker-compose -f semaphore-docker-compose.yml down"
    echo "Restart:      docker-compose -f semaphore-docker-compose.yml restart"
    echo ""
else
    echo ""
    echo "❌ Services failed to start. Check logs:"
    echo "   docker-compose -f semaphore-docker-compose.yml logs"
    exit 1
fi
