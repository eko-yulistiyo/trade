# SUMBER DATA BLOCKCHAIN (BLOCKCHAIN DATA SOURCES)
**Dokumen:** `docs/02-architecture/BLOCKCHAIN_DATA_SOURCES.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Arsitektur  

---

Dokumen ini mendefinisikan strategi teknis integrasi, protokol penarikan, penguraian instruksi, dan manajemen kuota data on-chain dari blockchain **Solana**.

---

## 1. Karakteristik & Spesifikasi Data On-Chain Solana

Blockchain Solana memiliki karakteristik arsitektur berbasis akun (*Account-based*) berkecepatan tinggi yang memerlukan penanganan data spesifik:
1. **Transaction Signature:** Hash Base58 sepanjang 64 byte yang menjadi pengenal unik global transaksi.
2. **Tingkat Finalitas (Commitment Levels):**
   - `processed`: Blok telah diverifikasi oleh node lokal, rentan rollback. (Tidak digunakan untuk keputusan order).
   - `confirmed`: Blok telah diverifikasi oleh quorum validator (>66%). Digunakan sebagai standar deteksi sinyal cepat (*default ingest*).
   - `finalized`: Blok telah di-commit ke rantai secara permanen (>31 blok konfirmasi). Digunakan untuk audit dan rekonsiliasi akhir.
3. **Standar Token SPL & Account Model:** Saldo token tersimpan dalam *Associated Token Account* (ATA), bukan langsung di alamat wallet publik induk.

---

## 2. Penyedia Layanan RPC & Strategi Konsumsi Kuota

Untuk mengoptimalkan pengeluaran biaya pada fase MVP lokal (MacBook M1 Pro), sistem menerapkan strategi hibrida bertingkat:

| Kategori Sumber | Penyedia Layanan | Metode Akses | Batas Free Tier | Peruntukan Khusus |
|---|---|---|---|---|
| **RPC Primer** | **Helius** | HTTPS REST / WSS | 100.000 kredit/hari | Penguraian transaksi tingkat lanjut (*Enhanced Transaction API*) dan webhook swap DEX. |
| **RPC Sekunder** | **Solana Public / QuickNode Free** | JSON-RPC 2.0 | 25-50 request/detik | Pengambilan data read-only non-kritis (saldo SOL, snapshot blok, status akun). |
| **Market Data API** | **DEXScreener / Birdeye API** | HTTPS REST | Free Public Tier | Snapshot harga USD, likuiditas pool DEX, dan volume 24 jam. |

---

## 3. Protokol Penarikan Data (Ingestion Protocols)

### 3.1 Polling Periodik Adaptif (Adaptive Polling)
- Digunakan untuk memantau wallet target pada daftar `ACTIVE_MONITORED`.
- **Interval Polling:**
  - Wallet dengan aktivitas tinggi (terakhir aktif < 1 jam lalu): Interval 10 detik.
  - Wallet dengan aktivitas normal (terakhir aktif > 1 jam lalu): Interval 30 detik.
  - Wallet non-aktif (> 24 jam): Interval 60 detik.
- Menggunakan parameter `until: <last_seen_signature>` pada RPC `getSignaturesForAddress` untuk meminimalkan beban bandwidth dan jumlah data yang dikembalikan.

### 3.2 WebSocket Streaming (Untuk Token Aktif)
- Membuka koneksi WSS `logsSubscribe` atau `accountSubscribe` hanya untuk token yang sedang memiliki posisi terbuka di portofolio virtual atau sedang dalam pengawasan intensif.
- Koneksi WebSocket otomatis ditutup jika posisi token telah ditutup secara penuh guna menghemat koneksi jaringan.

---

## 4. Penguraian Transaksi Bursa Terdesentralisasi (DEX Parsing)

Sistem mendukung penguraian instruksi untuk protokol DEX terbesar di ekosistem Solana:

### 4.1 Raydium AMM v4
- **Program ID:** `675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8`
- **Pola Instruksi:** Swap Base In / Swap Base Out. Parser membaca mutasi akun token pada *inner instructions* untuk mencatat harga tukar efektif.

### 4.2 Orca Whirlpool (Concentrated Liquidity)
- **Program ID:** `whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc`
- **Pola Instruksi:** Instruksi `swap`. Parser mengekstrak parameter batas harga pergeseran (*sqrtPriceLimit*).

### 4.3 Jupiter Routing Aggregator v6
- **Program ID:** `JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4`
- **Pola Instruksi:** Agregasi multi-hop. Parser membaca akun token masukan pertama (*source token*) dan akun token keluaran terakhir (*destination token*) untuk mendapatkan nominal swap bersih.

---

## 5. Pengendalian Kuota & Penanganan Kegagalan RPC

1. **Credit Budget Tracker:** Modul memonitor perkiraan pemakaian kredit Helius harian. Jika pemakaian mencapai 85% dari kuota gratis harian, interval polling otomatis dilonggarkan ke 60 detik.
2. **Circuit Breaker RPC:** Jika node primer mengembalikan 3 kali berturut-turut pesan error atau HTTP 429, traffic dialihkan ke node publik cadangan.
3. **Data Freshness Gate:** Setiap data harga atau blok wajib memiliki atribut usia waktu (*timestamp age*). Jika usia data on-chain melebihi 30 detik dari waktu jam lokal sistem, data diklasifikasikan sebagai `STALE` dan menolak pembuatan order baru.
