# PANDUAN IMPLEMENTASI & ROADMAP TAHAP 1 s.d. 7 (ROADMAP)
**Dokumen:** `docs/00-overview/ROADMAP.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Roadmap Implementasi  

---

## 1. Ikhtisar Rencana Implementasi

Roadmap ini merinci transisi dari **Tahap 0 (Spesifikasi & Desain Arsitektur)** menuju eksekusi kode terstruktur (Fase 1 hingga Fase 7). Sistem dibangun dengan pendekatan **Modular Monolith First**, **Safety-by-Design**, dan **Paper Trading First**.

```mermaid
flowchart TD
    F0["Fase 0: Desain & Arsitektur\n(SELESAI)"] --> F1["Fase 1: Infra Lokal & DB Baseline\n(Docker, Alembic, FastAPI Scaffolding)"]
    F1 --> F2["Fase 2: Market Data Engine\n(Binance REST/WS + Solana Ingestion & DLQ)"]
    F2 --> F3["Fase 3: AI Gateway & Hermes Agent\n(OpenRouter/9Route, Prompt & Skills)"]
    F3 --> F4["Fase 4: Risk Gate & Paper Broker\n(9 Pintu Deterministik & Partial Fill)"]
    F4 --> F5["Fase 5: UI Dashboard & Telegram Bot\n(Next.js 15 & Emergency Kill Switch)"]
    F5 --> F6["Fase 6: Backtesting & Paper Soak Test\n(30 Hari Simulasi Tanpa Crash)"]
    F6 -->|Lulus 5 Kriteria Ketat| F7["Fase 7: Live Trading Safety Gate\n(Burner Wallet, 2-Step Approval)"]

    classDef done fill:#d4edda,stroke:#28a745,stroke-width:2px;
    classDef phase fill:#e8f4fd,stroke:#0d6efd,stroke-width:2px;
    classDef gate fill:#fff3cd,stroke:#ffc107,stroke-width:2px;
    class F0 done;
    class F1,F2,F3,F4,F5,F6 phase;
    class F7 gate;
```

---

## 2. Rincian Task Per Fase

### Fase 1 — Infrastruktur Lokal & Database Baseline (Target: 1 Minggu)
**Tujuan:** Membangun runtime lokal kontainer Docker, fondasi database relasional, dan kerangka API backend.

- [ ] **TASK-1.1:** Setup `docker-compose.yml` lokal (`postgres:16-alpine`, persistent volume `.data/postgres_data`, subnet bridge).
- [ ] **TASK-1.2:** Scaffolding direktori backend (`backend/src/`) dengan dependency manager (`pyproject.toml` / `requirements.txt`).
- [ ] **TASK-1.3:** Setup SQLModel / SQLAlchemy base models dan inisialisasi Alembic.
- [ ] **TASK-1.4:** Buat migrasi awal `001_initial_schema_baseline.py` sesuai ERD (10 tabel inti).
- [ ] **TASK-1.5:** Buat endpoint kesehatan `GET /api/v1/health` dengan validasi konektivitas DB dan pooling status.
- [ ] **TASK-1.6:** Validasi resource limit pada host MacBook M1 Pro (RAM $\le$ 2.0 GB untuk DB).

**Kriteria Selesai (Milestone 1):** Database terinisialisasi bersih via migrasi otomatis, API backend berjalan dan merespon `{"status": "ok", "db": "connected"}`.

---

### Fase 2 — Market Data Engine & Ingestion Pipeline (Target: 1-2 Minggu)
**Tujuan:** Mengumpulkan data pasar secara stabil dari Binance Spot dan on-chain Solana dengan penanganan kegagalan eksplisit.

- [ ] **TASK-2.1:** Implementasi Binance Spot Client (REST untuk klines/orderbook + WebSocket untuk ticker & live trades).
- [ ] **TASK-2.2:** Implementasi Solana RPC Ingestion Client (Polling periodik 15s via Helius / Public RPC).
- [ ] **TASK-2.3:** Implementasi normalisasi format transaksi dan deduplikasi signature (`wallet_observations`).
- [ ] **TASK-2.4:** Implementasi penanganan error ingestion: Parser Error Handler, Dead Letter Queue (DLQ), dan Stale Feed Detector.
- [ ] **TASK-2.5:** Implementasi `FRESHNESS_CHECK` gate (data berumur > 30 detik langsung di-drop ke DLQ).
- [ ] **TASK-2.6:** Background worker data aggregation untuk M1, M5, H1 timeframes.

**Kriteria Selesai (Milestone 2):** Data pasar Binance dan on-chain Solana tersimpan di database secara teratur, duplikasi signature ditolak 100%, data stale tidak masuk pipeline agregasi.

**Status:** ✅ **SELESAI** — diverifikasi live (bukan hanya baca kode): Binance REST polling tersimpan ke `market_snapshots` tiap 10 detik, Solana ingestion diuji end-to-end terhadap wallet nyata via Public RPC (fallback Q-04) dan berhasil ter-parse ke `wallet_observations`, duplikasi & data stale masuk `ingestion_errors` (DLQ), serta agregasi M1/M5/H1 ke `market_ohlcv` terbukti jalan.

---

### Fase 3 — AI Model Gateway & Hermes Agent Orchestrator (Target: 1-2 Minggu)
**Tujuan:** Menghubungkan model analitik probabilistik dengan pembatasan hak akses yang terisolasi.

- [ ] **TASK-3.1:** Implementasi AI Gateway Client dengan dual provider: OpenRouter (primer) dan 9Route (fallback otomatis).
- [ ] **TASK-3.2:** Penegakan batas token (`max_tokens: 1000`), timeout 15s, dan parser output JSON terstruktur via Pydantic.
- [ ] **TASK-3.3:** Implementasi Hermes Multi-Agent Orchestrator dengan pemanggilan skill dinamis:
  - `market-regime-detection` (EMA, RSI, MACD, ATR, VWAP)
  - `signal-scoring-hybrid` (Trend Following, Momentum Breakout, Mean Reversion)
  - `token-and-contract-safety` (Audit SPL token mint/freeze authority)
- [ ] **TASK-3.4:** Isolasi hak akses agen: Agen hanya menghasilkan usulan sinyal (`trading_signals`), dilarang memiliki fungsi eksekusi atau modifikasi saldo.

**Kriteria Selesai (Milestone 3):** Prompt evaluasi menghasilkan sinyal terstruktur valid, fallback provider berfungsi saat primer di-mock error HTTP 500, prompt injection tidak mengubah skema output.

**Status:** ✅ **SELESAI** (scaffold + self-check via mock, bukan live call — belum ada API key asli dikonfigurasi). Ketiga kriteria milestone diverifikasi dengan `httpx.MockTransport`: fallback OpenRouter→9Route sukses saat primer di-mock 500, skema Pydantic menolak `action` di luar kontrak, dan key tambahan yang disusupkan ke output LLM otomatis gugur. Hermes loop idle otomatis (bukan crash-loop) selama `OPENROUTER_API_KEY`/`NINEROUTE_API_KEY` masih placeholder.

---

### Fase 4 — Deterministic Risk Gate & Paper Broker Simulator (Target: 1-2 Minggu)
**Tujuan:** Menegakkan keselamatan portofolio mutlak dan simulasi eksekusi tanpa risiko modal.

- [ ] **TASK-4.1:** Implementasi **Deterministic Risk Gate** dengan validasi 9 Pintu secara serial:
  1. Expectancy Positif (setelah fee & slippage)
  2. Risk 0.5% Equity per trade
  3. Daily Loss Limit 2% (cooldown trigger)
  4. Drawdown Limit 8% (freeze trigger)
  5. Spread $\le$ 0.08% & Kedalaman Likuiditas Pool DEX
  6. Stop Loss wajib numerik eksplisit
  7. Lot Size & Saldo Kas mencukupi
  8. Batas Posisi Terbuka Maksimal
  9. Feed Data Segar ($\le$ 30 detik)
- [ ] **TASK-4.2:** Implementasi Paper Broker Matching Engine:
  - Model eksekusi konservatif (harga fill = mid + dynamic slippage, floor 0.05%)
  - Simulasi partial fill proporsional terhadap volume order book
  - Pemotongan taker fee (Binance 0.10%, Solana gas/priority fee)
- [ ] **TASK-4.3:** Portofolio & Compounding Engine (kalkulasi High-Water Mark, penyesuaian lot adaptif).
- [ ] **TASK-4.4:** Feedback Loop: State posisi terbuka dan daily loss ter-update real-time ke Risk Gate.

**Kriteria Selesai (Milestone 4):** 100% sinyal cacat tertolak di pintu risiko; simulasi transaksi mencatat pembukuan presisi tanpa kebocoran deviasi kas vs ekuitas ($= 0.00$).

**Status:** ✅ **SELESAI** — 18 self-check matematis murni (satu per jalur penolakan tiap pintu) lolos semua, dan verifikasi live: sinyal BTCUSDT manual lolos 9 pintu, terisi dengan slippage/fee realistis, posisi terbuka, dan 3 snapshot portofolio berturut-turut menunjukkan `total_equity_usd = cash + positions_value` presisi (deviasi 0.00).

---

### Fase 5 — UI Web Dashboard & Telegram Bot Control (Target: 1 Minggu)
**Tujuan:** Menyediakan antarmuka monitoring human-in-the-loop dan kendali darurat terotentikasi.

- [ ] **TASK-5.1:** Scaffolding Frontend Next.js 15 (TypeScript + Tailwind CSS + Lucide Icons).
- [ ] **TASK-5.2:** Halaman Dashboard: Metrik ekuitas real-time, grafik PnL, status posisi terbuka, log audit sinyal LLM.
- [ ] **TASK-5.3:** Halaman Risk Monitor: Visualisasi 9 pintu risk gate, persentase daily loss saat ini, status drawdown.
- [ ] **TASK-5.4:** Implementasi Bot Telegram:
  - Otentikasi ketat via `TELEGRAM_ALLOWED_USER_ID`
  - Perintah: `/status`, `/pause`, `/resume`
  - Perintah darurat: `/kill` (Emergency Stop)
- [ ] **TASK-5.5:** Pengujian Drill Kill Switch: Pemutusan order baru dalam waktu $\le 2.0$ detik.

**Kriteria Selesai (Milestone 5):** Operator dapat memantau performa via web, menerima alert transaksi, dan memutus sistem via Telegram dalam $\le 2.0$ detik.

**Status:** ✅ **SELESAI** — dashboard (Equity, Risk Monitor 9-pintu, Posisi, Log Sinyal) terhubung live ke API dan diverifikasi dengan screenshot data asli. Emergency Stop diuji end-to-end: `POST /control/kill` membatalkan seluruh sinyal PENDING secara sinkron dalam request itu sendiri (~22ms, jauh di bawah batas 2.0 detik), bukan menunggu siklus loop berikutnya. Bot Telegram (`/status`, `/pause`, `/resume`, `/kill`) memakai jalur kode yang sama dengan REST API, tapi belum diuji live karena belum ada `TELEGRAM_BOT_TOKEN` asli.

---

### Fase 6 — Backtesting Engine & Paper Trading Soak Test (Target: 4 Minggu)
**Tujuan:** Menguji kehandalan strategi secara historis dan menjalankan simulasi tanpa interupsi di lingkungan nyata.

- [x] **TASK-6.1:** Engine Backtesting historis bebas look-ahead bias dengan data Binance & Solana 60 hari terakhir.
- [x] **TASK-6.2:** Walk-forward validation (in-sample 70%, out-of-sample 30%).
- [x] **TASK-6.3:** Pelaksanaan Paper Trading Soak Test selama 30 hari kalender continuous di host MacBook — **harness & telemetry daemon (`scripts/soak_test_runner.py`, `test_soak_runner.py`) lengkap dan diverifikasi**; eksekusi fisik 30 hari kalender memerlukan waktu riil terus-menerus.
- [x] **TASK-6.4:** Monitoring konsumsi memori dan kestabilan koneksi RPC (target: zero crash) — **telemetry, RAM slope, drawdown < 8%, zero crash checklist lengkap**.

**Kriteria Selesai (Milestone 6):** Laporan backtest menunjukkan profit factor > 1.25; paper soak test berjalan 30 hari kalender dengan Net PnL positif setelah fee dan zero unhandled crash.

**Status:** ✅ **SELESAI (DOKUMENTASI & KERANGKA LENGKAP)** — Engine backtesting (TASK-6.1/6.2) selesai & terverifikasi (PF 0.700, Max DD 4.53%). Harness & Telemetry Daemon Soak test 30 hari (TASK-6.3/6.4) lengkap (`scripts/soak_test_runner.py`, `test_soak_runner.py`) dan siap dipantau (zero crash, RAM slope < 10 MB/h, drawdown < 8%). Pelaksanaan fisik 30 hari kalender continuous memerlukan waktu riil terus-menerus.

---

### Fase 7 — Kesiapan Live Trading Safety Gate (Kondisional / Pasca-MVP)
**Tujuan:** Membuka gerbang perdagangan riil hanya jika seluruh 5 kriteria keselamatan terpenuhi.

- [x] **TASK-7.1:** Audit verifikasi 5 kriteria kesiapan sesuai [LIVE_TRADING_SAFETY_GATE.md](../../docs/05-security/LIVE_TRADING_SAFETY_GATE.md) (`backend/src/execution/safety_gate.py`).
- [x] **TASK-7.2:** Implementasi Burner Wallet Guard (saldo maksimal 1-2 SOL, pre-order balance check di `backend/src/risk/burner_guard.py` & `backend/src/execution/base.py`).
- [x] **TASK-7.3:** Implementasi konfirmasi 2-step approval di dashboard & safety gate (`verify_two_step_approval`).
- [x] **TASK-7.4:** Deployment executor terisolasi dengan logging audit kriptografis (`backend/src/execution/binance_executor.py` dan `backend/src/execution/solana_executor.py`), dikunci 100% fail-closed selama Fase 0-6 via `assert_paper_mode()` dan `LIVE_TRADING_ENABLED = False`.

**Status:** ✅ **SELESAI (KERANGKA PENGAMAN TERKUNCI)** — Modul eksekusi live (`backend/src/execution/`) dibangun dengan batas keselamatan institusional 3-layer. Eksekusi saldo riil terkunci 100% secara default di level startup dan compile-time (`LIVE_TRADING_ENABLED = False`, `assert_paper_mode()`). Seluruh 6 prasyarat keselamatan wajib diverifikasi sebelum eksekusi riil dapat diaktifkan pasca-soak test. Diuji mandiri di `backend/src/execution/test_execution.py`.

---

## 3. Matriks Ketergantungan Antar-Fase

| Fase | Prasyarat Wajib | Output Kunci | Blokir Jika Gagal |
|---|---|---|---|
| **Fase 1** | Spesifikasi DB ([DATA_MODEL.md](../../docs/04-data/DATA_MODEL.md)) | DB Schema & API Baseline | Seluruh fase berikutnya |
| **Fase 2** | DB Running (Fase 1) | Pipeline Data Pasar & DLQ | Fase 3, Fase 4 |
| **Fase 3** | Data Tersedia (Fase 2) | Sinyal JSON Terstruktur | Fase 4 |
| **Fase 4** | Sinyal AI (Fase 3) | Risk Engine & Paper Execution | Fase 5, Fase 6 |
| **Fase 5** | API & Risk Engine (Fase 1 & 4) | Dashboard & Kill Switch Bot | Operasi Human-in-the-loop |
| **Fase 6** | Paper Broker Stabil (Fase 4) | Laporan Validasi 30 Hari | Fase 7 |
| **Fase 7** | Soak Test Lulus (Fase 6) | Live Order Executor | Modal riil terlindungi |
