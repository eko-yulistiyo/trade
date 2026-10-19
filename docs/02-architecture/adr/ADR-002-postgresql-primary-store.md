# ADR-002: PostgreSQL Sebagai Sumber Kebenaran Tunggal (Primary Datastore)
**Status:** Diterima (*Accepted*)  
**Tanggal:** 14 Oktober 2026  
**Penulis:** Data Architect / Senior Backend Engineer  
**Cakupan:** Lapisan Penyimpanan Data dan Persistensi  

---

## Konteks (Context)
Sistem **AUTO-TRADE-AA** mengelola berbagai jenis data:
1. Hubungan entitas ketat: Wallet, Observasi, Token, Sinyal, Cek Risiko, Order, Trade, dan Posisi.
2. Integritas finansial & akuntansi: Pembukuan saldo kas virtual dan posisi perdagangan memerlukan jaminan ACID mutlak untuk mencegah saldo negatif atau pencatatan ganda.
3. Kebutuhan query analitik dan time-series: Snapshot harga pasar dan riwayat eksekusi backtesting.
4. Audit trail: Log permintaan AI dan keputusan risiko yang tidak boleh hilang atau rusak.

Kandidat teknologi database:
- **SQLite:** Ringan, namun memiliki batasan konkruensi penulisan (*database lock*) saat ingestion dan web dashboard berjalan serentak.
- **MongoDB / NoSQL:** Fleksibel untuk payload JSON mentah, tetapi lemah dalam integritas relasional, foreign keys, dan transaksi multi-dokumen yang ketat untuk akuntansi.
- **PostgreSQL 16:** Database relasional open-source matang, dukungan JSONB terindeks sangat kuat, transaksi ACID tangguh, dan performa tinggi.

---

## Keputusan (Decision)
Kami memutuskan untuk menggunakan **PostgreSQL 16** sebagai sumber kebenaran tunggal (*Single Source of Truth*) untuk seluruh data operasional, relasional, akuntansi simulasi, dan log audit sistem.

---

## Konsekuensi (Consequences)

### Positif:
- **Jaminan Konsistensi Finansial (ACID):** Mencegah korupsi data saldo, posisi, atau eksekusi order pada kondisi konkruensi tinggi.
- **Fleksibilitas Hibrida Relasional + JSONB:** Data transaksi terstruktur disimpan dalam kolom relasional dengan constraint dan foreign key, sementara metadata fleksibel dari blockchain atau respons mentah LLM disimpan dalam kolom `JSONB`.
- **Dukungan Indeks Tingkat Lanjut:** Indeks B-Tree, Hash, dan GIN pada kolom JSONB memungkinkan pencarian cepat pada signature transaksi dan riwayat token.
- **Portabilitas Tinggi:** Berjalan stabil di dalam Docker Compose lokal M1 Pro dan mudah dipindahkan ke server VPS atau layanan cloud managed database di masa depan.

### Negatif:
- **Konsumsi Sumber Daya:** PostgreSQL membutuhkan alokasi memori khusus (sekitar 512 MB hingga 2 GB RAM) dibandingkan SQLite yang berbasis file embedded.

### Netral / Mitigasi:
- Alokasi RAM PostgreSQL di Docker Compose dibatasi pada batas aman 2.0 GB dengan tuning parameter buffer yang efisien (`shared_buffers = 256MB`).
