# PERAN PENGGUNA DAN USE CASES (USER ROLES AND USE CASES)
**Dokumen:** `docs/01-requirements/USER_ROLES_AND_USE_CASES.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Peran & Use Cases  

---

Dokumen ini mendefinisikan aktor manusia dan sistem yang berinteraksi di dalam platform, serta memetakan skenario penggunaan utama (*Use Cases*) beserta alur langkah, pra-kondisi, dan pasca-kondisi operasionalnya.

---

## 1. Definisi Peran & Aktor Sistem (Actors & Roles)

### 1.1 Aktor Manusia
1. **Operator Sistem (Human Operator / Solo Trader):**
   - Pengguna tunggal dengan otoritas penuh atas sistem.
   - Bertanggung jawab meninjau wallet hasil penemuan, mengonfigurasi parameter batas risiko, menyetujui aktivasi strategi, memantau portofolio simulasi, dan memicu *Kill Switch* dalam keadaan darurat.

### 1.2 Aktor Perangkat Lunak Internal
2. **Hermes Orchestrator:**
   - Orkestrator tingkat sistem yang mengoordinasikan agen-agen analitik spesialis (Discovery, Token Safety, Market Context, Strategy Signal).
3. **Deterministic Risk Engine:**
   - Komponen penjaga gerbang keselamatan berbasis aturan kode yang mengevaluasi seluruh sinyal secara matematis dan logis tanpa toleransi bypass oleh AI.
4. **Paper Broker Simulator:**
   - Komponen pengeksekusi order virtual yang mencocokkan harga, menghitung *slippage*, membebankan biaya simulasi, dan memperbarui portofolio virtual.

### 1.3 Aktor Eksternal
5. **Solana RPC / WebSocket Provider (Helius/Public):**
   - Sumber penyedia data blok, saldo, signature, dan transaksi on-chain Solana.
6. **AI Model Gateway (OpenRouter, 9Route):**
   - Layanan penyedia inferensi model bahasa besar pihak ketiga.
7. **Telegram Bot API:**
   - Kanal komunikasi dua arah untuk pengiriman notifikasi dan penerimaan perintah kendali jarak jauh.

---

## 2. Matriks Pemetaan Use Case

| ID Use Case | Nama Use Case | Aktor Utama | Tujuan Utama |
|---|---|---|---|
| **UC-01** | Mengonfigurasi & Menyetujui Wallet Pantauan | Operator Sistem | Menambahkan wallet terpercaya ke daftar aktif copy-trade. |
| **UC-02** | Mendeteksi & Mengklasifikasi Transaksi Copy-Trade | Solana Ingestion Engine | Menangkap swap transaksi dari wallet target secara akurat. |
| **UC-03** | Menganalisis Keamanan Kontrak Token | AI Token Safety Agent | Memastikan token bebas dari bahaya mint/freeze authority. |
| **UC-04** | Menghasilkan Sinyal Perdagangan Terstruktur | AI Strategy Agent | Memformulasikan usulan tindakan (Buy/Sell/Hold). |
| **UC-05** | Mengevaluasi Sinyal melalui Risk Gate | Deterministic Risk Engine | Memvalidasi kepatuhan sinyal terhadap batas risiko statis. |
| **UC-06** | Mengeksekusi Order Paper Trading | Paper Broker Simulator | Mencocokkan order virtual dengan harga pasar riil. |
| **UC-07** | Memantau Portofolio & Audit Trail di Web | Operator Sistem | Meninjau performa simulasi dan rekaman keputusan sistem. |
| **UC-08** | Memicu Penghentian Darurat (Kill Switch) | Operator Sistem | Menghentikan seluruh operasi secara instan via Telegram/Web. |
| **UC-09** | Menjalankan Simulasi Backtesting Historis | Operator Sistem | Menguji keandalan strategi pada data pasar lampau. |
| **UC-10** | Menjeda & Melanjutkan Sistem (Pause/Resume) | Operator Sistem | Menghentikan sementara pembuatan order tanpa mematikan proses. |

---

## 3. Rincian Use Cases Utama

### UC-01: Mengonfigurasi & Menyetujui Wallet Pantauan
- **Aktor:** Operator Sistem
- **Pra-Kondisi:** Sistem telah mengumpulkan data kandidat wallet melalui modul Discovery atau input manual dari pengguna.
- **Alur Utama (Main Flow):**
  1. Operator membuka menu *Wallet Explorer* pada Dashboard Web.
  2. Operator meninjau metrik performa historis (Net PnL, Win Rate, Drawdown, Profit Factor).
  3. Operator mengklik tombol `Approve & Monitor` pada wallet yang dinilai konsisten.
  4. Sistem memperbarui status wallet menjadi `ACTIVE_MONITORED` di database.
  5. Modul Ingestion mulai menyertakan alamat wallet tersebut dalam siklus polling berikutnya.
- **Alur Alternatif (Reject/Remove):**
  - Pada langkah 3, operator mengklik `Reject / Remove`. Sistem mengubah status menjadi `ARCHIVED` dan tidak menyertakannya dalam pemantauan.
- **Pasca-Kondisi:** Wallet aktif dipantau untuk mendeteksi transaksi on-chain baru.

---

### UC-02: Mendeteksi & Mengklasifikasi Transaksi Copy-Trade
- **Aktor:** Solana Ingestion Engine, Solana RPC
- **Pra-Kondisi:** Terdapat minimal 1 wallet berstatus `ACTIVE_MONITORED`.
- **Alur Utama:**
  1. Ingestion Engine melakukan polling signature terbaru dari RPC Solana.
  2. Ditemukan signature transaksi baru yang belum ada di tabel `wallet_observations`.
  3. Ingestion Engine mengambil payload detail transaksi mentah.
  4. Engine mengurai instruksi dan memastikan bahwa transaksi adalah swap token di DEX (bukan transfer biasa).
  5. Sistem mencatat transaksi ke tabel `wallet_observations` dengan status `PARSED_SWAP`.
  6. Sistem memicu event pemicu ke Hermes Orchestrator untuk evaluasi copy-trading.
- **Alur Pengecualian (Bukan Swap):**
  - Pada langkah 4, jika transaksi terdeteksi sebagai transfer internal SOL atau SPL token, sistem mencatat status `IGNORED_TRANSFER` dan mengakhiri alur tanpa memicu sinyal.
- **Pasca-Kondisi:** Objek transaksi siap diproses oleh alur analisis dan strategi.

---

### UC-05: Mengevaluasi Sinyal melalui Risk Gate
- **Aktor:** Deterministic Risk Engine
- **Pra-Kondisi:** Dihasilkan objek `trading_signals` baru oleh modul strategi atau copy-trade.
- **Alur Utama:**
  1. Risk Engine mengambil sinyal dan membaca snapshot harga serta status portofolio saat ini.
  2. Risk Engine memeriksa usia snapshot harga (harus < 30 detik).
  3. Risk Engine memeriksa likuiditas pool token (harus ≥ $20.000 USD).
  4. Risk Engine memeriksa persentase alokasi dana yang diminta (harus ≤ 10% ekuitas).
  5. Risk Engine memeriksa batas kerugian harian portofolio (kerugian hari ini harus < 15%).
  6. Risk Engine memeriksa estimasi *slippage* (harus ≤ 2.0%).
  7. Seluruh aturan terpenuhi: Risk Engine mencatat record `risk_checks` dengan status `PASSED`.
  8. Sinyal diteruskan ke antrean Paper Broker untuk eksekusi order virtual.
- **Alur Alternatif (Pelanggaran Risiko):**
  - Jika salah satu aturan gagal (misal likuiditas hanya $10.000 USD):
    1. Risk Engine langsung menandai record `risk_checks` sebagai `REJECTED` beserta alasan spesifik (`REASON: INSUFFICIENT_LIQUIDITY`).
    2. Sinyal dibatalkan (*dropped*).
    3. Sistem mengirimkan pesan notifikasi penolakan ke Telegram operator.
- **Pasca-Kondisi:** Tidak ada order yang dibuat jika ada parameter keselamatan yang dilanggar.

---

### UC-06: Mengeksekusi Order Paper Trading
- **Aktor:** Paper Broker Simulator
- **Pra-Kondisi:** Sinyal telah lolos verifikasi `risk_checks` dengan status `PASSED`.
- **Alur Utama:**
  1. Paper Broker membuat record `paper_orders` berstatus `SUBMITTED`.
  2. Broker membaca harga eksekusi pasar saat ini dan menghitung estimasi slippage realistis (misal +0.5% untuk buy).
  3. Broker menghitung potongan biaya simulasi (Network Fee 0.000005 SOL + DEX Fee 0.25%).
  4. Broker membuat record `paper_trades` berstatus `FILLED`.
  5. Saldo kas virtual dikurangi dan saldo token virtual ditambahkan pada portofolio.
  6. Posisi diperbarui atau dibuat di tabel `positions`.
  7. Sistem mengirim notifikasi eksekusi sukses ke Telegram operator.
- **Pasca-Kondisi:** Posisi portofolio virtual tercatat secara akurat dan saldo kas terupdate.

---

### UC-08: Memicu Penghentian Darurat (Kill Switch)
- **Aktor:** Operator Sistem
- **Pra-Kondisi:** Sistem sedang berjalan dalam status `RUNNING`.
- **Alur Utama:**
  1. Operator mengirimkan perintah `/kill` melalui obrolan bot Telegram pribadi (atau menekan tombol `EMERGENCY STOP` di dashboard).
  2. Handler Telegram memverifikasi bahwa pengirim adalah `TELEGRAM_ALLOWED_USER_ID`.
  3. Sistem mengubah status global sistem menjadi `EMERGENCY_STOP` di database dan cache memori.
  4. Ingestion loop dan paper execution loop segera membatalkan pemrosesan task yang sedang berjalan.
  5. Seluruh sinyal yang sedang antre langsung dibatalkan (*purged*).
  6. Sistem mengirimkan balasan konfirmasi di Telegram: `"🚨 EMERGENCY STOP AKTIF: Seluruh pembuatan sinyal dan order telah dimatikan secara instan."`
- **Pasca-Kondisi:** Sistem berada dalam status terkunci (*locked closed*) dan menolak seluruh operasi baru hingga operator melakukan intervensi manual.
