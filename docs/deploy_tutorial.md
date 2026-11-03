# Tutorial Deploy AUTO-TRADE-AA

> Repo: `eko-yulistiyo/trade` (clone dari `garryaf/BotTradingCrypto`) — commit `75bbf5f`
> Verifikasi: `docker-compose.yml` + `docker-compose.prod.yml` + `deploy/` valid

---

## 1. Struktur & File Kunci (Terverifikasi)

| File | Fungsi | Status |
|---|---|---|
| `docker-compose.yml` | Dev (postgres `5432`, backend `8000`, frontend `3000`) | ✅ Ada |
| `docker-compose.prod.yml` | Prod (bind `127.0.0.1`, `restart: always`, `internal_net`) | ✅ Ada |
| `.env.example` | Template env (DB, AI key, Telegram, Safety Lock) | ✅ Ada |
| `backend/Dockerfile` | Python 3.12 + Alembic + uvicorn | ✅ Ada |
| `frontend/Dockerfile` | Multi-stage Next.js 15 | ✅ Ada |
| `engine/Dockerfile` | Rust 1.97 build → `debian:trixie-slim` binary | ✅ Ada |
| `deploy/nginx/autotrade.conf` | Reverse proxy `api/` → 8000, `/` → 3000 | ✅ Ada |
| `deploy/ufw.sh` | Firewall (SSH/80/443 publik; 5432/8000 internal) | ✅ Ada |
| `deploy/` | Konfigurasi produksi | ✅ Lengkap |

---

## 2. Deploy Lokal (Development)

### Prasyarat
- Docker Desktop 24.x+ (RAM ≥ 4 GB)
- OS: macOS / Linux / Windows 11 (WSL2)
- Git 2.x+

### Langkah

```bash
# 1. Clone
git clone https://github.com/eko-yulistiyo/trade.git
cd trade

# 2. Konfigurasi env
cp .env.example .env
# Edit .env: POSTGRES_PASSWORD, BACKEND_API_SECRET (≥32 char), LIVE_TRADING_ENABLED=false

# 3. Build & jalankan (postgres + backend + frontend)
docker compose up -d --build
```

**Verifikasi otomatis:**
```bash
curl -s http://localhost:8000/api/v1/health | head -c 200
echo "---"
docker compose logs backend --tail 20
docker compose ps
```

**Status yang diharapkan:** `postgres` healthy → `backend` running (`alembic upgrade head` otomatis) → `frontend` running. `tasks` di `/api/v1/health`: `binance_ingestion`/`risk_engine` `running`; `hermes` mungkin `exited` (aman — idle jika API key kosong).

---

## 3. Deploy Produksi (VPS Ubuntu)

### Spesifikasi Minimum
| Komponen | Minimum |
|---|---|
| OS | Ubuntu 22.04/24.04 LTS x86_64 |
| CPU | 2 vCPU |
| RAM | 4 GB (8 GB disarankan) |
| Disk | 40 GB NVMe |
| Domain | A-Record ke IP publik (mis. `trade.domainanda.com`) |

### Langkah Produksi

```bash
# SSH & update
ssh root@<IP_VPS>
apt-get update && apt-get upgrade -y
apt-get install -y git curl ufw certbot python3-certbot-nginx nginx

# User operasional (bukan root)
adduser trader
usermod -aG sudo trader
su - trader

# Clone repo
cd ~
git clone https://github.com/eko-yulistiyo/trade.git
cd trade

# Konfigurasi .env (salin dari .env.example, isi DB password, secret, Telegram token jika diperlukan)
cp .env.example .env
# EDIT .env sesuai kebutuhan produksi

# Firewall (hanya SSH/HTTP/HTTPS publik; DB/backend internal)
bash deploy/ufw.sh

# Jalankan stack produksi
docker compose -f docker-compose.prod.yml up -d --build
```

**Verifikasi produksi:**
```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs --tail 30
curl -s http://localhost:8000/api/v1/health
```

**Nginx (jika domain aktif):**
```bash
sudo cp deploy/nginx/autotrade.conf /etc/nginx/sites-available/autotrade.conf
sudo ln -sf /etc/nginx/sites-available/autotrade.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# TLS (Certbot)
sudo certbot --nginx -d trade.domainanda.com
```

**Port & akses:**
- Publik: `80`/`443` (Nginx)
- Internal: `5432` (DB), `8000` (API) — bind `127.0.0.1` (tidak ekspos ke publik)
- Frontend: `3000` (melalui Nginx proxy)

---

## 4. Opsi Rust Risk Gate (Opsional)

Default: **nonaktif** (`ENGINE_URL=` kosong) — Risk Gate 9 pintu berjalan di Python (`backend/src/risk/gate.py`).

Aktifkan hanya jika diperlukan:
```bash
# 1. Edit .env
ENGINE_URL=http://engine:8080
ENGINE_TIMEOUT_MS=10

# 2. Jalankan dengan profile engine
docker compose --profile engine up -d --build
```
Port `8080` hanya internal Docker (`expose`, tidak `ports` publik). Backend akan memanggil `POST /evaluate` secara fail-closed: jika engine tidak merespons dalam `ENGINE_TIMEOUT_MS`, order otomatis ditolak.

---

## 5. Verifikasi & Keamanan

| Pemeriksaan | Perintah / File | Bukti |
|---|---|---|
| DB migrasi otomatis | `docker compose logs backend` (carilah `alembic upgrade head`) | ✅ Ada di `backend/Dockerfile` |
| Safety lock | `.env` — `LIVE_TRADING_ENABLED=false` | ✅ Default terkunci |
| Firewall produksi | `deploy/ufw.sh` — hanya `22/80/443` publik | ✅ Verifikasi `ufw status verbose` |
| Nginx proxy | `deploy/nginx/autotrade.conf` — `proxy_pass` ke `127.0.0.1:8000/3000` | ✅ Konfigurasi lengkap |
| Paper trading | `LIVE_TRADING_ENABLED=false` + `assert_paper_mode()` di `execution/` | ✅ Kode terkunci |

---

## 6. Mematikan / Reset

```bash
# Hentikan (data DB tetap)
docker compose down

# Reset bersih (hapus DB + container)
docker compose down -v
rm -rf .data/
```

---
*Tutorial ini dibangun dari file aktual repo (`docker-compose.yml`, `docker-compose.prod.yml`, `.env.example`, `deploy/`, `README.md`, `backend/Dockerfile`, `engine/Dockerfile`). Semua perintah diverifikasi terhadap struktur file yang ada di commit `75bbf5f`.*
