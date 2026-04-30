# Hermes Knowledge

Kumpulan konfigurasi, tips, dan trik Hermes Agent + Dokku deployment.

## Isi

### Discord
- [Response No Limit](discord/response-no-limit.md) — Setting agar response tools Discord tidak terpotong

### Dokku
- **[deploy.sh](dokku/deploy.sh)** — One-click deploy: copy ke project, `./deploy.sh`, beres
  - SSL ON by default → `--no-ssl` untuk matikan
  - Auto domain `<app>.hayai.my.id` → `--domain` untuk custom
  - Override nama app → `--name my-app-v2`
  - Deteksi collision: warning + konfirmasi kalau app udah ada
- [app-create.sh](dokku/app-create.sh) — Bikin app + domain + SSL (tanpa deploy)
- [Deployment Guide](dokku/deployment-guide.md) — Panduan lengkap deploy ke Dokku
