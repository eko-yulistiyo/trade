# ARSITEKTUR KOMPONEN (COMPONENT ARCHITECTURE)
**Dokumen:** `docs/02-architecture/COMPONENT_ARCHITECTURE.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Arsitektur  

---

Dokumen ini menguraikan struktur dekomposisi komponen internal platform **AUTO-TRADE-AA** dalam arsitektur **Modular Monolith**. Sistem dibagi ke dalam 7 lapisan fungsional dengan dependensi satu arah yang teratur (*unidirectional dependencies*).

---

## 1. Diagram Arsitektur Lapisan Komponen

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. CONTROL & API LAYER                                                      │
│    ├── FastAPI Router (/api/v1/wallets, /signals, /positions, /portfolio)   │
│    ├── Telegram Bot Controller (Command Handler & Notification Dispatcher)  │
│    └── Auth & API Key Middleware                                            │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Menerima perintah / Meminta data
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. ORCHESTRATION LAYER (Hermes Multi-Agent Workflow)                        │
│    ├── Hermes Workflow Orchestrator (State Graph & Task Dispatcher)         │
│    ├── Token Safety Agent (Evaluasi Mint/Freeze & Konsentrasi Suplai)       │
│    ├── Market Context Agent (Analisis Likuiditas & Volatilitas)             │
│    └── Strategy Signal Agent (Sintesis Sinyal Beli/Jual Terstruktur)        │
└───────────────────┬─────────────────────────────────────▲───────────────────┘
                    │ Meminta Inferensi AI                │ Data Konteks Bersih
                    ▼                                     │
┌───────────────────────────────────────────┐ ┌───────────┴───────────────────┐
│ 3. AI & MODEL GATEWAY LAYER               │ │ 5. INGESTION & DATA LAYER     │
│    ├── Gateway Manager (Routing & Quota)  │ │    ├── Solana RPC Poller      │
│    ├── OpenRouter Adapter (Primary)       │ │    ├── Solana WebSocket Client│
│    ├── 9Route Adapter (Fallback)          │ │    ├── Swap Instruction Parser│
│    └── JSON Schema & Pydantic Validator   │ │    └── Deduplicator (Sig Hash)│
└───────────────────────────────────────────┘ └───────────────────────────────┘
                                                          │
                                                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 4. DOMAIN & TRADING ENGINE LAYER (High-Performance Engine in Rust)          │
│    ├── Deterministic Risk Gate (Sub-ms Rule Engine: 0.5% Risk, 2% Loss, 8% DD│
│    ├── Strategy Engine & Versioning (Trend Following, Breakout, Mean Reversion
│    ├── Paper Broker Matching (Slippage Model, Bybit Fee, Partial Fill Sim)  │
│    └── Compounding & Position State Manager (Memory-speed High-Water Mark)  │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Persistensi State & Transaksi
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 5. INGESTION & DATA LAYER (High-Throughput in Rust)                         │
│    ├── Bybit Spot WebSocket & REST Connector                                │
│    ├── Solana RPC / Geyser WebSocket Client                                 │
│    ├── Swap Instruction Parser (Raydium / Orca / Jupiter)                   │
│    └── Deduplicator (Base58 Signature Hash)                                 │
└──────────────────────────────────────┬──────────────────────────────────────┘
│    ├── PostgreSQL Repositories (Wallets, Signals, Orders, Trades, Portfolio)│
│    ├── SQLAlchemy / SQLModel ORM Data Access Objects                        │
│    └── Alembic Migration Engine                                             │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 7. OBSERVABILITY & SAFETY LAYER                                             │
│    ├── Structured JSON Audit Logger (Pencatatan Request LLM & Evaluasi RSK) │
│    ├── System State & Emergency Kill Switch Controller                      │
│    └── Provider Health & Data Freshness Monitor                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Rincian Tanggung Jawab Tiap Lapisan Komponen

### Lapisan 1: Control & API Layer
- **FastAPI Router:** Menyediakan antarmuka REST API JSON untuk konsumsi antarmuka pengguna web Next.js. Mengelola pagination, filtering data riwayat, dan penerimaan aksi manual operator.
- **Telegram Bot Controller:** Menjalankan klien polling bot Telegram, memfilter chat ID berdasarkan allowlist, dan memetakan perintah kontrol (`/status`, `/pause`, `/kill`).
- **Auth & API Key Middleware:** Memastikan komunikasi antara dashboard dan backend API dilindungi oleh token Bearer rahasia statis.

### Lapisan 2: Orchestration Layer (Hermes Multi-Agent)
- **Hermes Workflow Orchestrator:** Mengarahkan aliran data analitik antar-agen. Mengatur giliran eksekusi agen secara serial atau paralel bergantung pada ketersediaan data.
- **Token Safety Agent:** Memeriksa risiko eksploitasi smart contract token di Solana (status kewenangan minting dan pembekuan akun).
- **Market Context Agent:** Menghitung rasio likuiditas pool terhadap volume perdagangan untuk mengidentifikasi apakah kondisi pasar sedang likuid atau kering.
- **Strategy Signal Agent:** Menggabungkan rekomendasi teknis menjadi objek sinyal standar dengan derajat keyakinan (*confidence score*).

### Lapisan 3: AI & Model Gateway Layer
- **Gateway Manager:** Mengelola alokasi kuota token harian, mencatat latensi provider, dan mengelola logika retry dengan backoff.
- **OpenRouter & 9Route Adapters:** Lapisan abstraksi klien HTTP yang menyamakan format request/response menuju format standar antarmuka chat completion.
- **Pydantic Schema Validator:** Memastikan respons LLM diuraikan ke dalam class data Python yang valid. Menolak respons jika field wajib hilang atau tipe data salah.

### Lapisan 4: Domain & Trading Engine Layer
- **Deterministic Risk Engine:** Modul terisolasi yang mengevaluasi sinyal terhadap batas risiko numerik absolut. Merupakan otoritas mutlak penentu apakah suatu sinyal diizinkan diteruskan ke eksekusi.
- **Strategy Engine:** Menyimpan logika strategi trading dan nomor versinya (misal: `copy_trade_v1.0`, `breakout_v1.1`) untuk auditabilitas performa.
- **Paper Broker Simulator:** Mensimulasikan bursa virtual. Menggunakan model *slippage* dinamis berbasis ukuran order vs. kedalaman likuiditas pool AMM dan menambahkan biaya gas Solana realistis.
- **Accounting Engine:** Mengelola saldo kas virtual dan saldo token virtual menggunakan prinsip pembukuan ganda (*double-entry balancing*). Menghitung PnL secara akurat menggunakan metode FIFO (*First-In, First-Out*).

### Lapisan 5: Ingestion & Data Layer
- **Solana RPC Poller & WebSocket Client:** Mengumpulkan signature transaksi baru dan memantau akun wallet yang terdaftar.
- **Swap Instruction Parser:** Membedah instruksi program Solana DEX (Raydium, Orca, Jupiter) untuk mengekstrak token yang dibeli/dijual serta harganya.
- **Deduplicator:** Memastikan setiap signature transaksi on-chain hanya diproses sekali dengan memanfaatkan indeks unik hash transaksi.

### Lapisan 6: Persistence Layer
- **PostgreSQL Repositories:** Menyediakan antarmuka repositori terisolasi untuk operasi CRUD dan query analitik basis data.
- **Alembic Migration Engine:** Mengelola evolusi skema tabel basis data secara terkontrol dan dapat dilacak (*version-controlled migrations*).

### Lapisan 7: Observability & Safety Layer
- **Structured Audit Logger:** Mencatat riwayat pemanggilan AI, prompt mentah, respons mentah, waktu inferensi, dan alasan penolakan risiko.
- **Emergency Kill Switch:** Sakelar global di memori dan database yang memutus eksekusi siklus perdagangan dalam hitungan detik.
- **Health & Freshness Monitor:** Memantau keterlambatan data on-chain (*data lag*) dan menandai data sebagai *stale* jika usia data melampaui ambang batas aman.
