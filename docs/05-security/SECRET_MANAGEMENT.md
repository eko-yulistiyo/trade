# PENGELOLAAN RAHASIA DAN KREDENSIAL (SECRET MANAGEMENT)
**Dokumen:** `docs/05-security/SECRET_MANAGEMENT.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Keamanan  

---

Dokumen ini mendefinisikan standar ketat dalam pengelolaan kunci API, token bot, kredensial basis data, serta prosedur perlindungan dari kebocoran informasi rahasia.

---

## 1. Kebijakan Nol Rahasia di Repositori (Zero Secrets in Git)

1. **Aturan File `.env` & `.gitignore`:**
   - Seluruh nilai kredensial hanya disimpan dalam file lokal `.env` pada lingkungan mesin host pengembang.
   - File `.env` terdaftar di baris pertama file `.gitignore` dan dilarang keras di-commit ke Git.
2. **Standar File `.env.example`:**
   - Repositori hanya menyediakan file templat `.env.example` yang memuat nama-nama variabel konfigurasi dengan nilai placeholder buatan (*dummy placeholders*):
     ```env
     # Template Konfigurasi Aman (.env.example)
     BACKEND_API_SECRET=change_me_to_a_random_32_char_secret
     POSTGRES_DB=autotrade_db
     POSTGRES_USER=autotrade_app
     POSTGRES_PASSWORD=change_me_to_a_strong_password
     
     # AI Model Gateway Credentials
     OPENROUTER_API_KEY=your_openrouter_api_key_here
     NINEROUTE_API_KEY=your_9route_api_key_here
     
     # Blockchain Data Credentials
     HELIUS_API_KEY=your_helius_api_key_here
     SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
     
     # Bybit Spot API
     BYBIT_API_KEY=your_bybit_public_api_key_here
     BYBIT_API_SECRET=your_bybit_secret_key_here
     
     # Telegram Bot
     TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ
     TELEGRAM_ALLOWED_USER_ID=987654321
     TELEGRAM_ALLOWED_CHAT_ID=987654321
     ```

---

## 2. Penyamaran Log Otomatis (Log Sanitization & Redaction)

Sistem menerapkan filter log khusus (*logging filter middleware*) yang memindai setiap string sebelum dicatat ke stdout atau file log:
1. **Penyamaran Header Sensitif:**
   Header seperti `Authorization`, `X-API-Key`, `api-key`, dan `token` secara otomatis diganti dengan string bertopeng:  
   `Authorization: Bearer sk-or-v1-****...[REDACTED]`
2. **Pembersihan Log Database:**
   Tabel `llm_requests` hanya mencatat ringkasan prompt (`request_prompt_summary`) dan dilarang mencatat raw header HTTP yang mengandung API Key penyedia.

---

## 3. Isolasi Mutlak Kunci Privat Blockchain (Zero Private Key in MVP)

1. **Ketiadaan Kunci Privat di Seluruh Lapisan:**
   - Pada fase MVP (Fase 1 s.d. 6), sistem tidak meminta, tidak mengimpor, dan tidak menghasilkan *private key* atau *seed phrase* apa pun.
   - Transaksi dilakukan murni secara simulasi (*Paper Trading*) di dalam memori database lokal.
2. **Pencegahan Eksfiltrasi Melalui Model AI:**
   - Karena kunci privat tidak pernah ada di memori sistem, risiko eksfiltrasi kunci privat melalui serangan *prompt extraction* atau kebocoran model bahasa besar adalah **0% (Mustahil Terjadi)**.

---

## 4. Pemindaian Rahasia Otomatis (Automated Secret Scanning)

Sebelum rilis atau commit git dijalankan:
- Pengembang dianjurkan menjalankan pemindai rahasia lokal (*Trufflehog* atau *Git-Secrets*) untuk mendeteksi pola regex kunci API kripto, token bot Telegram, dan string heksadesimal privat.
- Jika ditemukan file yang tidak sengaja memuat token rahasia, token tersebut wajib langsung dicabut (*revoked & rotated*) melalui dashboard penyedia terkait, dan riwayat commit dibersihkan.
