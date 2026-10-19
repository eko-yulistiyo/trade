# DAFTAR PERTANYAAN TERBUKA & KEPUTUSAN ARSITEKTUR (OPEN QUESTIONS)
**Dokumen:** `docs/00-overview/OPEN_QUESTIONS.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Menunggu Keputusan Pengguna (*Awaiting Human Decision*)  

---

Dokumen ini mencatat seluruh pertanyaan arsitektur dan parameter operasional yang memerlukan konfirmasi eksplisit dari pengguna. Setiap poin dilengkapi dengan **Rekomendasi Sementara (Baseline Assumption)** serta **Dampak Teknis & Konsekuensi** agar perancangan dokumentasi awal dapat berlanjut tanpa hambatan.

---

## 1. Pertanyaan Kunci & Rekomendasi Sementara

### Q-01: Apakah Solana menjadi satu-satunya venue data pada MVP atau didukung Bybit Spot?
- **Rekomendasi Terkini (Berdasarkan Blueprint):** **Arsitektur Hibrida: Bybit Spot API untuk instrumen likuiditas utama (BTCUSDT, ETHUSDT, SOLUSDT) + Solana On-Chain DEX (Raydium/Orca) untuk token discovery & copy-trading.**
- **Rasional:** Menggabungkan likuiditas institusional bursa terpusat (Bybit Spot WebSocket & REST) dengan peluang token desentralisasi on-chain Solana.
- **Konsekuensi / Dampak:** Market Data Engine mendukung dua konektor data: Bybit API Connector (Spot) dan Solana RPC/WebSocket Ingestion.

---

### Q-02: Bagaimana frekuensi target pemantauan wallet & ingestion data (Periodik vs. Mendekati Real-Time)?
- **Rekomendasi Sementara:** **Pendekatan Hibrida (Polling Periodik 10-30 detik untuk Wallet Ingestion; WebSocket Stream Bybit & Solana untuk pasangan aktif).**
- **Rasional:** Menggunakan WebSocket kontinu untuk ribuan transaksi di jaringan Solana akan langsung menghabiskan kuota *free-tier* RPC dalam hitungan jam. Polling periodik dengan interval adaptif (misal 15 detik untuk wallet aktif) jauh lebih hemat kuota.
- **Konsekuensi / Dampak:** Transaksi copy-trading pada paper trading akan mengalami jeda latensi 10-30 detik di belakang transaksi asli on-chain. Hal ini realistis untuk dievaluasi terhadap *slippage* simulasi.

---

### Q-03: Apakah sistem ini dirancang murni untuk Single-User atau Multi-User di masa depan?
- **Rekomendasi Sementara:** **Murni Single-User (Single Operator / Admin tunggal).**
- **Rasional:** Menyederhanakan mekanisme autentikasi dan otorisasi. Tidak diperlukan tabel tenant, manajemen peran kompleks (*RBAC multi-tenant*), atau isolasi data tingkat baris (*Row Level Security*) antar-pengguna.
- **Konsekuensi / Dampak:** Akses API dilindungi oleh token API/Bearer rahasia statis untuk operator, dan Telegram Bot dibatasi menggunakan *Chat ID Allowlist*.

---

### Q-04: Apa pilihan penyedia sumber data / Solana RPC dan bagaimana batas Free Tier-nya?
- **Rekomendasi Sementara:** **Helius Free Tier (100.000 kredit/hari) dikombinasikan dengan Public Solana RPC sebagai cadangan sekunder untuk query read-only non-kritis.**
- **Rasional:** Helius menyediakan parser transaksi Solana yang kaya (*Enhanced Transaction API*) yang sangat memudahkan identifikasi jenis swap di DEX tanpa harus mem-parse instruksi biner mentah secara manual.
- **Konsekuensi / Dampak:** Ingestion engine wajib memiliki modul *Rate Limiter & Budget Tracker* agar tidak melampaui 100k kredit/hari. Jika kuota habis, ingestion otomatis masuk ke mode jeda (*pause*) dengan status *fail-closed*.

---

### Q-05: Bagaimana definisi matematis dan sumber data untuk mengukur performa trader (*Wallet Discovery*)?
- **Rekomendasi Sementara:** **Metrik komposit berbasis PnL Bersih, Maximum Drawdown (MDD), Profit Factor, dan Umur Aktivitas Wallet minimum 30 hari; Sumber data: Solscan Public / DEXScreener / Birdeye API.**
- **Rasional:** Hanya mengandalkan *Win Rate* sangat menyesatkan karena banyak dompet sniper memiliki win rate 90% tetapi mengalami kerugian total pada 1 token scam.
- **Konsekuensi / Dampak:** Rumus skor trader:  
  $$\text{Score} = (0.4 \times \text{Net PnL}) + (0.3 \times \text{Profit Factor}) - (0.3 \times \text{Max Drawdown})$$  
  Wallet yang lolos ambang batas skor akan berstatus `PENDING_REVIEW` dan memerlukan persetujuan manual operator sebelum masuk daftar copy-trade.

---

### Q-06: Apa aturan strategi awal yang akan diimplementasikan pada fase simulasi?
- **Rekomendasi Terkini (Berdasarkan Blueprint):** **Tiga Pilar Hybrid Strategy: (1) Trend Following, (2) Momentum Breakout, dan (3) Mean Reversion; didukung Copy-Trade Mirroring.**
- **Rasional:** Memberikan diversifikasi adaptif terhadap kondisi pasar (Trending Bullish, Trending Bearish, maupun Sideways/Range-bound).
- **Konsekuensi / Dampak:** Modul strategi memiliki modul pendeteksi rezim pasar (*Market Regime Detection*) dan pembobotan sinyal terpadu.

---

### Q-07: Berapa modal awal simulasi (*Paper Capital*) dan bagaimana aturan Position Sizing?
- **Rekomendasi Terkini (Berdasarkan Blueprint):** **Modal awal virtual: $10.000 USD (atau setara 50-70 SOL virtual); Aturan Sizing: Ketat Risk 0.5% dari Total Equity Terkini per Trade dengan Compounding Adaptif.**
- **Rasional:** Sizing 0.5% dari ekuitas menjamin akun tahan terhadap 20 kali kerugian beruntun sekalipun tanpa mengalami kerusakan modal (*ruin*). Keuntungan direinvestasikan secara adaptif saat ekuitas naik.
- **Konsekuensi / Dampak:** Rumus kalkulasi: $\text{Lot Size} = (\text{Equity} \times 0.005) / |\text{Entry} - \text{StopLoss}|$.

---

### Q-08: Apa saja batas risiko (*Risk Gate*) yang wajib diterapkan oleh Risk Engine?
- **Rekomendasi Terkini (Sesuai Kotak 3 & Kotak 8 Blueprint):**
  1. **Positive Expectancy (setelah biaya):** Sinyal hanya dieksekusi jika model menghasilkan ekspektasi matematis positif bersih dari fee dan estimasi slippage.
  2. **Risk per Trade:** Maksimal **0.5% dari equity**.
  3. **Daily Loss Limit:** Maksimal **2.0% dari equity** (jika tersentuh, hentikan entry baru, batalkan order aktif aman, kelola posisi terbuka).
  4. **Drawdown Limit:** Maksimal **8.0% dari High-Water Mark** (memicu pembekuan strategi otomatis untuk evaluasi manual).
  5. **Cek Spread & Likuiditas:** Tolak entry jika spread > 0.08% atau kedalaman pool tidak memadai.
  6. **Validasi Stop Loss:** Stop Loss wajib terdefinisi numerik secara eksplisit.
  7. **Cek Saldo & Lot Size:** Memenuhi aturan minimum lot Bybit / DEX.
  8. **Market Condition OK:** Feed data normal, latency < 30 detik.
- **Rasional:** Standar ini adalah disiplin mutlak untuk melindungi portofolio dan memastikan profitabilitas jangka panjang.
- **Konsekuensi / Dampak:** Risk Engine menerapkan 8 aturan deterministik ini secara serial; 1 kegagalan aturan langsung menghasilkan status `NO TRADE`.

---

### Q-09: Bagaimana kebijakan retensi data di PostgreSQL?
- **Rekomendasi Sementara:** **Snapshot pasar dan raw on-chain data disimpan selama 14-30 hari; Data sinyal, order, trade, dan snapshot portofolio disimpan permanen (atau minimum 1 tahun).**
- **Rasional:** Data transaksi on-chain mentah dan snapshot harga per menit dapat membengkak hingga puluhan gigabyte jika disimpan tanpa batas di laptop M1 Pro.
- **Konsekuensi / Dampak:** Perlu disediakan skrip cron/pekerja latar belakang untuk membersihkan atau memadatkan (*vacuum/prune*) data time-series pasar yang lebih tua dari 30 hari.

---

### Q-10: Kapan infrastruktur VPS dibutuhkan?
- **Rekomendasi Sementara:** **VPS hanya dipertimbangkan setelah Paper Trading berjalan stabil tanpa interupsi di laptop lokal selama minimal 2 minggu berturut-turut.**
- **Rasional:** Tidak ada urgensi menyewa server selama fase perancangan, unit testing, dan integrasi awal.
- **Konsekuensi / Dampak:** Pengujian lokal menghemat anggaran operasional. Arsitektur Docker Compose dirancang portabel sehingga mudah dipindahkan ke VPS Linux Ubuntu kapan saja.

---

### Q-11: Apakah Bot Telegram hanya berfungsi sebagai penerima notifikasi atau juga menerima perintah kontrol?
- **Rekomendasi Sementara:** **Hibrida: Notifikasi otomatis untuk seluruh kejadian penting, ditambah perintah kendali darurat dan informasi status dasar.**
- **Rasional:** Pengguna memerlukan cara cepat untuk memantau status atau mematikan sistem tanpa harus membuka antarmuka web.
- **Konsekuensi / Dampak:** Bot Telegram mengimplementasikan command handler terotentikasi:
  - `/status` : Menampilkan ringkasan PnL, posisi terbuka, dan kesehatan sistem.
  - `/pause` : Menghentikan sementara pembuatan order baru.
  - `/resume` : Mengaktifkan kembali sistem setelah peninjauan.
  - `/kill` : Pemicu *Emergency Stop* darurat.
  Setiap pesan dari *chat ID* yang tidak terdaftar akan diabaikan tanpa respons.

---

### Q-12: Provider LLM apa saja yang tersedia dan bagaimana ketentuan penggunaannya?
- **Rekomendasi Sementara:** **OpenRouter sebagai provider primer dan 9Route sebagai cadangan (*fallback*); Model default yang disarankan: model dengan rasio biaya/performa tinggi (misal `anthropic/claude-3.5-haiku`, `meta-llama/llama-3.1-70b-instruct`, atau `google/gemini-flash-1.5`).**
- **Rasional:** Fleksibilitas beralih antar model tanpa mengubah kode adapter, memanfaatkan free tier atau kuota terjangkau.
- **Konsekuensi / Dampak:** Lapisan AI Model Gateway harus membungkus pemanggilan dengan batas token maksimum (*max_tokens: 1000*), timeout 15 detik, dan fallback otomatis ke provider sekunder jika provider primer mengalami error HTTP 429/500.

---

### Q-13: Apa saja persyaratan mutlak (*Prerequisites*) untuk mengaktifkan Live Trading di masa depan (Fase 7)?
- **Rekomendasi Sementara:**
  1. Paper trading telah berjalan stabil minimal 30 hari kalender dengan Net PnL positif setelah memperhitungkan fee dan slippage.
  2. Zero unhandled exceptions / crash pada Trading Engine selama periode uji.
  3. Mekanisme *Kill Switch* telah diuji coba dan terbukti memutus koneksi transaksi dalam hitungan detik.
  4. Penggunaan *Burner Wallet* terisolasi dengan batas saldo maksimal yang ditentukan pengguna (misal maksimal 1-2 SOL).
  5. Pengguna menyetujui checklist keamanan secara eksplisit via antarmuka bertingkat dua (*2-Step Confirmation*).
- **Rasional:** Melindungi modal pengguna dari bug perangkat lunak dan fluktuasi ekstrem pasar Solana.
- **Konsekuensi / Dampak:** Live Trading terkunci secara permanen di tingkat arsitektur pada Fase 0 s.d. Fase 6.
