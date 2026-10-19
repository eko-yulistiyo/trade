# REVIEW DAN PENYELARASAN ARSITEKTUR (ARCHITECTURE REVIEW & ALIGNMENT)
**Dokumen:** `docs/00-overview/ARCHITECTURE_REVIEW_AND_ALIGNMENT.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Referensi:** Gambar Blueprint "FLOW ARSITEKTUR AI CRYPTO AUTOTRADE"  
**Tanggal:** 14 Oktober 2026  
**Status:** Diterima & Diselaraskan (*Accepted & Aligned*)  

---

## 1. Ringkasan Eksekutif Review

Berdasarkan blueprint acuan visual yang diberikan oleh pengguna (**FLOW ARSITEKTUR AI CRYPTO AUTOTRADE**), dilakukan audit komparatif terhadap dokumentasi Tahap 0 yang telah disusun sebelumnya.

Blueprint pengguna menetapkan standar kuantitatif dan disiplin manajemen modal profesional (*institutional quant standard*) dengan tujuan utama:
1. **Positive Expectancy setelah biaya.**
2. **Risiko terukur dan konsisten.**
3. **Compounding cepat dengan disiplin.**

Hasil audit menunjukkan perlunya penyelarasan parameter kunci dari asumsi awal menjadi angka parameter emas (*gold standard parameters*), serta penambahan dukungan **Bybit API (Spot)** bersama dengan integrasi on-chain Solana, mekanisme **Compounding Adaptif**, manajemen posisi tingkat lanjut (*Partial TP & Trailing Stop*), dan arsitektur **Circuit Breaker 4-Layer**.

---

## 2. Matriks Komparasi: Dokumentasi Awal vs Blueprint Pengguna

| Dimensi Arsitektur | Spesifikasi Awal (Baseline Asumsi) | Blueprint Baru (Gambar Acuan Pengguna) | Tindakan Penyelarasan Dokumentasi |
|---|---|---|---|
| **Data & Execution Venue** | Solana On-Chain DEX (Raydium/Orca) saja. | **Bybit Spot API** (WebSocket real-time + REST historical) + **Solana On-Chain**. | Mendukung arsitektur **Hybrid Market Data Engine**: Bybit Spot untuk pasangan likuiditas utama (BTCUSDT, ETHUSDT, SOLUSDT) dan Solana untuk token DEX & copy-trading. |
| **Risk per Trade** | 5.0% - 10.0% dari ekuitas. | **Ketat 0.5% dari equity terkini**. | **DIUBAH:** Menurunkan batas risiko per trade menjadi **0.5%** sesuai kaidah prop-firm/manajemen risiko institusional. |
| **Daily Loss Limit** | 15.0% dari ekuitas awal hari. | **Ketat 2.0% dari ekuitas**. | **DIUBAH:** Memperketat Daily Loss Limit menjadi **2.0%** untuk melindungi modal dari *drawdown* beruntun. |
| **Drawdown Limit** | Tidak ditentukan batas keras eksplisit. | **Ketat 8.0% Maximum Drawdown**. | **DITAMBAHKAN:** Batas keras Drawdown 8.0% yang memicu pembekuan otomatis strategi untuk evaluasi manual. |
| **Position Management** | Entry & Exit penuh. | **SL, Take Profit (TP), Trailing Stop (opsional), Partial Take Profit, Partial Fill Simulation**. | **DITAMBAHKAN:** Logika manajemen posisi komprehensif pada Execution Simulator. |
| **Manajemen Modal** | Alokasi statis berbasis kas virtual. | **Compounding Adaptif**: Reinvest profit, sesuaikan volatilitas, kurangi risiko saat drawdown, High-Water Mark. | **DITAMBAHKAN:** Modul `Compounding & Equity Ledger Engine` dengan feedback loop ke optimasi sinyal. |
| **Multi-Timeframe & Indikator** | Analisis snapshot harga dasar. | **Multi-Timeframe (M1, M5, M15, H1, H4, D1)**; Indikator: EMA, RSI, MACD, ATR, VWAP, Support/Resistance; Regime: Trending vs Sideways. | **DITAMBAHKAN:** Spesifikasi feature engineering kuantitatif pada AI Signal Engine. |
| **Pilar Strategi AI** | Copy-trade mirror & breakout sederhana. | **Hybrid Strategy**: Trend Following, Momentum Breakout, dan Mean Reversion dengan filter sinyal palsu. | **DITAMBAHKAN:** Klasifikasi 3 pilar strategi pada modul Strategy Engine. |
| **Circuit Breaker & Safety** | Emergency kill switch umum. | **4 Pemicu Otomatis:** Daily Loss ≥ 2%, Drawdown ≥ 8%, Gangguan Data/Koneksi, Anomali Eksekusi/Slippage. | **DITAMBAHKAN:** Kotak 8 Circuit Breaker & Safety spesifik. |
| **Kanal Notifikasi** | Telegram Bot saja. | **Telegram, Email, Discord**. | **DIPERLUAS:** Multi-channel alerting (Telegram primer, webhook Discord & Email sekunder). |

---

## 3. Pemetaan 8 Kotak Arsitektur Baru

Sistem kini secara formal mengadopsi struktur 8 pilar arsitektur sesuai gambar:
1. **Kotak 1 — Market Data Engine (Real-time & Historical Data):** Bybit Spot (WebSocket & REST) + Solana On-Chain, OHLCV M1-D1, Order Book (Depth & Spread), Ticker & Volume 24h, Market Info (tick/lot size), Funding & Sentiment.
2. **Kotak 2 — AI Signal & Analysis (Multi-Timeframe + AI Model):** Data cleaning & normalization, Technical Analysis (EMA, RSI, MACD, ATR, VWAP, S/R), Market Regime Detection (Trending/Sideways), AI Model & Signal Scoring (Hybrid: Trend Following, Momentum Breakout, Mean Reversion, Probability Winrate, Filter Sinyal Palsu).
3. **Kotak 3 — Risk Gate (Validasi Sebelum Eksekusi):** Expectancy Positif (setelah biaya), Risk per Trade 0.5%, Daily Loss Limit 2%, Drawdown Limit 8%, Cek Spread & Likuiditas, Validasi Stop Loss, Cek Saldo & Lot Size, Market Condition OK. (Keputusan: LOLOS -> Eksekusi; TIDAK -> NO TRADE).
4. **Kotak 4 — Execution Engine (Paper Trading Simulasi):** Simulasi Market/Limit Order, Partial Fill, Hitung Fee & Slippage realistis, Eksekusi Entry & Exit, Manajemen Posisi (SL, TP, Trailing Stop, Partial TP), Update Portofolio real-time.
5. **Kotak 5 — Portofolio & Compounding (Equity Management):** Position Sizing 0.5% equity terkini (auto-adjust), Compounding Adaptif (reinvest profit, kurangi risiko saat drawdown), Equity Ledger (High-Water Mark), Performance Metrics (Win Rate, Profit Factor, Net Expectancy, Max Drawdown, Sharpe Ratio). Loop kembali ke Feedback & Optimasi.
6. **Kotak 6 — Backtesting & Validation (Uji Strategi Data Historis):** Data Bybit multi-timeframe, Backtest Engine (fee, slippage, latency), Walk-Forward Testing (In-sample & Out-of-sample), Evaluasi Expectancy & Win Rate.
7. **Kotak 7 — Monitoring & Alert (Real-time Dashboard):** Tampilan dashboard (Total Equity, Realized/Unrealized PnL, Win Rate, Profit Factor, Max Drawdown, Candlestick Chart, Open Positions Paper), Risk Monitoring, Multi-channel Alert (Telegram, Email, Discord), System Audit Logs.
8. **Kotak 8 — Circuit Breaker & Safety (Otomatis Menghentikan Trading):** Daily Loss ≥ 2% (hentikan entry baru, batalkan order aktif aman, kelola posisi terbuka), Drawdown ≥ 8% (bekukan strategi, evaluasi manual), Koneksi/Data bermasalah (no entry baru sampai data normal), Anomali eksekusi/slippage (hentikan strategi terkait).

---

## 4. Desain AI Agent Skill System (Efisiensi Token & Modularitas)

Sesuai arahan pengguna (*"tambahkan juga skill nya untuk ai agent menghemat dan membaca skill tersebut bebas ai agent nya apa saja"*), sistem multi-agent dilengkapi dengan **Agent Skill System**:
- **Tujuan:** Menghemat token konteks LLM secara drastis (hingga 70% penghematan biaya token) dengan tidak menyuntikkan manual aturan panjang ke dalam prompt statis.
- **Mekanisme Kerja:** AI agent (Hermes atau model LLM yang diakses melalui Model Gateway) membaca file instruksi keahlian (*Skill Files*) berformat Markdown yang ringkas dan terfokus hanya saat tugas spesifik dijalankan (*on-demand loading*).
- **Struktur Lokasi:** Tersimpan pada direktori `.agents/skills/`.
- **Daftar Skill yang Dibuat:**
  1. `market-regime-detection`: Aturan identifikasi rezim tren vs sideways menggunakan indikator teknikal.
  2. `signal-scoring-hybrid`: Metodologi pembobotan sinyal, estimasi probabilitas winrate, dan eliminasi sinyal palsu.
  3. `risk-gate-validation`: Standar validasi batas 0.5% risk, 2% daily loss, 8% drawdown limit, dan expectancy positif.
  4. `position-sizing-compounding`: Kalkulasi lot size dinamis, reinvestasi profit, dan penyesuaian drawdown.
  5. `token-and-contract-safety`: Aturan audit keamanan kontrak SPL token Solana dan spesifikasi symbol Bybit Spot.
