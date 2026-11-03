#!/bin/bash
# ==============================================================================
# AUTO-TRADE-AA: Production Deployment Script (run on VPS as 'trader' user)
# ==============================================================================
set -euo pipefail

echo "=== AUTO-TRADE-AA Production Deploy ==="

# 1. Check .env exists
if [[ ! -f .env ]]; then
    echo "ERROR: .env not found. Copy .env.prod to .env and fill in all CHANGE_THIS values."
    echo "  cp .env.prod .env"
    echo "  # Edit .env with real secrets"
    exit 1
fi

# 2. Generate secrets if still placeholders
if grep -q "CHANGE_THIS" .env; then
    echo "Generating missing secrets..."
    if grep -q "JWT_SECRET_KEY=CHANGE_THIS" .env; then
        NEW_JWT=$(openssl rand -hex 32)
        sed -i "s|JWT_SECRET_KEY=CHANGE_THIS_64_HEX_CHARS|JWT_SECRET_KEY=$NEW_JWT|" .env
        echo "  Generated JWT_SECRET_KEY"
    fi
    if grep -q "FIELD_ENCRYPTION_KEY=CHANGE_THIS" .env; then
        NEW_FERNET=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
        sed -i "s|FIELD_ENCRYPTION_KEY=CHANGE_THIS_FERNET_KEY|FIELD_ENCRYPTION_KEY=$NEW_FERNET|" .env
        echo "  Generated FIELD_ENCRYPTION_KEY"
    fi
    if grep -q "BACKEND_API_SECRET=CHANGE_THIS" .env; then
        NEW_API=$(openssl rand -hex 32)
        sed -i "s|BACKEND_API_SECRET=CHANGE_THIS_TO_32_CHAR_RANDOM_STRING_MIN|BACKEND_API_SECRET=$NEW_API|" .env
        echo "  Generated BACKEND_API_SECRET"
    fi
    if grep -q "POSTGRES_PASSWORD=CHANGE_THIS" .env; then
        NEW_DB=$(openssl rand -hex 24)
        sed -i "s|POSTGRES_PASSWORD=CHANGE_THIS_TO_STRONG_PASSWORD|POSTGRES_PASSWORD=$NEW_DB|" .env
        # Also update DATABASE_URL
        sed -i "s|postgresql+asyncpg://autotrade_app:CHANGE_THIS_TO_STRONG_PASSWORD@|postgresql+asyncpg://autotrade_app:$NEW_DB@|" .env
        echo "  Generated POSTGRES_PASSWORD"
    fi
    echo "Secrets generated. Please verify .env and re-run if needed."
fi

# 3. Configure firewall (run once, needs sudo)
if [[ $EUID -eq 0 ]]; then
    echo "Running as root - configuring UFW..."
    bash deploy/ufw.sh
else
    echo "Firewall setup requires sudo. Run once manually: sudo bash deploy/ufw.sh"
fi

# 4. Setup Nginx (run once, needs sudo)
if [[ -f /etc/nginx/sites-available/autotrade.conf ]]; then
    echo "Nginx config already exists."
else
    echo "Nginx config not found. Run once manually:"
    echo "  sudo cp deploy/nginx/autotrade.conf /etc/nginx/sites-available/autotrade.conf"
    echo "  sudo ln -sf /etc/nginx/sites-available/autotrade.conf /etc/nginx/sites-enabled/"
    echo "  sudo nginx -t && sudo systemctl reload nginx"
fi

# 5. Deploy stack
echo "=== Building & Starting Production Stack ==="
docker compose -f docker-compose.prod.yml up -d --build

# 6. Wait for health
echo "Waiting for services to be healthy..."
sleep 10

# 7. Verify
echo "=== Verification ==="
docker compose -f docker-compose.prod.yml ps
echo ""
curl -s http://localhost:8000/api/v1/health | jq . 2>/dev/null || curl -s http://localhost:8000/api/v1/health

echo ""
echo "=== Next Steps (manual) ==="
echo "1. Configure DNS A-record: trade.your-domain.com -> VPS IP"
echo "2. Get TLS cert: sudo certbot --nginx -d trade.your-domain.com"
echo "3. Verify dashboard: https://trade.your-domain.com"
echo "4. Test Telegram /kill switch"
echo ""
echo "Logs: docker compose -f docker-compose.prod.yml logs -f"