#!/usr/bin/env bash
# deploy.sh — One-click Dokku deploy
# Copy this file into your project, then:
#   ./deploy.sh                    # auto domain, no SSL
#   ./deploy.sh --ssl              # auto domain + SSL
#   ./deploy.sh --domain app.example.com --ssl
#
# What it does:
#   1. Detect app name (folder name)
#   2. Create Dokku app
#   3. Set domain (auto: <app>.hayai.my.id or custom)
#   4. Setup Let's Encrypt SSL (if --ssl)
#   5. Init git + push to Dokku

set -euo pipefail

# === Config ===
DOKKU_HOST="localhost"
DOKKU_SSH_KEY="$HOME/.ssh/dokku_admin"
GLOBAL_DOMAIN="hayai.my.id"
SSL_EMAIL="admin@hayai.my.id"

# === Parse Args ===
CUSTOM_DOMAIN=""
DO_SSL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) CUSTOM_DOMAIN="$2"; shift 2 ;;
    --ssl)    DO_SSL=true; shift ;;
    --host)   DOKKU_HOST="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--domain example.com] [--ssl] [--host HOST]"
      echo ""
      echo "One-click deploy current project to Dokku."
      echo ""
      echo "Options:"
      echo "  --domain    Custom domain (default: <app>.hayai.my.id)"
      echo "  --ssl       Enable Let's Encrypt SSL"
      echo "  --host      Dokku server host (default: localhost)"
      exit 0
      ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

# === Detect App Name ===
APP_NAME=$(basename "$(pwd)")
echo "========================================"
echo "  Dokku One-Click Deploy"
echo "========================================"
echo "App:      $APP_NAME"
echo "Host:     $DOKKU_HOST"

# === Ensure Dockerfile Exists ===
if [[ ! -f Dockerfile ]]; then
  echo ""
  echo "❌ No Dockerfile found in $(pwd)"
  echo "   Create one first, e.g.:"
  echo ""
  echo "   FROM nginx:alpine"
  echo "   COPY dist/ /usr/share/nginx/html"
  exit 1
fi

# === SSH Setup ===
export GIT_SSH_COMMAND="ssh -i $DOKKU_SSH_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

# === [1/5] Create App ===
echo ""
echo "[1/5] Creating Dokku app..."
sudo dokku apps:create "$APP_NAME" 2>/dev/null && echo "  ✓ Created" || echo "  ⚠ Already exists"

# === [2/5] Set Domain ===
echo ""
echo "[2/5] Configuring domain..."
if [[ -n "$CUSTOM_DOMAIN" ]]; then
  sudo dokku domains:set "$APP_NAME" "$CUSTOM_DOMAIN"
  DOMAIN="$CUSTOM_DOMAIN"
  echo "  ✓ Domain: $DOMAIN (custom)"
else
  DOMAIN="$APP_NAME.$GLOBAL_DOMAIN"
  echo "  ✓ Domain: $DOMAIN (auto)"
fi

# === [3/5] SSL ===
echo ""
echo "[3/5] Setting up SSL..."
if $DO_SSL; then
  # Install letsencrypt plugin (idempotent, ignore if already installed)
  sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git 2>/dev/null || true
  sudo dokku letsencrypt:set "$APP_NAME" email "$SSL_EMAIL" 2>/dev/null || true
  sudo dokku letsencrypt:enable "$APP_NAME" 2>/dev/null || true
  sudo dokku letsencrypt:cron-job --add 2>/dev/null || true
  echo "  ✓ SSL enabled"
  PROTO="https"
else
  echo "  ⚠ SSL skipped (use --ssl)"
  PROTO="http"
fi

# === [4/5] Init Git ===
echo ""
echo "[4/5] Preparing git..."
if [[ ! -d .git ]]; then
  git init -q
  git add -A
  git commit -m "deploy: one-click Dokku deploy" -q
  echo "  ✓ Git initialized + committed"
else
  if ! git diff --cached --quiet 2>/dev/null || ! git diff --quiet 2>/dev/null; then
    git add -A
    git commit -m "deploy: update" -q || true
    echo "  ✓ Uncommitted changes staged"
  else
    echo "  ✓ Git up to date"
  fi
fi

# === [5/5] Push & Deploy ===
echo ""
echo "[5/5] Deploying to Dokku..."
REMOTE="dokku@${DOKKU_HOST}:${APP_NAME}"
if ! git remote get-url dokku &>/dev/null; then
  git remote add dokku "$REMOTE"
else
  git remote set-url dokku "$REMOTE"
fi

BRANCH=$(git branch --show-current)
git push dokku "$BRANCH" 2>&1 | tail -5

# === Done ===
echo ""
echo "========================================"
echo "  ✓ Deployed!"
echo "  $PROTO://$DOMAIN"
echo "========================================"
