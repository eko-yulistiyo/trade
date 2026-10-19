# GAMBARAN UMUM ARSITEKTUR (ARCHITECTURE OVERVIEW)
**Dokumen:** `docs/02-architecture/ARCHITECTURE_OVERVIEW.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Arsitektur  

---

## 1. Filosofi & Pendekatan Arsitektur

Platform **AUTO-TRADE-AA** dirancang dengan pendekatan **Modular Monolith First** dan **Safety-by-Design**. Sistem menggabungkan kemampuan inferensi probabilistik dari model AI (LLM) dengan kepastian matematis dari mesin manajemen risiko deterministik (*Deterministic Risk Engine*). 

Prinsip fundamental sistem adalah: **AI memberikan analisis dan usulan sinyal, namun kode deterministik yang memegang otoritas penuh terhadap eksekusi transaksi.**

```
═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
                      FLOW ARSITEKTUR AI CRYPTO AUTOTRADE (HYBRID ENGINE BLUEPRINT)
  Hybrid Strategy │ Bybit Spot + Solana │ Paper Trading │ Risk 0.5% │ Daily Loss 2% │ Drawdown 8% │ Compounding Adaptif
═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

┌──────────────────────────────────────┐     ┌──────────────────────────────────────┐     ┌──────────────────────────────────────┐
│ 1. MARKET DATA ENGINE                │     │ 2. AI SIGNAL & ANALYSIS              │     │ 3. RISK GATE                         │
│    (Real-time & Historical Data)     │     │    (Multi-Timeframe + AI Model)      │     │    (Validasi Sebelum Eksekusi)       │
│                                      │     │                                      │     │                                      │
│ • Bybit API (Spot): WS & REST        │────►│ • Data Cleaning & Normalisasi        │────►│ • Expectancy Positif (setelah fee)   │
│ • Solana Ingestion: RPC/WS & Helius  │     │ • Tech Analysis: EMA, RSI, MACD,     │     │ • Risk per Trade 0.5% (dari equity)  │
│ • OHLCV Data: M1, M5, M15, H1, H4, D1│     │   ATR, VWAP, Support/Resistance      │     │ • Daily Loss Limit 2%                │
│ • Order Book: Bid/Ask, Spread, Depth │     │ • Market Regime Detection:           │     │ • Drawdown Limit 8%                  │
│ • Ticker & Volume 24h                │     │   (Trending vs Sideways)             │     │ • Cek Spread & Likuiditas            │
│ • Market Info: Symbol & Tick rules   │     │ • Dynamic AI Skill Loading:          │     │ • Validasi Stop Loss                 │
│ • Funding & Market Sentiment         │     │   - market-regime-detection          │     │ • Cek Saldo & Lot Size               │
│ • Data Storage: PostgreSQL (Time-S.) │     │   - signal-scoring-hybrid            │     │ • Status: LOLOS?                     │
│                                      │     │ • Hybrid Strategy: Trend Following,  │     │   ├── YA ──► Lanjut ke Kotak 4       │
│                                      │     │   Momentum Breakout, Mean Reversion  │     │   └── TIDAK ──► [ NO TRADE ]         │
└──────────────────────────────────────┘     └──────────────────────────────────────┘     └──────────────────┬───────────────────┘
                                                                                                             │ Lolos Risk Gate
                                                                                                             ▼
┌──────────────────────────────────────┐     ┌──────────────────────────────────────┐     ┌──────────────────────────────────────┐
│ 6. BACKTESTING & VALIDATION          │     │ 5. PORTOFOLIO & COMPOUNDING          │     │ 4. EXECUTION ENGINE                  │
│    (Uji Strategi Data Historis)      │     │    (Equity Management)               │     │    (Paper Trading Simulasi)          │
│                                      │     │                                      │     │                                      │
│ • Historical Data Bybit & Solana     │     │ • Position Sizing: Risk 0.5% Equity  │◄────│ • Simulasi Market / Limit Order      │
│ • Realistic Fee, Slippage & Latency  │     │ • Compounding Adaptif: Reinvest      │     │ • Partial Fill Simulation            │
│ • Walk-Forward Testing (In/Out sample│     │   profit, sesuaikan volatilitas      │     │ • Hitung Fee Bybit & Solana Slippage │
│ • Evaluasi: Expectancy, Profit Factor│     │ • Kurangi risiko saat drawdown       │     │ • Manajemen Posisi: Stop Loss, Take  │
│   Win Rate, Maximum Drawdown         │     │ • Equity Ledger: High-Water Mark     │     │   Profit (TP), Trailing Stop,        │
│   (Loop balik ke Optimasi Kotak 2)   │     │ • Metrics: Win Rate, Sharpe Ratio    │     │   Partial Take Profit (50% TP1)      │
└──────────────────▲───────────────────┘     └──────────────────┬───────────────────┘     └──────────────────────────────────────┘
                   │                                            │ Feedback & Optimasi
                   └────────────────────────────────────────────┴────────────────────────────────────────────┐
                                                                                                             │
┌───────────────────────────────────────────────────────────────────────────────────┐                        │
│ 7. MONITORING & ALERT (Real-time Dashboard & Notifications)                       │                        │
│ • Web Dashboard: Equity, Realized/Unrealized PnL, Win Rate, Profit Factor, DD %   │                        │
│ • Open Positions View: BTCUSDT, ETHUSDT, SOLUSDT, SPL Tokens                      │                        │
│ • Multi-channel Alerting: Telegram Bot, Discord Webhook, Email                    │                        │
│ • System Logs: Audit trail lengkap permintaan LLM & evaluasi risiko               │                        │
└───────────────────────────────────────────────────────────────────────────────────┘                        │
                                                                                                             │
┌───────────────────────────────────────────────────────────────────────────────────┐                        │
│ 8. CIRCUIT BREAKER & SAFETY (Otomatis Menghentikan Trading)                       │◄───────────────────────┘
│ • Daily Loss >= 2%: Hentikan entry baru, batalkan order aktif aman, kelola posisi │
│ • Drawdown >= 8%: Bekukan strategi, evaluasi manual sebelum aktivasi kembali      │
│ • Data / Koneksi Bermasalah: No entry baru sampai data normal (Fail-Closed)       │
│ • Anomali Eksekusi / Slippage: Hentikan strategi terkait, kirim alert darurat     │
└───────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Prinsip-Prinsip Desain Utama

1. **Modular Monolith First (ADR-001):**
   Seluruh modul domain dibangun dengan batasan modul yang jelas (*cohesive domain boundaries*). Menghindari kompleksitas jaringan mikroservis (RPC internal, *service discovery*, konsistensi terdistribusi) pada tahap awal.
2. **PostgreSQL Sebagai Sumber Kebenaran Tunggal (ADR-002):**
   Seluruh data transaksi, sinyal, evaluasi risiko, posisi virtual, portofolio, dan log audit disimpan secara relasional dengan integritas transaksi ACID (*Atomicity, Consistency, Isolation, Durability*).
3. **Redis Berstatus Opsional (ADR-003):**
   Redis bukan prasyarat wajib untuk MVP. Polling in-memory dan database PostgreSQL sudah memadai untuk beban kerja single-operator pada MacBook M1 Pro. Redis hanya diintegrasikan jika ada kebutuhan terukur untuk antrean background terdistribusi atau rate-limiting kecepatan tinggi.
4. **Simulasi Tanpa Risiko / Paper Trading First (ADR-004):**
   Sistem dirancang secara mendasar untuk *paper trading* dan *backtesting*. Tidak ada fungsionalitas penandatanganan transaksi dengan kunci privat (*private key*) nyata pada fase ini.
5. **Solana & Bybit Hybrid Data Engine (ADR-005):**
   Spesifikasi ingestion dan model data dioptimalkan untuk instrumen likuiditas utama Bybit Spot dan karakteristik on-chain Solana (SPL Token, Account Model, DEX AMM Raydium/Orca).
6. **Arsitektur Hibrida Python + Rust + React.js (ADR-006):**
   - **Frontend:** **React.js** melalui framework **Next.js 15 (TypeScript + Tailwind CSS)** untuk antarmuka visual responsif, grafik candlestick interaktif, dan status portofolio.
   - **AI Orchestration & API Layer (Python FastAPI):** Menjalankan Hermes Multi-Agent, Dynamic AI Skill System (`.agents/skills/`), adapter AI Model Gateway (OpenRouter, 9Route), serta antarmuka REST API dan Telegram bot.
   - **High-Speed Trading & Safety Engine (Rust):** Menjalankan WebSocket ingestion berkecepatan tinggi, decoding transaksi on-chain Solana, Deterministic Risk Gate sub-milidetik, dan matching engine Paper Broker bebas jeda garbage collection.

---

## 3. Batas Tanggung Jawab Modul (Domain Boundaries)

| Modul Domain | Tanggung Jawab Utama | Komponen Input | Komponen Output |
|---|---|---|---|
| **Ingestion Engine** | Membaca RPC/WebSocket, mendeteksi swap, normalisasi data, deduplikasi signature. | Solana RPC, Helius, DEX API | `wallet_observations`, `market_snapshots` |
| **Discovery Engine** | Menilai kinerja historis wallet, mendeteksi wash trading, mengelola status approval. | Data historis transaksi | Rekomendasi wallet, skor trader |
| **Hermes Multi-Agent** | Mengorkestrasi analisis keamanan token, sentimen pasar, dan perumusan sinyal. | Context data token & pasar | `trading_signals` (JSON terstruktur) |
| **AI Model Gateway** | Menghubungkan ke OpenRouter/9Route, membatasi token, menangani timeout & fallback. | Prompt dari Hermes Agent | Respons LLM terstandarisasi |
| **Risk Engine** | Mengevaluasi sinyal terhadap aturan keselamatan statis (Sizing, Slippage, Daily Loss). | `trading_signals`, data pasar, portofolio | `risk_checks` (`PASSED` / `REJECTED`) |
| **Paper Broker Simulator** | Mensimulasikan order virtual, menghitung fee & slippage, pembukuan posisi & PnL. | Sinyal yang lolos risiko | `paper_orders`, `paper_trades`, `positions` |
| **Control & API** | Menyediakan endpoint REST untuk Dashboard dan webhook/polling untuk Telegram Bot. | HTTP request operator / Telegram webhook | JSON API Response, Notifikasi Telegram |

---

## 4. Keamanan dan Batas Kepercayaan (Trust Boundaries)

- **Untrusted Zone (Zona Tidak Terpercaya):** Data on-chain dari blockchain publik (nama token, simbol, instruksi transaksi) dan API eksternal pihak ketiga dianggap sebagai input tidak terpercaya (*untrusted input*) yang wajib divalidasi dan disanitasi sebelum diproses.
- **Semi-Trusted Zone (Zona Analisis AI):** Model LLM eksternal (OpenRouter / 9Route) dianggap semi-terpercaya. Outputnya bersifat probabilistik dan selalu divalidasi skemanya menggunakan Pydantic. Agen AI dilarang mengakses kunci rahasia atau mengeksekusi order secara langsung.
- **Trusted Zone (Zona Terpercaya):** Risk Engine deterministik, Paper Broker, database PostgreSQL, dan handler Telegram terotentikasi beroperasi dalam zona terpercaya lokal.
