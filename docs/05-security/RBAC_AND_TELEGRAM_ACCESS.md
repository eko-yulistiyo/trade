# KONTROL AKSES RBAC DAN OTORISASI TELEGRAM (RBAC AND TELEGRAM ACCESS)
**Dokumen:** `docs/05-security/RBAC_AND_TELEGRAM_ACCESS.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Keamanan  

---

Dokumen ini mendefinisikan mekanisme otorisasi, pembatasan akses pengguna tunggal (*single-operator RBAC*), dan protokol verifikasi perintah melalui bot Telegram.

---

## 1. Model Kontrol Akses Berbasis Peran (Single-Operator RBAC)

Platform dirancang untuk melayani **Satu Pengguna Utama (Operator Solo)** yang memegang hak administratif penuh. Tidak ada registrasi multi-user publik pada tahap MVP.

| Peran Pengguna | Deskripsi Peran | Hak Akses yang Diizinkan | Batasan Akses |
|---|---|---|---|
| **System Operator (Admin)** | Pemilik platform dan pengendali sistem independen. | • Akses penuh ke Web Dashboard.<br/>• Persetujuan/penolakan wallet.<br/>• Konfigurasi parameter batas risiko.<br/>• Pemicu perintah darurat (/kill). | Dilarang mengaktifkan live trading sebelum checklist Fase 7 disetujui. |
| **Anonymous / Public** | Pihak luar di internet atau pengguna Telegram acak. | **TIDAK ADA** (Zero Access). | Seluruh request HTTP atau chat Telegram ditolak/diabaikan. |

---

## 2. Protokol Otorisasi Bot Telegram (Strict Allowlist Protocol)

Bot Telegram merupakan kanal kontrol jarak jauh yang krusial. Untuk mencegah eksploitasi perintah:

```
[ Pesan Masuk dari Telegram API ]
                │
                ▼
  [ Ekstraksi `message.from_user.id` & `chat.id` ]
                │
                ▼
  { Apakah `from_user.id == TELEGRAM_ALLOWED_USER_ID`? }
                │
        ┌───────┴───────┐
        ▼ (TIDAK)       ▼ (YA: Terotentikasi)
 [ SILENT IGNORE ]  [ Periksa Jenis Perintah ]
  - Jangan balas     ├── `/status` ──► Kirim Ringkasan Portofolio
  - Catat ke log     ├── `/pause`  ──► Ubah Status: PAUSED
    keamanan         ├── `/resume` ──► Ubah Status: RUNNING
                     └── `/kill`   ──► Pemicu EMERGENCY STOP Seketika
```

### 2.1 Kebijakan Penolakan Tanpa Suara (Silent Ignore)
- Jika pesan berasal dari ID Telegram yang tidak terdaftar dalam `TELEGRAM_ALLOWED_USER_ID`, bot **TIDAK AKAN** mengirimkan pesan penolakan seperti *"Access Denied"*.
- Pesan diabaikan sepenuhnya (*dropped silently*) untuk mencegah penyerang mengetahui keberadaan atau fungsi aktif bot tersebut (*prevent reconnaissance*).
- Upaya akses tidak sah dicatat dalam tabel `system_events` dengan tingkat keparahan `WARNING`.

### 2.2 Konfirmasi Dua Langkah untuk Aksi Kritis (2-Step Confirmation)
- Untuk perintah berisiko tinggi seperti penghapusan database atau pembukaan kembali strategi setelah Circuit Breaker Drawdown 8%:
  - Bot meminta konfirmasi lanjutan: `"Ketik '/confirm_reset_circuit' dalam 60 detik untuk melanjutkan."`
  - Perintah dibatalkan otomatis jika batas waktu 60 detik terlewati tanpa konfirmasi.

---

## 3. Otentikasi API Internal Dashboard (REST API Security)

1. **Header API Key Rahasia (`X-API-Key`):**
   - Komunikasi antara antarmuka Next.js dan backend FastAPI dilindungi oleh token statis 32-karakter acak yang dimuat saat kontainer dijalankan.
2. **Pencegahan Brute-Force (Rate Limiting Lokal):**
   - Endpoint API menerapkan pembatasan laju panggilan (*rate limiter*) maksimal **60 request/menit per IP lokal** untuk endpoint mutasi data guna mencegah spam permintaan internal.
