# ADR-001: Penggunaan Pola Arsitektur Modular Monolith
**Status:** Diterima (*Accepted*)  
**Tanggal:** 14 Oktober 2026  
**Penulis:** Principal Software Architect  
**Cakupan:** Struktur Sistem dan Organisasi Kode  

---

## Konteks (Context)
Platform **AUTO-TRADE-AA** memerlukan integrasi erat antara beberapa domain fungsional: penarikan data blockchain (Solana Ingestion), orkestrasi kecerdasan buatan (Hermes Multi-Agent), evaluasi kebijakan keselamatan (Deterministic Risk Engine), simulasi pencocokan order (Paper Broker), dan antarmuka kontrol (REST API & Telegram Bot).

Terdapat pilihan arsitektur:
1. **Microservices:** Memecah setiap modul menjadi layanan kontainer terpisah yang berkomunikasi melalui gRPC/HTTP dan message broker (Kafka/RabbitMQ).
2. **Modular Monolith:** Membangun seluruh subsistem dalam satu basis kode Python terpadu, namun memisahkan modul secara tegas ke dalam paket-paket domain mandiri dengan batasan dependensi satu arah.

Sistem saat ini ditargetkan berjalan secara lokal pada perangkat MacBook M1 Pro (RAM 16 GB) untuk kebutuhan satu pengguna (single operator) pada fase MVP.

---

## Keputusan (Decision)
Kami memutuskan untuk mengadopsi pola **Modular Monolith** sebagai arsitektur inti backend. Seluruh domain ditempatkan dalam paket Python yang terisolasi dengan kontrak antarmuka yang jelas (`interfaces/`), dan dijalankan dalam satu proses/kontainer backend terpadu.

---

## Konsekuensi (Consequences)

### Positif:
- **Efisiensi Sumber Daya Host:** Tidak ada overhead memori akibat menjalankan puluhan runtime service terpisah di MacBook M1 Pro.
- **Kesederhanaan Transaksi & Konsistensi Data:** Memanfaatkan transaksi ACID lokal database PostgreSQL tanpa kerumitan konsistensi terdistribusi (*distributed transactions / 2-phase commit*).
- **Kecepatan Pengembangan & Refaktorisasi:** Debugging, penulisan pengujian unit/integrasi, dan tracing log jauh lebih mudah karena seluruh alur dapat ditelusuri dalam satu proses.
- **Kemudahan Deployment:** Hanya membutuhkan satu kontainer backend di Docker Compose.

### Negatif:
- **Skalabilitas Komponen Independen:** Seluruh modul berbagi proses yang sama; jika salah satu modul mengalami CPU spike berat, modul lain dapat terpengaruh jika tidak dikelola dengan asynchronous I/O yang tepat.

### Netral / Mitigasi:
- Kode dirancang dengan prinsip pemisahan domain yang ketat. Jika di masa depan salah satu komponen (misalnya Solana Ingestion intensif) membutuhkan penskalaan mandiri, modul tersebut siap diekstrak menjadi microservice tanpa merombak logika bisnis internal.
