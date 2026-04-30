# Discord Response No Limit

Setting agar response tools di Discord tidak terpotong / truncated.

## Masalah

Default Hermes di Discord:
- Tool preview cuma **40 karakter** → `💻 terminal: "ls -la /some/ver..."`
- Format raw JSON → `["command", "timeout", "workdir"]` (susah dibaca)

## Solusi

### 1. Format Bersih + No Truncation

```bash
hermes config set display.tool_progress all
hermes config set display.tool_preview_length 500
```

**Penjelasan:**
- `tool_progress: all` → format bersih (`💻 terminal: "ls -la /path"`) bukan raw JSON
- `tool_preview_length: 500` → bypass cap 40 karakter bawaan gateway. Nilai `0` yang harusnya "no limit" tetap kena truncate di level gateway, jadi pakai angka besar eksplisit.

### 2. Hasil di Discord

```
💻 terminal: "cd ~/projects/web/your-grave && npm run build -- --verbose"
📖 read_file: "/home/ubuntu/projects/web/your-grave/src/routes/+page.svelte"
```

### 3. Restart Diperlukan

Setelah set config, restart gateway:
```bash
hermes gateway restart
```

## Lokasi Config

Semua setting ada di `~/.hermes/config.yaml`:
```yaml
display:
  tool_progress: all
  tool_preview_length: 500
```

## Catatan

- `tool_progress_command: false` → jangan tampilkan full command (biar preview doang)
- Setting ini per-profile, pastikan profile yang aktif
