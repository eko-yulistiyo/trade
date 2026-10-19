# ARSITEKTUR DEPLOYMENT (DEPLOYMENT ARCHITECTURE)
**Dokumen:** `docs/02-architecture/DEPLOYMENT_ARCHITECTURE.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Arsitektur  

---

Dokumen ini mendefinisikan arsitektur kontainerisasi dan strategi deployment platform **AUTO-TRADE-AA**, dimulai dari lingkungan pengembangan lokal berbasis **MacBook M1 Pro (Apple Silicon)** hingga opsi migrasi terkontrol ke server **VPS Indonesia** di masa mendatang.

---

## 1. Topologi Deployment Lokal (MacBook M1 Pro Baseline)

Lingkungan operasional utama untuk MVP dijalankan sepenuhnya di dalam kontainer Docker pada host lokal operator:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    HOST MACHINE: MACBOOK PRO M1 PRO (macOS)                 │
│                          Apple Silicon (ARM64) / 16 GB RAM                  │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    DOCKER DESKTOP (ENGINE: DOCKER COMPOSE)            │  │
│  │                                                                       │  │
│  │  Bridge Network: auto_trade_net (172.28.0.0/16)                      │  │
│  │                                                                       │  │
│  │  ┌────────────────────────┐         ┌──────────────────────────────┐  │  │
│  │  │ container: frontend    │         │ container: backend           │  │  │
│  │  │ Next.js 15 (Node 20)   │ ◄─────► │ FastAPI (Python 3.11/3.12)   │  │  │
│  │  │ Port Host: 3000:3000   │         │ Port Host: 8000:8000         │  │  │
│  │  │ RAM Limit: 1.5 GB      │         │ RAM Limit: 2.5 GB            │  │  │
│  │  └────────────────────────┘         └──────────────┬───────────────┘  │  │
│  │                                                    │                  │  │
│  │                                                    ▼                  │  │
│  │  ┌────────────────────────┐         ┌──────────────────────────────┐  │  │
│  │  │ container: redis (opt) │         │ container: postgres          │  │  │
│  │  │ Redis 7 Alpine         │ ◄─────► │ PostgreSQL 16 Alpine         │  │  │
│  │  │ Port Host: 6379 (Opt)  │         │ Port Host: 5432:5432         │  │  │
│  │  │ RAM Limit: 512 MB      │         │ RAM Limit: 2.0 GB            │  │  │
│  │  └────────────────────────┘         └──────────────┬───────────────┘  │  │
│  │                                                    │                  │  │
│  └────────────────────────────────────────────────────┼──────────────────┘  │
│                                                       │ Host Mount           │
│  Persistensi Data Host:                               ▼                      │
│  └── /Users/.../AUTO-TRADE-AA/.data/postgres_data ◄───┘                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Alokasi Sumber Daya Kontainer (Resource Limits)

Untuk mencegah kontainer menghabiskan kapasitas RAM 16 GB pada host laptop, batasan sumber daya ketat (*resource limits*) diterapkan di dalam definisi Docker Compose:

| Layanan Kontainer | Base Image | Batas RAM (*Limit*) | Reservasi RAM | Batas CPU | Catatan Arsitektur |
|---|---|---|---|---|---|
| **`postgres`** | `postgres:16-alpine` | 2.0 GB | 512 MB | 2.0 Cores | Dilengkapi tuning `shared_buffers = 256MB`, `work_mem = 16MB`. |
| **`backend`** | `python:3.11-slim` (ARM64) | 2.5 GB | 1.0 GB | 4.0 Cores | Menjalankan API FastAPI, Ingestion, Hermes, dan Risk Engine. |
| **`frontend`** | `node:20-alpine` (ARM64) | 1.5 GB | 512 MB | 2.0 Cores | Menjalankan Next.js web dashboard. |
| **`redis`** *(Opsional)* | `redis:7-alpine` | 512 MB | 128 MB | 1.0 Core | Hanya diaktifkan bila antrean latar belakang memerlukan Redis. |
| **Total Maksimal** | — | **6.5 GB** | **2.15 GB** | — | Aman di bawah batas 8.0 GB (NFR-PERF-01). |

---

## 3. Isolasi Jaringan & Port Mapping

- **Internal Network:** Seluruh kontainer terhubung melalui jaringan jembatan (*user-defined bridge network*) bernama `auto_trade_net`. Komunikasi antar-kontainer menggunakan nama layanan DNS Docker internal (misal `http://backend:8000`, `postgres:5432`).
- **Eksposur Port ke Host:**
  - `localhost:3000` -> Web Dashboard (Next.js)
  - `localhost:8000` -> Backend REST API & OpenAPI Docs (`/docs`)
  - `localhost:5432` -> PostgreSQL (Hanya dibatasi akses dari localhost untuk audit manual/DBeaver)

---

## 4. Persistensi Volume Data & Keamanan Lingkungan

1. **Volume Database:** Data PostgreSQL disimpan secara permanen pada direktori lokal yang diabaikan oleh Git:  
   `./.data/postgres_data:/var/lib/postgresql/data`
2. **Pengelolaan Variabel Lingkungan:**
   - Seluruh kredensial (API keys, DB password, Telegram bot token) disimpan dalam file `.env` lokal pada root repositori.
   - File `.env` wajib dimasukkan ke dalam `.gitignore`.
   - File `.env.example` disediakan sebagai templat tanpa nilai rahasia.

---

## 5. Opsi Migrasi Terkontrol ke VPS Indonesia (Future Phase)

Migrasi ke Virtual Private Server (VPS) yang berlokasi di pusat data Indonesia bersifat **opsional** dan hanya dipertimbangkan setelah fase evaluasi paper trading lokal tuntas.

### 5.1 Kriteria Kesiapan Migrasi ke VPS
- Paper trading telah beroperasi stabil secara lokal selama minimal 2 minggu tanpa *unhandled error*.
- Rasio latency RPC lokal ke Helius/node global dinilai dapat diterima atau perlu server dengan konektivitas 24/7 tanpa bergantung pada status menyala laptop.

### 5.2 Spesifikasi Minimal Rekomendasi VPS (Data Center Indonesia / SG)
- **CPU:** 4 vCPU (KVM Virtualization, x86_64 atau ARM Ampere)
- **RAM:** Minimal 8 GB RAM (Direkomendasikan 16 GB)
- **Penyimpanan:** 80 GB SSD / NVMe
- **Sistem Operasi:** Ubuntu 24.04 LTS x86_64
- **Perkiraan Biaya:** Rp 200.000 s.d. Rp 450.000 per bulan.

### 5.3 Prosedur Migrasi Bebas Gangguan
1. Cadangkan seluruh data PostgreSQL lokal menggunakan `pg_dump`.
2. Siapkan instance VPS dengan Docker Engine, Docker Compose, dan firewall UFW ketat (hanya membuka port SSH 22 dengan otentikasi SSH Key, dan port HTTPS 443).
3. Salin repositori dan file `.env` produksi yang terkonfigurasi aman.
4. Pulihkan data basis data menggunakan `pg_restore`.
5. Pasang reverse proxy Caddy / Nginx dengan sertifikat TLS Let's Encrypt otomatis untuk mengakses dashboard secara aman melalui domain pribadi.
