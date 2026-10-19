# CAKUPAN DAN NON-GOALS (SCOPE AND NON-GOALS)
**Dokumen:** `docs/00-overview/SCOPE_AND_NON_GOALS.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi  

---

## 1. Definisi Ruang Lingkup MVP (Minimum Viable Product)
Cakupan Minimum Viable Product (MVP) berfokus pada pembentukan fondasi analitik, pengujian deterministik, simulasi portofolio tanpa risiko, serta kendali operasional yang aman.

### 1.1 In-Scope: Modul & Fitur yang Dibangun pada MVP
1. **Blockchain & Data Ingestion (Solana):**
   - Penarikan data transaksi on-chain untuk daftar wallet terpilih (*tracked wallets*).
   - Penarikan data harga token, likuiditas pool DEX (misal Raydium/Orca AMM), dan metadata token via RPC/REST/WebSocket.
   - Normalisasi transaksi, validasi integritas payload, serta deduplikasi transaksi (*idempotency*).
2. **Trader & Wallet Discovery Engine:**
   - Evaluasi historis performa wallet berdasarkan metrik objektif: Profit and Loss (PnL) bersih biaya, rasio Sharpe/Sortino sederhana, Maximum Drawdown (MDD), dan konsistensi durasi holding.
   - Skrining anti-manipulasi (mendeteksi wash trading, sirkulasi dana internal antar-wallet).
   - Antarmuka review bagi pengguna untuk menyetujui wallet sebelum masuk daftar pantau (*watchlist approval*).
3. **AI Multi-Agent Workflow (Hermes Agent & Model Gateway):**
   - Agen Spesialis Analisis Token: Memeriksa risiko keamanan kontrak token (mint authority, freeze authority, konsentrasi kepemilikan top holders).
   - Agen Spesialis Analisis Pasar: Mengidentifikasi tren likuiditas dan sentimen volume perdagangan.
   - Agen Spesialis Strategi: Menghasilkan rekomendasi sinyal terstruktur (Buy, Sell, Hold, Size Recommendation) dengan format skema JSON ketat.
   - Gateway Adapter terpadu untuk OpenRouter dan 9Route dengan mekanisme *fallback*, batasan kuota token, dan penanganan timeout.
4. **Deterministic Risk Engine (Gerbang Risiko Mutlak):**
   - Filter aturan deterministik yang tidak dapat dimatikan atau dilewati oleh LLM:
     - Maksimum modal per posisi simulasi.
     - Ambang batas toleransi *slippage*.
     - Batas toleransi kerugian harian (*Daily Max Loss Limit*).
     - Filter likuiditas minimum DEX (menolak token dengan likuiditas rendah/rentan *rug pull*).
     - Blacklist token terkonfigurasi.
     - Pemeriksaan integritas data (menolak eksekusi jika data harga kadaluarsa / *stale data*).
5. **Simulation & Testing Engine (Paper Broker & Backtester):**
   - *Backtesting Engine* untuk menguji strategi pada data historis dengan simulasi fee jaringan dan slippage realistis tanpa bias masa depan (*look-ahead bias*).
   - *Paper Trading Engine* untuk mengeksekusi order virtual secara real-time terhadap harga pasar langsung.
   - Akuntansi posisi virtual, pelacakan saldo kas virtual, kalkulasi Realized PnL dan Unrealized PnL secara akurat.
6. **Dashboard Web & Kontrol Telegram:**
   - Antarmuka web modern (Next.js) yang responsif: Ringkasan portofolio simulasi, riwayat order/trade, log audit sinyal, dan status kesehatan sistem.
   - Bot Telegram untuk notifikasi instan (sinyal baru, penolakan risiko, status order paper trading).
   - Perintah Telegram terotentikasi (*Allowlist User/Chat ID*) untuk kontrol darurat: `/status`, `/pause`, `/resume`, `/kill`.
7. **Audit Trail & Keamanan:**
   - Penyimpanan riwayat lengkap permintaan/respons AI, evaluasi risiko, dan eksekusi order pada PostgreSQL.
   - Prinsip keamanan *fail-closed* dan *least privilege*.

---

## 2. Non-Goals: Hal yang Secara Eksplisit TIDAK Dibuat pada MVP

| Item Non-Goal | Alasan & Rasional Penolakan pada MVP | Rencana Masa Depan |
|---|---|---|
| **Live Trading Otomatis (Eksekusi Dana Riil)** | Menghindari risiko finansial langsung akibat kesalahan kode, latensi, atau anomali pasar pada tahap awal. | Ditangguhkan ke **Fase 7**; memerlukan audit keamanan mandiri, simulasi berkepanjangan, dan persetujuan eksplisit pengguna. |
| **Penyimpanan Private Key / Seed Phrase** | Menghilangkan vektor serangan pencurian dana (*zero custodial risk*). | Pada Fase 7 kelak, opsi yang dipertimbangkan adalah transaksi bertanda tangan manual (*manual signing*) atau wallet terpisah (*burner wallet*) dengan saldo terisolasi. |
| **Dukungan Multi-Chain (Ethereum, BSC, EVM, dll.)** | Menjaga fokus rekayasa sistem agar tidak mengalami kompleksitas arsitektur abstraksi rantai yang berlebihan. | Dievaluasi pada rilis v2 setelah modul Solana terbukti stabil dan menguntungkan dalam simulasi. |
| **Registrasi Publik / Arsitektur Multi-Tenant (SaaS)** | Proyek ditujukan sebagai alat operasional privat/independen satu pengguna (*single operator*). | Di luar lingkup proyek. Jika kelak dikembangkan menjadi produk komersial, diperlukan refaktorisasi arsitektur keamanan multi-tenant tersendiri. |
| **Aplikasi Mobile Native (iOS / Android)** | Biaya pemeliharaan (*overhead*) tinggi untuk pengembangan mobile ganda. | Dashboard Next.js dioptimalkan untuk tampilan *mobile-responsive* web browser, didukung notifikasi instan Telegram. |
| **Jaminan Profitabilitas Otomatis** | Tidak ada algoritma trading yang dapat menjamin keuntungan di pasar aset kripto. | Sistem berfokus pada disiplin manajemen risiko dan transparansi kalkulasi. |
| **Penyewaan Server VPS Terburu-buru** | Menghindari pemborosan biaya infrastruktur sebelum sistem teruji fungsional secara lokal. | VPS (opsi Indonesia) hanya akan disewa setelah tahapan paper trading lokal tuntas dan stabil. |

---

## 3. Matriks Evolusi Fase Proyek

```
[Tahap 0: Desain & Spesifikasi] 
       │
       ▼
[Fase 1-6: MVP Paper Trading & Analisis On-Chain (Lokal MacBook)]
  - Discovery & Ingestion Solana
  - Multi-Agent Hermes + Model Gateway
  - Deterministic Risk Engine
  - Paper Execution & Backtesting
  - Dashboard Web & Telegram Control
       │
       ▼ (Evaluasi Operasional & Audit Keamanan Mandiri)
[Fase 7: Gerbang Live Trading Terkontrol (Opsional & Memerlukan Persetujuan)]
  - Burner Wallet / Saldo Terisolasi
  - Manual Approval per Transaksi
  - Verifikasi Kill Switch Fisik
```

---

## 4. Konsekuensi Batasan Ruang Lingkup
- Semua kalkulasi keuntungan dan kerugian pada Fase 1 hingga Fase 6 adalah **kinerja hipotetis/virtual (*paper performance*)**.
- Ketidakhadiran live trading pada MVP memungkinkan pengujian ketahanan arsitektur secara mendalam tanpa beban stres finansial bagi operator.
