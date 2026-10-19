# KEBIJAKAN RETENSI DATA (DATA RETENTION POLICY)
**Dokumen:** `docs/04-data/DATA_RETENTION.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Basis Data  

---

Dokumen ini menetapkan aturan masa simpan data (*retention window*), strategi pemadatan (*partitioning & pruning*), serta jadwal pemeliharaan otomatis untuk mencegah pembengkakan ruang penyimpanan SSD pada MacBook M1 Pro.

---

## 1. Klasifikasi Tingkat Retensi Data (Retention Tiers)

Data di dalam basis data PostgreSQL 16 dikelompokkan ke dalam 3 tier retensi berdasarkan nilai audit dan frekuensi penambahan data:

| Kategori Tier | Tabel Terkait | Estimasi Pertumbuhan Harian | Masa Simpan Maksimal | Tindakan Pasca Kedaluwarsa |
|---|---|---|---|---|
| **Tier 1: High-Frequency Time-Series** | `market_snapshots`, kolom `raw_payload` pada `wallet_observations` | ~50.000 s.d. 100.000 baris/hari (~50-100 MB/hari) | **14 s.d. 30 Hari** | **Automated Hard Delete / Drop Partition** setelah 30 hari. |
| **Tier 2: AI & Risk Audit Trail** | `agent_runs`, `llm_requests`, `risk_checks`, `system_events` | ~1.000 s.d. 5.000 baris/hari (~5-10 MB/hari) | **90 Hari** | **Arsip / Vacuum Delete** baris yang lebih tua dari 90 hari. |
| **Tier 3: Permanent Financial Ledger** | `wallets`, `tokens`, `strategies`, `strategy_versions`, `trading_signals`, `paper_orders`, `paper_trades`, `positions`, `portfolio_snapshots` | ~50 s.d. 200 baris/hari (< 1 MB/hari) | **Permanen (Min. 1 Tahun)** | Dipertahankan permanen untuk rekapitulasi performa dan audit akuntansi. |

---

## 2. Strategi Partisi Tabel Time-Series (Table Partitioning)

Tabel `market_snapshots` memiliki volume baris tertinggi karena mencatat harga per menit untuk puluhan aset. Untuk menjaga performa query tetap instan tanpa degradasi performa B-Tree index:
- Menggunakan fitur **PostgreSQL Declarative Table Partitioning by Range** berdasarkan kolom `snapshot_time`.
- Partisi dibuat per minggu atau per bulan:  
  `market_snapshots_y2026m10`, `market_snapshots_y2026m11`.
- **Penghapusan Cepat (Zero Overhead Pruning):**  
  Alih-alih menjalankan query `DELETE FROM market_snapshots WHERE snapshot_time < NOW() - INTERVAL '30 days'` yang memicu I/O berat dan *table bloat*, sistem cukup mengeksekusi:  
  `DROP TABLE market_snapshots_y2026m08;` secara instan dalam 1 milidetik.

---

## 3. Jadwal Pekerja Pemeliharaan Otomatis (Housekeeping Routine)

Pekerja latar belakang (*background maintenance worker*) dijalankan setiap hari pada pukul **03:00 UTC** (saat aktivitas pasar relatif lebih tenang):
1. **Pruning Payload Mentah:** Mengosongkan kolom `raw_payload` pada record `wallet_observations` yang usianya sudah melebihi 14 hari:  
   `UPDATE wallet_observations SET raw_payload = NULL WHERE ingested_at < NOW() - INTERVAL '14 days';`
2. **Pembersihan Log Audit Usang:** Menghapus data `llm_requests` yang lebih tua dari 90 hari.
3. **Optimasi Ruang Disk (`VACUUM ANALYZE`):** Menjalankan `VACUUM (ANALYZE)` harian pada tabel-tabel transaksi aktif untuk mereklamasi ruang penyimpanan dan memperbarui statistik query planner.

---

## 4. Batasan Alokasi Disk Host (MacBook M1 Pro Budget)
- Total ukuran direktori database `./.data/postgres_data` dibatasi maksimal **10.0 GB**.
- Jika ukuran volume database terdeteksi melampaui **8.0 GB (80% threshold)**, sistem memicu notifikasi peringatan `DISK_SPACE_WARNING` ke Telegram dan otomatis memperpendek retensi `market_snapshots` dari 30 hari menjadi 14 hari.
