# ADR-004: Pendekatan Paper Trading First dan Penonaktifan Live Trading pada MVP
**Status:** Diterima (*Accepted*)  
**Tanggal:** 14 Oktober 2026  
**Penulis:** Principal Software Architect / DevSecOps Engineer  
**Cakupan:** Kebijakan Eksekusi Perdagangan dan Manajemen Risiko Modal  

---

## Konteks (Context)
Pasar perdagangan aset kripto di jaringan Solana memiliki karakteristik likuiditas yang sangat volatil, dinamika slippage ekstrem, dan risiko keamanan kontrak yang tinggi (token scam, honeypot, rug pull). Menggabungkan model AI dan otomasi sinyal dengan eksekusi on-chain langsung menggunakan dana riil pada fase awal pengembangan membawa risiko kerugian finansial yang tidak dapat dipulihkan (*irreversible capital loss*) akibat:
1. Kesalahan pengkodean (*bugs*) pada kalkulasi sizing atau arah order.
2. Anomali respons model bahasa besar (*AI hallucination*).
3. Latensi jaringan atau kegagalan koneksi RPC saat transaksi sedang diproses.

---

## Keputusan (Decision)
Kami memutuskan untuk menerapkan prinsip **Paper Trading First**:
1. Seluruh sistem pada MVP (Fase 1 hingga Fase 6) **hanya mengeksekusi perdagangan secara virtual (*Paper Trading*)** dan simulasi historis (*Backtesting*).
2. Live Trading dinonaktifkan secara default di tingkat arsitektur kode dan skema basis data.
3. Fitur Live Trading dialokasikan ke **Fase 7 terpisah** dan tidak boleh diaktifkan secara otomatis tanpa audit keamanan menyeluruh, pengujian *Kill Switch* fisik, dan persetujuan eksplisit tertulis dari pengguna.
4. Sistem tidak menyimpan atau meminta *private key* atau *seed phrase* selama fase MVP.

---

## Konsekuensi (Consequences)

### Positif:
- **Nol Risiko Finansial Langsung (Zero Financial Risk):** Operator dapat menguji strategi, menganalisis performa AI, dan mengevaluasi copy-trade tanpa beban kecemasan kehilangan modal.
- **Auditabilitas Akuntansi Realistis:** Mesin Paper Broker dirancang untuk memperhitungkan biaya transaksi jaringan Solana dan estimasi slippage riil, menghasilkan data kinerja yang realistis dan bebas ilusi.
- **Ketiadaan Vektor Pencurian Kunci Privat:** Menghilangkan risiko eksfiltrasi private key melalui serangan siber, prompt injection, atau kebocoran log.

### Negatif:
- **Ketiadaan Keuntungan Finansial Riil:** Sistem belum dapat menghasilkan keuntungan moneter langsung selama periode pengujian.

### Netral / Mitigasi:
- Disiplin pengujian paper trading selama minimal 30 hari kalender akan memberikan data empiris yang valid untuk membuktikan apakah strategi memiliki keunggulan kompetitif (*edge*) sebelum dana riil dipertimbangkan.
