# GERBANG KESELAMATAN TRADING LANGSUNG (LIVE TRADING SAFETY GATE)
**Dokumen:** `docs/05-security/LIVE_TRADING_SAFETY_GATE.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Keamanan  

---

Dokumen ini mendefinisikan batas arsitektur mutlak yang mengunci fitur perdagangan menggunakan dana riil (*Live Trading*) selama fase MVP, serta menetapkan kriteria prasyarat ketat yang wajib dipenuhi sebelum **Fase 7 (Live Trading)** dipertimbangkan.

---

## 1. Kebijakan Penguncian Live Trading pada MVP (Locked by Default)

1. **Penguncian Tingkat Arsitektur (Hardcoded Lock):**
   - Pada Fase 0 hingga Fase 6, kode sumber aplikasi **tidak memiliki fungsi penandatanganan transaksi blockchain (*signing transactions*)** menggunakan kunci privat.
   - Variabel konfigurasi `LIVE_TRADING_ENABLED` terkunci pada nilai `FALSE` secara mutlak dan tidak dapat diubah hanya dengan memodifikasi satu baris file `.env`.
2. **Ketiadaan Akses Saldo Riil:**
   - Seluruh transaksi dieksekusi oleh mesin simulator `Paper Broker` dengan saldo virtual di database PostgreSQL. Kesalahan pengkodean (*bugs*) atau anomali pasar tidak akan pernah mengakibatkan kerugian finansial nyata.

---

## 2. Persyaratan Mutlak Sebelum Memasuki Fase 7 (Prerequisites)

Fitur Live Trading **TIDAK BOLEH** diaktifkan atau dikembangkan sebelum seluruh 6 kriteria keselamatan berikut berstatus lulus (**PASS**):

### Kriteria 1: Periode Observasi Paper Trading Minimum 30 Hari
- Sistem paper trading wajib telah berjalan secara kontinu minimal **30 hari kalender berturut-turut** di lingkungan pengujian.
- Menghasilkan **Positive Expectancy ($E > 0$)** dan Net PnL positif setelah memperhitungkan biaya bursa Bybit Spot (0.1%) dan estimasi slippage realistis.

### Kriteria 2: Kepatuhan Drawdown & Stabilitas Tanpa Crash
- Selama 30 hari observasi, Maximum Drawdown portofolio simulasi **tidak pernah menyentuh atau melampaui batas 8.0%**.
- Tercatat **Zero Unhandled Exceptions / Crash** pada proses backend dan ingestion engine.

### Kriteria 3: Uji Petik Pemutusan Fisik Emergency Stop (Kill Switch Drill)
- Dilakukan simulasi pengujian tombol darurat `/kill` saat antrean pemrosesan sinyal sedang padat.
- Sistem terbukti memutus pembuatan order baru dalam waktu $\le 2.0$ detik sebanyak 5 kali pengujian berturut-turut tanpa kegagalan.

### Kriteria 4: Isolasi Modal Menggunakan Burner Wallet
- Jika live trading diaktifkan di masa depan:
  - Dilarang keras menggunakan dompet utama (*Main Wallet*) atau dompet penyimpan aset dingin (*Cold Storage*).
  - Wajib menggunakan **Burner Wallet** khusus dengan alokasi modal kecil yang diisolasi (misal maksimal 1-2 SOL atau setara $150-$300 USD).
  - Kehilangan saldo pada burner wallet tidak boleh mengancam kelangsungan finansial pengguna.

### Kriteria 5: Audit Kode Transaksi Mandiri (Independent Code Audit)
- Seluruh logika pembentukan transaksi Solana SPL dan penandatanganan instruksi DEX wajib diaudit secara baris per baris untuk memastikan ketiadaan *slippage uncapped* atau transfer tanpa batas.

### Kriteria 6: Persetujuan Eksplisit Pengguna (2-Step Human Confirmation)
- Live trading hanya dapat diaktifkan melalui checklist persetujuan tertulis formal dan konfirmasi dua langkah di antarmuka sistem.

---

## 3. Checklist Kesiapan Gerbang Keselamatan (Safety Gate Checklist)

| No | Parameter Kesiapan | Standar Target | Status Fase 0 |
|---|---|---|---|
| 1 | Masa Pengujian Paper Trading | $\ge 30$ Hari Kalender | **LOCKED (Belum Dimulai)** |
| 2 | Net Expectancy Portofolio | Positif ($E > 0$) Bersih Fee | **LOCKED** |
| 3 | Maximum Drawdown Historis | $< 8.0\%$ dari High-Water Mark | **LOCKED** |
| 4 | Stabilitas Backend Service | 0 Unhandled Crashes | **LOCKED** |
| 5 | Latensi Respons Emergency Stop | $\le 2.0$ Detik (Lolos Uji Drill) | **LOCKED** |
| 6 | Penggunaan Burner Wallet Terisolasi | Saldo Terkunci $\le 2$ SOL | **LOCKED** |
| 7 | Persetujuan Eksplisit Tertulis Operator | Ditandatangani Formal | **LOCKED** |

---

> [!CAUTION]
> Mengabaikan salah satu kriteria di atas atau mengaktifkan live trading secara prematur melanggar prinsip dasar keselamatan proyek dan membawa risiko kehilangan seluruh modal yang diperdagangkan.
