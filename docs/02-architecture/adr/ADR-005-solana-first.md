# ADR-005: Solana Sebagai Blockchain Tunggal Tahap MVP (Solana First)
**Status:** Diterima (*Accepted*)  
**Tanggal:** 14 Oktober 2026  
**Penulis:** Principal Software Architect / Blockchain Specialist  
**Cakupan:** Pemilihan Ekosistem Jaringan Blockchain  

---

## Konteks (Context)
Dalam perdagangan aset kripto dan copy-trading terdesentralisasi, pemilihan blockchain mendikte format data on-chain, jenis DEX AMM, biaya transaksi jaringan, dan kecepatan konfirmasi blok.

Kandidat blockchain:
1. **Ethereum Mainnet:** Sangat mapan, namun biaya gas sangat tinggi (seringkali > $10 - $50 per transaksi swap), membuat strategi frekuensi tinggi atau copy-trading modal kecil tidak layak secara ekonomi.
2. **EVM L2 (Arbitrum, Base):** Biaya gas rendah, namun volume perdagangan koin meme dan aktivitas trader ritel on-chain saat ini banyak terkonsentrasi di Solana.
3. **Solana:** Waktu pembuatan blok sub-detik (400ms), biaya transaksi sangat rendah (< $0.001 per transaksi), likuiditas DEX masif (Raydium, Orca), dan aktivitas copy-trading trader pintar (*smart money*) sangat aktif.
4. **Multi-Chain Sejak Awal:** Membangun abstraksi multi-chain sejak rilis pertama menambah beban kompleksitas teknis yang signifikan (mengelola Web3.js, Ethers.js, format tx yang berbeda, parsing event heterogen).

---

## Keputusan (Decision)
Kami memutuskan untuk fokus secara eksklusif pada **Solana** sebagai satu-satunya blockchain untuk tahap MVP (**Solana First**). Seluruh pipeline ingestion, penguraian instruksi DEX, verifikasi otoritas token, dan simulasi biaya dioptimalkan secara spesifik untuk Solana.

---

## Konsekuensi (Consequences)

### Positif:
- **Kecepatan & Kedalaman Integrasi:** Pengembang dapat memusatkan tenaga untuk membangun parser transaksi yang sangat presisi pada DEX Solana (Raydium, Orca, Jupiter) tanpa terganggu oleh perbedaan arsitektur EVM.
- **Biaya Transaksi Simulasi Rendah & Realistis:** Karakteristik fee jaringan Solana yang murah memungkinkan pemodelan transaksi frekuensi wajar tanpa beban fee yang memakan ekuitas simulasi.
- **Ekosistem Smart Money yang Kaya:** Banyak wallet trader berkinerja tinggi yang dapat dianalisis dan ditemukan di jaringan Solana.

### Negatif:
- **Keterbatasan Cakupan Pasar:** Peluang perdagangan pada jaringan EVM (Base, Ethereum, BSC) tidak dapat diakses selama fase MVP ini.

### Netral / Mitigasi:
- Skema basis data (tabel `tokens`, `wallets`, `paper_orders`) tetap menyertakan kolom `chain VARCHAR NOT NULL DEFAULT 'solana'` sehingga penambahan chain baru di masa depan dapat dilakukan dengan mudah tanpa mengubah struktur tabel relasional inti.
