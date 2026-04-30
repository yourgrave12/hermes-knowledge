# Dokku Deployment Guide

Panduan deploy aplikasi ke Dokku (self-hosted PaaS) — dari setup sampai SSL otomatis.

## Prasyarat

- Dokku terinstall di server
- Domain wildcard A record mengarah ke server IP
- SSH key sudah terdaftar (`sudo dokku ssh-keys:add`)

## Setup Awal

```bash
# Set global domain (sekali saja)
sudo dokku domains:set-global hayai.my.id

# Tambah SSH key
cat ~/.ssh/id_ed25519.pub | sudo dokku ssh-keys:add admin
```

## Bikin App Baru (Quick)

### Pakai Script

```bash
# Auto domain (app-name.hayai.my.id) + SSL
./dokku/app-create.sh my-app --ssl admin@hayai.my.id

# Custom domain + SSL
./dokku/app-create.sh my-app --domain app.hayai.my.id --ssl admin@hayai.my.id

# Tanpa SSL (HTTP doang)
./dokku/app-create.sh my-app
```

### Manual

```bash
# 1. Create
sudo dokku apps:create my-app

# 2. Custom domain (opsional)
sudo dokku domains:set my-app app.hayai.my.id

# 3. SSL
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
sudo dokku letsencrypt:set my-app email admin@hayai.my.id
sudo dokku letsencrypt:enable my-app
sudo dokku letsencrypt:cron-job --add
```

## Deploy Aplikasi

### Dockerfile (rekomendasi)

Contoh untuk Vite + Svelte:

```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Push ke Dokku

```bash
cd project/
git init && git add -A && git commit -m "init"
git remote add dokku dokku@<server-ip>:my-app
git push dokku main
```

## Perintah Penting

| Action | Command |
|--------|---------|
| List apps | `sudo dokku apps:list` |
| Logs | `sudo dokku logs <app>` |
| Set env | `sudo dokku config:set <app> KEY=value` |
| Run command | `sudo dokku run <app> <cmd>` |
| Restart | `sudo dokku ps:restart <app>` |
| Destroy app | `sudo dokku apps:destroy <app>` |
| Check status | `sudo dokku ps:report <app>` |

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `Permission denied (publickey)` | Tambah SSH key: `cat ~/.ssh/key.pub \| sudo dokku ssh-keys:add admin` |
| `Host key verification failed` | `ssh-keyscan -H <ip> >> ~/.ssh/known_hosts` |
| SSL gagal | Pastikan DNS sudah mengarah ke server & port 80 terbuka |
| Build timeout | Tambah timeout: `sudo dokku config:set <app> DOKKU_DOCKER_BUILD_TIMEOUT=600` |
