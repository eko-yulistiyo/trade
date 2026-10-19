# PENJELASAN RELASI ERD (ERD EXPLANATION)
**Dokumen:** `docs/04-data/ERD_EXPLANATION.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Basis Data  

---

Dokumen ini melengkapi diagram visual [ERD.mmd](file:///Users/nabilartanabil/SourceCode/AUTO-TRADE-AA/docs/03-diagrams/ERD.mmd) dengan memberikan rincian matematis kardinalitas relasi, aturan integritas referensial (*foreign key behavior*), dan indeks awal basis data.

---

## 1. Rincian Relasi Antar-Entitas & Kardinalitas

### 1.1 `WALLETS` ──(1:N)──> `WALLET_OBSERVATIONS`
- **Kardinalitas:** Satu wallet dapat memiliki nol atau ribuan transaksi yang diobservasi (*One-to-Many*).
- **Foreign Key:** `wallet_observations.wallet_id` merujuk ke `wallets.id`.
- **Integritas Referensial:** `ON DELETE RESTRICT`. Riwayat observasi transaksi tidak boleh terhapus secara tidak sengaja jika wallet dinonaktifkan. Wallet hanya boleh diubah statusnya menjadi `ARCHIVED`.

### 1.2 `TOKENS` ──(1:N)──> `MARKET_SNAPSHOTS`
- **Kardinalitas:** Satu token memiliki snapshot harga berkala per menit (*One-to-Many*).
- **Foreign Key:** `market_snapshots.token_id` merujuk ke `tokens.id`.
- **Integritas Referensial:** `ON DELETE CASCADE`. Jika entitas token uji coba dihapus, data snapshot time-series terkait dapat dibersihkan otomatis.

### 1.3 `STRATEGIES` ──(1:N)──> `STRATEGY_VERSIONS`
- **Kardinalitas:** Satu induk strategi (misal `MOMENTUM_BREAKOUT`) dapat memiliki beberapa iterasi versi parameter (`v1.0.0`, `v1.1.0`).
- **Foreign Key:** `strategy_versions.strategy_id` merujuk ke `strategies.id`.
- **Integritas Referensial:** `ON DELETE RESTRICT`. Mencegah hilangnya konteks versi strategi yang pernah digunakan untuk menghasilkan sinyal masa lalu.

### 1.4 `STRATEGY_VERSIONS` ──(1:N)──> `AGENT_RUNS` ──(1:N)──> `LLM_REQUESTS`
- **Kardinalitas:** Setiap eksekusi alur kerja agen dicatat dalam `agent_runs`. Satu siklus *run* dapat melakukan beberapa panggilan model bahasa besar (misal panggilan Token Safety lalu Market Context).
- **Foreign Key:** `agent_runs.strategy_version_id` -> `strategy_versions.id`; `llm_requests.agent_run_id` -> `agent_runs.id`.
- **Integritas Referensial:** `ON DELETE CASCADE`.

### 1.5 `AGENT_RUNS` ──(1:N)──> `TRADING_SIGNALS`
- **Kardinalitas:** Satu siklus analisis agen menghasilkan nol atau beberapa usulan sinyal perdagangan terstruktur.
- **Foreign Key:** `trading_signals.agent_run_id` merujuk ke `agent_runs.id`.
- **Integritas Referensial:** `ON DELETE RESTRICT`. Sinyal adalah data audit finansial yang wajib dipertahankan.

### 1.6 `TRADING_SIGNALS` ──(1:N)──> `RISK_CHECKS`
- **Kardinalitas:** Setiap sinyal dievaluasi oleh Risk Engine. (Biasanya 1:1, namun dirancang 1:N untuk mendukung evaluasi ulang jika terjadi pembaruan parameter portofolio).
- **Foreign Key:** `risk_checks.trading_signal_id` merujuk ke `trading_signals.id`.
- **Integritas Referensial:** `ON DELETE RESTRICT`. Jejak keputusan kelulusan atau penolakan risiko tidak boleh dihapus.

### 1.7 `RISK_CHECKS` ──(1:1 / 1:0)──> `PAPER_ORDERS`
- **Kardinalitas:** Sinyal yang berstatus `risk_checks.passed == TRUE` akan menerbitkan tepat satu `paper_orders`. Sinyal yang gagal (`passed == FALSE`) tidak akan memiliki relasi ke `paper_orders`.
- **Foreign Key:** `paper_orders.risk_check_id` merujuk ke `risk_checks.id`.
- **Constraint:** `UNIQUE (risk_check_id)` untuk mencegah satu evaluasi risiko menerbitkan lebih dari satu order (*mencegah eksekusi ganda*).

### 1.8 `PAPER_ORDERS` ──(1:N)──> `PAPER_TRADES`
- **Kardinalitas:** Satu order virtual dapat terisi melalui satu atau beberapa pengisian eksekusi (*partial fills*).
- **Foreign Key:** `paper_trades.paper_order_id` merujuk ke `paper_orders.id`.
- **Integritas Referensial:** `ON DELETE RESTRICT`.

### 1.9 `POSITIONS` ──(1:N)──> `PAPER_TRADES`
- **Kardinalitas:** Satu posisi terbuka dibentuk oleh trade pembuka (Buy) dan dikurangi/ditutup oleh trade penutup (Partial TP1, TP2, SL Sell).
- **Foreign Key:** `paper_trades.position_id` merujuk ke `positions.id`.
- **Integritas Referensial:** `ON DELETE RESTRICT`.

---

## 2. Strategi Pengindeksan Basis Data Awal (Indexing Strategy)

Untuk menjamin latensi baca dashboard $\le 200$ ms dan latensi evaluasi risiko $\le 20$ ms (NFR-PERF-02 & NFR-PERF-03), indeks berikut diterapkan sejak hari pertama:

| Tabel | Kolom Terindeks | Tipe Indeks | Tujuan Optimasi Query |
|---|---|---|---|
| `wallet_observations` | `(tx_signature)` | **UNIQUE B-Tree** | Menjamin deduplikasi transaksi on-chain tepat satu kali (*idempotency*). |
| `wallet_observations` | `(wallet_id, block_time DESC)` | **Composite B-Tree** | Mempercepat query riwayat transaksi terakhir per dompet untuk alur copy-trading. |
| `market_snapshots` | `(token_id, snapshot_time DESC)` | **Composite B-Tree** | Mempercepat pengambilan harga spot terkini dan pemeriksaan data stale (< 30s). |
| `trading_signals` | `(status, generated_at DESC)` | **B-Tree** | Mempercepat antrean sinyal `PENDING` untuk dievaluasi oleh Risk Engine. |
| `positions` | `(status, symbol)` | **B-Tree** | Mempercepat pembacaan posisi terbuka aktif (`status = 'OPEN'`) oleh Matching Engine dan Dashboard. |
| `paper_orders` | `(client_order_id)` | **UNIQUE B-Tree** | Mencegah pembuatan order duplikat dari antrean internal. |
| `llm_requests` | `(requested_at DESC)` | **B-Tree** | Pengurutan audit trail inferensi model bahasa besar. |
| `wallet_observations` | `(raw_payload)` | **GIN Index (jsonb_path_ops)** | Pencarian cepat atribut khusus dalam payload instruksi program Solana/Bybit. |
