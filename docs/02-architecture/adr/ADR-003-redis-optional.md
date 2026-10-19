# ADR-003: Redis Sebagai Komponen Opsional (Bukan Dependensi Wajib MVP)
**Status:** Diterima (*Accepted*)  
**Tanggal:** 14 Oktober 2026  
**Penulis:** Principal Software Architect  
**Cakupan:** Lapisan Cache dan Antrean Pesan (*Messaging Queue*)  

---

## Konteks (Context)
Dalam arsitektur bot trading modern, Redis sering digunakan sebagai cache in-memory berkecepatan tinggi dan message broker untuk task queue (misalnya menggunakan Celery atau BullMQ).

Namun, untuk platform **AUTO-TRADE-AA**:
- Sistem beroperasi sebagai sistem **single-operator** di perangkat lokal MacBook M1 Pro.
- Frekuensi pemantauan wallet menggunakan polling periodik adaptif (10-30 detik).
- PostgreSQL 16 mampu menangani penulisan ratusan baris per detik dan caching buffer internalnya sudah sangat cepat.
- Menambahkan Redis sebagai dependensi wajib meningkatkan beban RAM kontainer Docker dan menambah satu titik kegagalan infrastruktur (*single point of failure*) yang harus dikelola saat inisialisasi awal.

---

## Keputusan (Decision)
Kami memutuskan bahwa **Redis berstatus OPSIONAL** dan **bukan dependensi wajib pada tahap MVP**.
1. Antrean tugas asinkron lokal dijalankan menggunakan mekanisme antrean in-memory Python (`asyncio.Queue`).
2. Caching jangka pendek (TTL < 30 detik untuk harga dan token blacklist) dikelola di memori proses backend.
3. Arsitektur kode menyediakan antarmuka cache abstrak (`CacheInterface`), sehingga Redis dapat diaktifkan melalui konfigurasi variabel lingkungan (`REDIS_ENABLED=true`) hanya jika kebutuhan terukur muncul di masa depan.

---

## Konsekuensi (Consequences)

### Positif:
- **Penghematan Memori Host:** Menghemat sekitar 256 MB s.d. 512 MB alokasi RAM di Docker Desktop MacBook M1 Pro.
- **Inisialisasi Lingkungan Sangat Cepat:** Setup kontainer lokal lebih sederhana (hanya butuh database PostgreSQL dan aplikasi backend).
- **Arsitektur Lebih Ramping:** Mengurangi ketergantungan software pihak ketiga pada fase perancangan dan pengujian awal.

### Negatif:
- **State In-Memory Tidak Bertahan Jika Restart:** Antrean task yang sedang berada di memori `asyncio.Queue` akan hilang jika proses backend me-restart mendadak (dapat dimitigasi dengan status persisten di tabel database).

### Netral / Mitigasi:
- Task kritis (sinyal dan order) selalu dicatat ke database PostgreSQL terlebih dahulu sebelum dieksekusi. Jika Redis diaktifkan di masa depan untuk VPS produksi, transisi kode hanya memerlukan pengalihan implementasi adapter.
