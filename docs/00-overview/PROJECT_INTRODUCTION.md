# PENDAHULUAN PROYEK (PROJECT INTRODUCTION)
**Dokumen:** `docs/00-overview/PROJECT_INTRODUCTION.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0 - Dokumentasi Arsitektur)  
**Status:** Draf Arsitektur  
**Klasifikasi:** Internal Engineering & Operational Guidance  

---

## 1. Latar Belakang & Masalah
Perdagangan aset kripto—khususnya pada ekosistem berkecepatan tinggi seperti Solana—memiliki dinamika pasar yang sangat volatil, likuiditas yang cepat berpindah, dan volume transaksi desentralisasi (DEX) yang masif. Praktik perdagangan manual sering menghadapi kendala:
1. **Keterbatasan Kognitif & Informasi Asimetris:** Sulit memantau ribuan aktivitas wallet on-chain dan token baru secara serentak 24/7 tanpa alat otomatisasi.
2. **Sindrom FOMO & Jebakan Likuiditas (Rug Pull / Honeypot):** Trader ritel sering masuk ke token manipulatif akibat ketiadaan audit keamanan token instan dan analisis likuiditas yang objektif.
3. **Risiko Halusinasi & Ketidakpastian AI:** Model bahasa besar (LLM) mutakhir memiliki kapabilitas interpretasi data yang hebat, namun memiliki sifat probabilistik, dapat berhalusinasi, dan tidak dapat dipercaya untuk mengeksekusi dana tanpa validasi matematis deterministik.
4. **Kerentanan Keamanan & Eksekusi Prematur:** Banyak bot trading pihak ketiga mewajibkan penyerahan *private key* atau mengeksekusi transaksi live secara otonom tanpa batasan risiko (*circuit breaker*) dan tanpa pengawasan manusia (*human-in-the-loop*).

Platform **AUTO-TRADE-AA** dirancang untuk memecahkan permasalahan di atas dengan menggabungkan komputasi data on-chain terstruktur, orkestrasi multi-agent bertenaga AI, serta mesin manajemen risiko (*Risk Engine*) deterministik yang ketat dan transparan.

---

## 2. Visi Produk
Membangun platform analitik, simulasi, dan asisten trading kripto yang andal, aman, dapat diaudit, dan hemat biaya, yang mengutamakan simulasi tanpa risiko (*paper trading & backtesting*) sebelum interaksi on-chain langsung diizinkan.

---

## 3. Tujuan dan Hasil yang Diharapkan
1. **Discovery & Observasi Wallet Cerdas:** Mengidentifikasi dan memantau dompet (*smart money / high-performing traders*) di jaringan Solana berdasarkan metrik kinerja historis yang bersih dari biaya, drawdown, dan manipulasi.
2. **Analisis Komprehensif Multi-Dimensi:** Menyediakan sintesis pasar otomatis melalui agen AI spesialis (analisis token, metrik on-chain, sentimen pasar).
3. **Pemisahan Tegas antara Analisis Probabilistik dan Eksekusi Deterministik:** Agen AI hanya bertindak sebagai penasihat (*advisor/signal generator*); keputusan eksekusi order sepenuhnya dikunci oleh gerbang risiko (*risk gate*) berbasis aturan kode (*hard-coded rule engine*).
4. **Pengujian Strategi Bebas Risiko:** Menyediakan lingkungan *paper trading* dan *backtesting* terintegrasi yang menghitung biaya transaksi, estimasi *slippage*, dan kegagalan eksekusi secara realistis.
5. **Observabilitas & Kendali Terpusat:** Dashboard berbasis web modern dan Bot Telegram terotentikasi untuk pemantauan portofolio dan *emergency stop*.

---

## 4. Pengguna Sasaran (Target Audience)
- **Primary User / Operator Solo:** Pengembang perangkat lunak sekaligus trader independen yang mengoperasikan sistem di lingkungan lokal (MacBook M1 Pro) dengan kontrol penuh atas parameter risiko dan alur kerja.
- **Auditor Teknis / Pengawas Keamanan:** Entitas atau peran yang memastikan bahwa tidak ada kredensial bocor, seluruh sinyal tercatat dalam log audit yang tidak dapat dimanipulasi, dan seluruh gerbang risiko terpenuhi sebelum pertimbangan transaksi nyata.

---

## 5. Gambaran Kemampuan Utama (Core Capabilities)
- **Multi-Agent Orchestration (Hermes Agent):** Mengorkestrasikan tugas analitik spesialis (Discovery Agent, Token Safety Agent, Market Context Agent, Strategy Agent).
- **AI Model Gateway Adapter:** Abstraksi fleksibel untuk menghubungkan platform ke berbagai penyedia model AI (OpenRouter, 9Route, serta antarmuka OpenAI-compatible lainnya) dengan mekanisme *fallback*, batasan kuota, dan validasi output berstruktur (*structured JSON schema*).
- **Solana On-Chain Ingestion:** Pemantauan transaksi dan snapshot harga/likuiditas secara berkala melalui koneksi RPC/HTTP dan WebSocket.
- **Deterministic Risk Engine:** Pemeriksaan ambang batas absolut (maksimal alokasi per token, slippage maksimum, batas kerugian harian / *daily loss limit*, blacklist token, dan verifikasi likuiditas minimum).
- **Execution Simulator (Paper Broker):** Mesin simulasi pencocokan order yang merekonsiliasi posisi, saldo kas virtual, dan P&L (*realized/unrealized*).
- **Interactive Control Center:** Antarmuka web (Next.js) dan bot notifikasi Telegram dengan otorisasi berbasis *chat ID allowlist*.

---

## 6. Batasan MVP (Minimum Viable Product)
- **Tanpa Live Trading Otomatis:** MVP secara mutlak beroperasi pada mode simulasi (*paper trading*) dan *backtesting*. Tidak ada instruksi penandatanganan transaksi (*signing*) menggunakan *private key* di blockchain mainnet nyata.
- **Single-Chain Focus:** Solana adalah satu-satunya blockchain yang didukung pada MVP.
- **Single-User Architecture:** Sistem didesain untuk satu pengguna administratif tanpa sistem registrasi multi-tenant publik.
- **Deployment Lokal:** Dioperasikan secara lokal pada MacBook M1 Pro menggunakan Docker Compose; migrasi ke VPS bersifat opsional dan hanya dilakukan setelah evaluasi operasional.

---

## 7. Prinsip Keselamatan dan Auditabilitas (Safety & Auditability First)
1. **Safety First & Default Closed:** Saat terjadi gangguan data (RPC timeout, harga stale, API LLM error), sistem wajib bersikap *fail-closed*—semua pemrosesan order baru otomatis dibatalkan atau ditolak.
2. **Zero Private Keys in LLM Context:** Kunci privat, frasa pemulihan (*seed phrase*), token API rahasia, atau kredensial database tidak boleh dikirimkan ke prompt LLM atau dicatat ke log sistem.
3. **No Uncontrolled Agent Autonomy:** Agen AI tidak memiliki hak akses eksekusi langsung ke saldo atau order; mereka hanya menghasilkan objek sinyal terstruktur yang dapat disetujui, ditolak, atau diabaikan oleh mesin deterministik.
4. **Audit Trail Komprehensif:** Setiap siklus analisis (prompt, parameter model, respons mentah, sinyal terstruktur, hasil evaluasi risiko, hingga eksekusi order simulasi) disimpan secara terikat (*traceable*) di database PostgreSQL.
5. **No Profit Guarantees:** Platform tidak memberikan jaminan keuntungan. Metrik historis dan sinyal AI merupakan data komputasi analitik, bukan nasihat keuangan.

---

## 8. Pemisahan Tanggung Jawab: Analisis AI vs Strategi vs Eksekusi

```
[Sumber Data Blockchain & Pasar]
               │
               ▼
   [Hermes Multi-Agent Workflow]  <--- ANALISIS PROBABILISTIK
   (Analisis Token, Sentimen, Sinyal)   (Menghasilkan Sinyal Terstruktur JSON)
               │
               ▼
    [Deterministic Risk Gate]     <--- VALIDASI DETERMINISTIK
   (Validasi Likuiditas, Max Loss,     (Hard-coded Rule Engine, Non-bypassable)
    Slippage, Status Sistem)
               │
               ▼
    [Execution Simulator / Broker]<--- EKSEKUSI TERKONTROL
   (Paper Order, Fill, Rekonsiliasi,   (Simulasi Portofolio & Log Audit)
    Audit Trail)
```

LLM tidak memiliki akses ke database eksekusi secara langsung dan tidak dapat memodifikasi aturan risiko.

---

## 9. Model Biaya: Local-First & Free-Tier First
- **Lingkungan Pengembangan:** Memanfaatkan sumber daya lokal MacBook M1 Pro (RAM 16 GB) dengan arsitektur ARM64 native.
- **Penyedia AI:** Memprioritaskan free tier atau model dengan rasio biaya-kinerja optimal melalui OpenRouter dan 9Route (misalnya model efisien open-weights). Setiap pemanggilan model dibatasi oleh kuota token dan *timeout*.
- **Penyedia RPC Solana:** Menggunakan tier gratis (misalnya Helius, QuickNode, atau public RPC dengan rate limiter) untuk pengujian, dengan mencatat batas kuota harian/menit untuk mencegah *throttling*.
- **Database & Cache:** PostgreSQL open-source lokal di dalam Docker; Redis hanya digunakan bila terbukti ada *bottleneck* I/O nyata.

---

## 10. Status Proyek
- **Fase Saat Ini:** Tahap 0 — Dokumentasi Arsitektur, ERD, Flowchart, dan Roadmap Perencanaan.
- **Status Implementasi:** Belum ada kode aplikasi, bot transaksi, atau integrasi wallet aktif yang dieksekusi. Implementasi kode hanya akan dimulai setelah Tahap 0 disetujui secara formal.

---

## 11. Asumsi Awal Proyek
1. Jaringan Solana merupakan fokus tunggal pada rilis v1.
2. Operator memiliki akses internet stabil untuk konsumsi RPC dan API Gateway.
3. Seluruh kalkulasi performa simulasi menyertakan estimasi biaya jaringan (gas/priority fee) dan fee protokol DEX (misal Raydium/Orca) untuk menghindari ilusi profitabilitas.
