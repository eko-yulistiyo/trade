# KEBUTUHAN BISNIS (BUSINESS REQUIREMENTS)
**Dokumen:** `docs/01-requirements/BUSINESS_REQUIREMENTS.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Kebutuhan Bisnis  

---

## 1. Ringkasan Kebutuhan Bisnis
Dokumen ini mendefinisikan tujuan nilai, pendorong bisnis (*business drivers*), batasan operasional, serta kriteria keberhasilan bisnis yang melandasi perancangan platform **AUTO-TRADE-AA**. Tujuan utama bisnis adalah menyediakan infrastruktur otomasi analitik on-chain dan simulasi perdagangan aset kripto di jaringan Solana yang aman, terukur, dan bebas risiko finansial langsung pada fase evaluasi.

---

## 2. Pendorong Bisnis (Business Drivers)

| ID | Pendorong Bisnis | Deskripsi Kebutuhan |
|---|---|---|
| **BD-01** | **Asimetri Informasi di On-Chain Solana** | Kecepatan peluncuran token dan transfer likuiditas di Solana menuntut kemampuan agregasi dan analisis data otomatis yang melampaui kapasitas pengamatan manual manusia. |
| **BD-02** | **Mitigasi Penipuan & Token Eksploitatif** | Ekosistem koin meme dan token DEX rentan terhadap *rug pull*, *honeypot*, dan manipulasi likuiditas. Sistem bisnis membutuhkan gerbang verifikasi keselamatan token sebelum modal diperhitungkan. |
| **BD-03** | **Validasi Strategi Tanpa Kerugian Modal** | Diperlukan mekanisme pengujian komprehensif (*backtesting* dan *paper trading*) yang memperhitungkan *slippage* dan biaya jaringan sebelum strategi dipertimbangkan layak. |
| **BD-04** | **Efisiensi Biaya Operasional (Cost-Awareness)** | Memanfaatkan arsitektur lokal pada perangkat MacBook M1 Pro dan kuota gratis/terjangkau dari penyedia API (Helius, OpenRouter, 9Route) guna meminimalkan pengeluaran modal (*CapEx*) dan biaya operasional (*OpEx*). |
| **BD-05** | **Kendali Penuh & Transparansi Operator** | Operator harus memiliki kendali mutlak dan visibilitas 100% terhadap alasan di balik setiap sinyal, penolakan risiko, dan simulasi transaksi. |

---

## 3. Daftar Kebutuhan Bisnis (Business Requirements)

### BR-01: Pemantauan dan Penemuan Trader Berkinerja Tinggi (Trader Discovery)
- **Deskripsi:** Sistem harus mampu mengidentifikasi, memeringkat, dan memantau wallet di jaringan Solana yang memiliki rekam jejak konsisten berdasarkan metrik keuntungan bersih dari biaya (*fee-adjusted Net PnL*) dan kontrol risiko (*drawdown*).
- **Nilai Bisnis:** Memungkinkan operator mengidentifikasi pola aliran dana pintar (*smart money flow*) tanpa terjebak oleh akun manipulatif atau *wash traders*.
- **Ukuran Keberhasilan:** Menyaring minimal 50 kandidat wallet dan mengklasifikasikan performa mereka dengan metrik objektif.

### BR-02: Asistensi Analisis Cerdas Berbasis AI Tanpa Risiko Eksekusi
- **Deskripsi:** Sistem harus memanfaatkan model AI (via AI Model Gateway) untuk menyintesis konteks pasar, metadata keamanan kontrak token, dan menghasilkan rekomendasi sinyal terstruktur tanpa memberikan hak eksekusi transaksi langsung kepada model AI.
- **Nilai Bisnis:** Menghemat waktu analisis data kualitatif dan kuantitatif secara drastis dengan tetap menjaga keamanan modal melalui pemisahan peran (*separation of concerns*).
- **Ukuran Keberhasilan:** Seluruh keluaran AI berupa skema JSON terstruktur yang lolos uji sintaks dan batas logika bisnis.

### BR-03: Perlindungan Modal Melalui Gerbang Risiko Deterministik (Deterministic Risk Gate)
- **Deskripsi:** Setiap sinyal yang dihasilkan (baik dari bot copy-trade maupun model AI) wajib melalui modul penyaring risiko berbasis aturan kode yang tidak dapat dibatalkan atau dilewati (*non-bypassable*).
- **Nilai Bisnis:** Mencegah kerugian portofolio yang tidak terduga akibat halusinasi AI, anomali data harga, atau lonjakan *slippage* di bursa terdesentralisasi.
- **Ukuran Keberhasilan:** 0% insiden pelanggaran batas risiko yang lolos ke lingkungan eksekusi simulasi.

### BR-04: Lingkungan Simulasi Realistis (Paper Trading & Backtesting)
- **Deskripsi:** Sistem wajib menyediakan mesin simulasi perdagangan yang mencerminkan kondisi riil pasar on-chain, termasuk kalkulasi biaya transaksi (*network & DEX fees*), estimasi *slippage*, dan kemungkinan order gagal (*failed fill*).
- **Nilai Bisnis:** Memberikan keyakinan matematis dan statistik terhadap profitabilitas strategi sebelum mempertimbangkan penggunaan dana nyata di masa depan.
- **Ukuran Keberhasilan:** Selisih antara model estimasi slippage dan kondisi likuiditas aktual pool AMM tidak melebihi 15% deviasi relatif.

### BR-05: Antarmuka Kendali & Tanggap Darurat Terpadu
- **Deskripsi:** Operator harus dapat memantau portofolio secara visual melalui dashboard web dan menerima peringatan instan serta mengeksekusi penghentian darurat (*Kill Switch*) melalui Telegram.
- **Nilai Bisnis:** Menjamin responsivitas operator terhadap anomali pasar dalam hitungan detik di mana pun operator berada.
- **Ukuran Keberhasilan:** Eksekusi perintah penghentian darurat (`/kill`) dari Telegram mematikan seluruh engine pembuatan order dalam waktu ≤ 2 detik.

### BR-06: Kepatuhan Keamanan & Auditabilitas Menyeluruh
- **Deskripsi:** Sistem harus menyimpan jejak audit lengkap (*audit trail*) untuk setiap request LLM, evaluasi risiko, dan status order, serta tidak boleh menyimpan atau meminta kunci privat (*private keys*) pengguna selama fase MVP.
- **Nilai Bisnis:** Menghilangkan risiko pencurian dana (*zero custodial liability*) dan mempermudah investigasi pasca-analisis terhadap kegagalan strategi.
- **Ukuran Keberhasilan:** Tidak ada kebocoran kredensial atau private key dalam log sistem, dan 100% alur keputusan dapat ditelusuri kembali ke sumber data awal.
