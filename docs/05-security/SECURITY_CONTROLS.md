# KENDALI KEAMANAN DEFENSIF (SECURITY CONTROLS)
**Dokumen:** `docs/05-security/SECURITY_CONTROLS.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Keamanan  

---

Dokumen ini merinci implementasi kendali keamanan teknis bertingkat (*Defense-in-Depth*) yang diterapkan pada setiap lapisan platform **AUTO-TRADE-AA**.

---

## 1. Kendali Lapisan Antarmuka & API (API & Web Controls)

1. **Autentikasi Header API Statis (`X-API-Key`):**
   - Seluruh endpoint kontrol backend FastAPI (di luar `/health`) mewajibkan penyertaan header `X-API-Key` yang dicocokkan dengan variabel rahasia `BACKEND_API_SECRET`.
   - Permintaan tanpa header atau dengan nilai yang salah ditolak dengan HTTP `401 Unauthorized`.
2. **Pembatasan Lintas Sumber Ketat (CORS Policy):**
   - Middleware CORS FastAPI hanya mengizinkan origin dari antarmuka web lokal:  
     `allow_origins = ["http://localhost:3000", "http://127.0.0.1:3000"]`.
   - Penggunaan wildcard (`*`) dilarang keras.
3. **Penyaringan Ukuran Payload:**
   - Pembatasan ukuran maksimum request HTTP masuk dibatasi hingga 1 MB untuk mencegah serangan buffer overflow atau kehabisan memori.

---

## 2. Kendali Lapisan Pemrosesan AI & Middleware (AI & Pipeline Controls)

1. **Penegakan Validasi Skema Pydantic Ketat:**
   - Menggunakan mode `extra = "forbid"` pada model Pydantic. Respons dari model AI yang menyertakan atribut asing atau menyimpang dari struktur yang ditentukan langsung ditolak.
2. **Isolasi Konteks Metadata Tidak Terpercaya:**
   - Seluruh string masukan on-chain dibersihkan dari karakter kontrol biner dan dibatasi panjangnya maksimal 255 karakter sebelum disisipkan ke dalam template prompt.
3. **Circuit Breaker Pemanggilan Model:**
   - Jika terjadi 3 kali kegagalan berturut-turut pada provider primer (OpenRouter), koneksi dialihkan otomatis ke 9Route dengan timeout 15 detik.

---

## 3. Kendali Lapisan Basis Data (Database Controls)

1. **Query Terparameter Penuh (Zero SQL Injection):**
   - Seluruh interaksi basis data menggunakan ORM SQLAlchemy/SQLModel dengan *parameterized queries*. Dilarang keras melakukan konkatenasi string mentah ke dalam klausa SQL.
2. **Prinsip Hak Akses Minimum Pengguna Database (Least Privilege DB User):**
   - Aplikasi backend terhubung ke PostgreSQL menggunakan akun pengguna khusus (`autotrade_app`), bukan pengguna superuser (`postgres`).
   - Akun aplikasi dilarang memiliki wewenang `SUPERUSER` atau hak untuk mengubah struktur skema secara langsung saat runtime.
3. **Integritas Konkruensi & Row Locking:**
   - Operasi pembaruan saldo kas dan status posisi menggunakan klausa `SELECT ... FOR UPDATE` dalam transaksi ACID untuk mencegah anomali *race condition* saat dua sinyal diproses serentak.

---

## 4. Kendali Lapisan Kontainer Docker (Container Hardening)

1. **Pengguna Kontainer Non-Root (Non-Root User):**
   - Image Dockerfile backend dan frontend dikonfigurasi untuk menjalankan proses menggunakan user non-root (misal `UID 1000:appuser`).
2. **Penerapan Batas Sumber Daya Fisik (Resource Quotas):**
   - Setiap kontainer memiliki batas keras RAM dan CPU di `docker-compose.yml` untuk mencegah salah satu kontainer memonopoli memori host MacBook M1 Pro.
3. **Pemisahan Jaringan Jembatan (Network Isolation):**
   - Database PostgreSQL tidak diekspos ke jaringan publik; port 5432 hanya diikat ke antarmuka localhost (`127.0.0.1:5432`) untuk kebutuhan inspeksi lokal operator.

---

## 5. Kendali Tanggap Darurat & Circuit Breaker (Safety Controls)

1. **Circuit Breaker 4 Pemicu Otomatis (Kotak 8):**
   - **Pemicu 1 (Daily Loss $\ge 2\%$):** Hentikan seluruh pembuatan entry order baru, batalkan order aktif yang belum terisi (*unfilled orders*), dan biarkan posisi terbuka dikelola oleh Stop Loss.
   - **Pemicu 2 (Drawdown $\ge 8\%$):** Bekukan seluruh modul strategi dan kirim peringatan darurat; memerlukan tinjauan manual operator sebelum dapat diaktifkan kembali.
   - **Pemicu 3 (Data Stale / RPC Outage):** Jika usia data harga $> 30$ detik, sistem otomatis masuk ke status *Fail-Closed*.
   - **Pemicu 4 (Anomali Slippage):** Jika eksekusi simulasi menghasilkan slippage $> 2\%$, hentikan strategi terkait dan catat ke log keamanan.
2. **Emergency Kill Switch Independen:**
   - Sakelar darurat dapat dipicu dalam 1 langkah melalui perintah Telegram `/kill` atau tombol darurat Dashboard.
   - Mekanisme ini memutus loop trading dalam waktu $\le 2.0$ detik secara independen tanpa bergantung pada respons LLM.
