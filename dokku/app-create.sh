#!/usr/bin/env bash
# dokku-app-create — Create a new Dokku app with optional domain + auto SSL
# Usage: ./dokku-app-create.sh <app-name> [--domain example.com] [--ssl email@example.com]

set -euo pipefail

APP_NAME=""
CUSTOM_DOMAIN=""
SSL_EMAIL=""

# --- Parse Args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)
      CUSTOM_DOMAIN="$2"; shift 2 ;;
    --ssl)
      SSL_EMAIL="$2"; shift 2 ;;
    -*)
      echo "Unknown flag: $1"; exit 1 ;;
    *)
      if [[ -z "$APP_NAME" ]]; then
        APP_NAME="$1"; shift
      else
        echo "Unexpected arg: $1"; exit 1
      fi
      ;;
  esac
done

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: $0 <app-name> [--domain example.com] [--ssl email@example.com]"
  echo ""
  echo "Examples:"
  echo "  $0 my-app                                    # Auto domain: my-app.<global-domain>"
  echo "  $0 my-app --domain my-app.example.com        # Custom domain"
  echo "  $0 my-app --ssl admin@example.com            # Auto domain + SSL"
  echo "  $0 my-app --domain app.com --ssl a@b.com     # Custom domain + SSL"
  exit 1
fi

echo "========================================"
echo "  Dokku App Creator"
echo "========================================"
echo "App:    $APP_NAME"

# --- Create App ---
echo ""
echo "[1/4] Creating app..."
sudo dokku apps:create "$APP_NAME"

# --- Set Domain ---
echo ""
echo "[2/4] Configuring domain..."
if [[ -n "$CUSTOM_DOMAIN" ]]; then
  sudo dokku domains:set "$APP_NAME" "$CUSTOM_DOMAIN"
  DOMAIN="$CUSTOM_DOMAIN"
  echo "  ✓ Custom domain: $DOMAIN"
else
  # Get the auto-generated domain
  DOMAIN=$(sudo dokku domains:report "$APP_NAME" | grep "Domains app vhosts:" | awk '{print $NF}')
  echo "  ✓ Auto domain: $DOMAIN"
fi

# --- SSL (Let's Encrypt) ---
echo ""
echo "[3/4] Setting up SSL..."
if [[ -n "$SSL_EMAIL" ]]; then
  # Install letsencrypt plugin if not present
  sudo dokku plugin:list 2>/dev/null | grep -q letsencrypt || \
    sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

  sudo dokku letsencrypt:set "$APP_NAME" email "$SSL_EMAIL"
  sudo dokku letsencrypt:enable "$APP_NAME"
  sudo dokku letsencrypt:cron-job --add
  echo "  ✓ SSL enabled for $DOMAIN"
  PROTO="https"
else
  echo "  ⚠ SSL skipped (use --ssl email@example.com)"
  PROTO="http"
fi

# --- Summary ---
echo ""
echo "[4/4] Done!"
echo "========================================"
echo "  App:     $APP_NAME"
echo "  URL:     $PROTO://$DOMAIN"
echo "========================================"
echo ""
echo "Next steps:"
echo "  git remote add dokku dokku@<server>:$APP_NAME"
echo "  git push dokku main"
