# PIAGAM PROYEK (PROJECT CHARTER)
**Dokumen:** `docs/00-overview/PROJECT_CHARTER.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi  

---

## 1. Tujuan Proyek yang Terukur (Measurable Objectives)
1. **Penyelesaian Fondasi Dokumentasi (Tahap 0):** Menyelesaikan 100% spesifikasi arsitektur, ERD, flowmap, kamus data, dan rencana mitigasi risiko sebelum baris kode aplikasi pertama ditulis.
2. **Keterandalan Analisis On-Chain:** Mencapai akurasi penguraian transaksi (*transaction parsing*) wallet Solana minimal 95% untuk transfer token dan interaksi DEX (Raydium/Orca) pada data historis uji coba.
3. **Penyaringan Risiko Deterministik Mutlak:** Memastikan 100% order simulasi melewati gerbang validasi risiko tanpa ada pengecualian yang dapat dipicu oleh model AI (*zero bypass rate*).
4. **Efisiensi Sumber Daya Lokal:** Seluruh tumpukan aplikasi (Backend, DB, Frontend, Gateway) mampu berjalan stabil di MacBook M1 Pro (RAM 16 GB) dengan konsumsi memori gabungan di bawah 10 GB dalam kondisi beban kerja standar.
5. **Observabilitas dan Audit Trail:** Mencatat 100% entri siklus dari penerimaan sinyal, keputusan risiko (*pass/reject*), hingga eksekusi order virtual ke dalam database audit.

---

## 2. Deliverables (Hasil Akhir yang Diserahkan)

### Fase 0 — Dokumentasi & Desain Arsitektur
- Dokumen spesifikasi bisnis, fungsional, dan non-fungsional.
- Desain arsitektur sistem, modul, konteks sistem, dan arsitektur deployment.
- Diagram alur kerja lengkap (Mermaid): System Context, Data Flow, Trading Flowchart, Copy-Trading Flowchart, Wallet Discovery Flowchart, Paper Trading Flowchart, ERD, dan Deployment Flowmap.
- Kamus data, spesifikasi skema relasional PostgreSQL, dan kebijakan retensi data.
- Kerangka model ancaman (*Threat Model*), panduan DevSecOps, dan spesifikasi gerbang keselamatan trading langsung (*Safety Gate*).
- Rencana pengujian komprehensif dan rincian task implementasi bertahap (Fase 1 s.d. 7).

### Fase 1 s.d. 6 — Implementasi Minimum Viable Product (MVP)
- **Lingkungan Kontainer:** Konfigurasi `docker-compose.yml` lokal untuk PostgreSQL, API, dan UI.
- **Backend Service (Python FastAPI):** Engine ingestion data Solana, adapter AI Gateway, orchestrator Hermes, Risk Engine, dan Paper Broker Simulator.
- **Frontend Dashboard (Next.js):** Dashboard interaktif untuk pemantauan sinyal, metriks wallet, status risiko, dan performa portofolio simulasi.
- **Bot Integrasi Telegram:** Bot notifikasi real-time dan pengendali perintah darurat terotentikasi (*Emergency Stop / Kill Switch*).
- **Automated Test Suite:** Unit testing, integration testing, backtesting engine, dan validasi paper trading.

---

## 3. Batasan Cakupan: In-Scope vs Out-of-Scope

### In-Scope (MVP)
- Pemantauan wallet terdaftar di blockchain Solana melalui RPC/WebSocket.
- Discovery wallet berbasis kriteria matematis terukur (PnL bersih biaya, drawdown, konsistensi aktivitas).
- Normalisasi dan deduping data transaksi on-chain.
- Multi-agent workflow untuk analisis token (keamanan mint, likuiditas pool) dan analisis pasar.
- Adapter AI Model Gateway (OpenRouter, 9Route) dengan output berformat JSON terstruktur.
- Rule-based Risk Engine (Stop Loss, Max Position Size, Daily Loss Limit, Max Slippage, Blacklist Token).
- Simulasi perdagangan virtual (*Paper Trading*) dan mesin pengujian historis (*Backtesting*).
- Notifikasi Telegram dan command bot untuk kontrol sistem dasar.
- Logging audit lengkap untuk setiap request LLM dan keputusan eksekusi order.

### Out-of-Scope (Dikeluarkan dari MVP)
- **Live Trading Otomatis dengan Dana Riil:** Dilarang keras pada MVP; berada pada Fase 7 terpisah dan memerlukan persetujuan eksplisit.
- **Dukungan Multi-Chain:** Tidak mendukung Ethereum, BSC, Arbitrum, Base, atau chain lain pada tahap awal.
- **Sistem Multi-User Publik / SaaS Komersial:** Tidak menyediakan registrasi publik, billing gateway, atau manajemen tenancy.
- **Mobile Native Application:** Tidak membuat aplikasi iOS/Android native (antarmuka mobile hanya melalui web responsif Next.js dan bot Telegram).
- **Akses Pengelolaan Private Key Otomatis:** Sistem MVP tidak menyimpan atau mengelola private key transaksi on-chain.

---

## 4. Pemangku Kepentingan & Peran (Stakeholders & Actors)
1. **Operator Sistem (User / Owner):** Pengambil keputusan utama yang mengonfigurasi strategi, menyetujui wallet yang dipantau, dan memegang kendali atas tombol darurat (*kill switch*).
2. **Hermes Agent Orchestrator:** Orkestrator alur kerja berbasis peran yang mengoordinasikan agen-agen analitik spesialis.
3. **Deterministic Risk Engine:** Komponen perangkat lunak otoritatif yang bertugas memvalidasi seluruh parameter keselamatan trading.
4. **External Infrastructure Providers:** Penyedia Solana RPC (Helius/QuickNode/Public), API Gateway AI (OpenRouter, 9Route), Telegram Bot API.

---

## 5. Ketergantungan Eksternal (Dependencies)
- Ketersediaan dan batas kecepatan (*rate limit*) API Solana RPC publik atau penyedia node gratis.
- Ketersediaan dan stabilitas jaringan API penyedia AI Model Gateway (OpenRouter, 9Route).
- Stabilitas Telegram Bot API untuk pengiriman pesan notifikasi.
- Ketersediaan Docker Desktop dan dependensi runtime Python/Node pada lingkungan host lokal.

---

## 6. Risiko Utama & Rencana Mitigasi Awal

| Risiko Utama | Tingkat Keparahan | Rencana Mitigasi |
|---|---|---|
| **Halusinasi LLM menghasilkan sinyal tidak realistis** | Kritis | Terapkan validasi skema JSON ketat; seluruh sinyal wajib melewati gerbang risiko deterministik sebelum dipertimbangkan oleh Paper Broker. |
| **RPC Solana mengalami kendala koneksi atau rate limit** | Tinggi | Terapkan caching harga lokal berumur pendek (*TTL 5-15 detik*), mekanisme antrean retry dengan *exponential backoff*, serta prinsip *fail-closed* (tolak order baru jika data stale). |
| **Kebocoran kredensial atau token API** | Kritis | Gunakan file `.env` yang diabaikan oleh Git (`.gitignore`); sediakan `.env.example` tanpa nilai rahasia; jangan mencatat rahasia ke log sistem. |
| **Keterbatasan RAM 16 GB pada host MacBook lokal** | Sedang | Optimasi profil memori kontainer Docker; jadikan Redis opsional; batasi jumlah agen yang berjalan secara konkruen. |
| **Sinyal copy-trade tertunda (*latency lag*)** | Sedang | Menghitung simulasi *slippage* realistis pada paper trading agar hasil simulasi tidak terdistorsi secara berlebihan. |

---

## 7. Kriteria Keberhasilan Proyek (Success Criteria)
1. Seluruh dokumen Tahap 0 (Arsitektur, ERD, Flowchart, Security, Roadmap) lengkap, konsisten, dan diaudit tanpa kontradiksi.
2. Sistem dapat melakukan backtesting strategi pada data historis Solana dengan laporan performa yang transparan dan bebas bias masa depan (*look-ahead bias*).
3. Paper trading engine dapat mencocokkan order simulasi dengan harga pasar aktual tanpa menimbulkan anomali portofolio atau kegagalan akuntansi.
4. Fitur Emergency Stop mampu menghentikan seluruh aktivitas pengambilan sinyal dan simulasi dalam waktu kurang dari 2 detik setelah dipicu melalui Telegram atau Dashboard.

---

## 8. Batasan Waktu & Biaya yang Belum Diketahui
- **Biaya Token AI Model:** Bergantung pada intensitas pemanggilan model dan token context window; estimasi awal menggunakan model efisien tier gratis/murah.
- **Biaya Solana RPC Tingkat Lanjut:** Jika frekuensi transaksi copy-trading membutuhkan WebSocket khusus berkecepatan tinggi, opsi langganan RPC berbayar akan dievaluasi setelah fase paper trading selesai.
- **Timeline Penyewaan VPS:** Biaya sewa VPS di Indonesia (Rp 150.000 - Rp 400.000/bulan) ditunda hingga platform stabil dan teruji secara lokal.
