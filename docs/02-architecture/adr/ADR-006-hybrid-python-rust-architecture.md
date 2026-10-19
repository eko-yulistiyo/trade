# ADR-006: Arsitektur Hibrida Python (AI & API) + Rust (Core Ingestion, Risk Gate, & Matching)
**Status:** Diterima (*Accepted*)  
**Tanggal:** 14 Oktober 2026  
**Penulis:** Principal Software Architect / Senior Systems Engineer  
**Cakupan:** Pemilihan Bahasa Pemrograman dan Distribusi Beban Komputasi  

---

## Konteks (Context)
Platform **AUTO-TRADE-AA** memiliki dua karakteristik beban kerja yang kontras:
1. **Beban Kerja AI & Antarmuka Kontrol:**
   - Orkestrasi multi-agent (Hermes Agent), manipulasi string dan prompt, integrasi AI Model Gateway (OpenRouter, 9Route), validasi skema JSON Pydantic, serta endpoint REST API kontrol dan bot Telegram. Beban kerja ini sangat cocok dan produktif dikembangkan menggunakan ekosistem **Python (FastAPI)**.
2. **Beban Kerja Trading On-Chain & Eksekusi Berkecepatan Tinggi:**
   - Ingestion WebSocket berfrekuensi tinggi (Bybit Spot L2 Orderbook, Solana RPC/Geyser stream), parsing instruksi biner DEX Solana (Raydium, Orca), evaluasi aturan matematika deterministik Risk Gate (< 1 milidetik), kalkulasi slippage AMM, serta simulasi pencocokan order (*matching engine*). Beban kerja ini menuntut keandalan memori mutlak (*memory safety*), ketiadaan jeda Garbage Collection (*zero-cost abstractions, zero GC pauses*), dan eksekusi konkruen berperforma tinggi yang merupakan keunggulan utama bahasa **Rust**.

Kandidat pendekatan:
- **Full Python:** Mudah dibangun, tetapi menghadapi keterbatasan GIL (*Global Interpreter Lock*), overhead parsing biner Solana, dan konsumsi memori lebih tinggi pada ingestion kontinu.
- **Full Rust:** Performa dan keamanan memori terbaik, tetapi ekosistem agen AI, integrasi LLM gateway, dan fleksibilitas prompt tooling di Rust masih jauh lebih terbatas dibandingkan Python.
- **Arsitektur Hibrida (Python + Rust):** Menggabungkan kekuatan terbaik kedua ekosistem.

---

## Keputusan (Decision)
Kami memutuskan untuk mengadopsi **Arsitektur Hibrida**:
1. **Frontend:** **React.js** melalui framework **Next.js 15 (TypeScript + Tailwind CSS)** untuk dashboard web real-time yang modern dan responsif.
2. **AI Orchestration & API Layer (Python 3.11/3.12 + FastAPI):**
   - Menjalankan Hermes Multi-Agent Framework dan Dynamic AI Skill System (`.agents/skills/`).
   - Menjalankan AI Model Gateway (OpenRouter & 9Route Adapter).
   - Menyediakan REST API untuk Web Dashboard dan mengelola bot Telegram.
3. **Core Engine Performa Tinggi (Rust):**
   - **Ingestion & Parser Service:** Konektor WebSocket Bybit Spot dan parser instruksi transaksi on-chain Solana menggunakan `solana-sdk` native.
   - **Deterministic Risk Engine:** Evaluasi 9 pintu risiko (Risk 0.5%, Daily Loss 2%, Drawdown 8%, Expectancy Positif) dalam sub-milidetik.
   - **Paper Broker Matching Engine:** Simulasi pencocokan order, model slippage matematis, dan akuntansi portofolio berkecepatan memori (*in-memory ledger*).
4. **Mekanisme Interoperabilitas:** Komunikasi antara Python dan Rust dapat dilakukan melalui **FFI (PyO3)** untuk integrasi in-process monolitik berkinerja tinggi, atau melalui **gRPC / IPC lokal** berlatensi ultra-rendah.

---

## Konsekuensi (Consequences)

### Positif:
- **Performa Eksekusi Ekstrem:** Kalkulasi Risk Gate dan decoding transaksi Solana berjalan di tingkat kecepatan CPU native (sub-milidetik), bebas jeda Garbage Collector.
- **Produktivitas AI Maksimal:** Logika penalaran agen AI, prompt engineering, dan adaptasi model LLM tetap fleksibel menggunakan pustaka Python modern.
- **Pengalaman Visual Modern:** React.js (Next.js) memberikan antarmuka visual grafik candlestick dan ledger PnL yang interaktif dan lancar.
- **Efisiensi Memori MacBook M1 Pro:** Rust memiliki *memory footprint* yang sangat kecil (< 50-100 MB), menjaga total konsumsi RAM kontainer tetap hemat.

### Negatif:
- **Kompleksitas Tooling Build:** Diperlukan toolchain kompilasi Rust (`cargo`, `rustc`) dan Python dalam pipeline Docker Compose lokal.

### Netral / Mitigasi:
- Menggunakan multi-stage Docker build untuk mengompilasi binary Rust, sehingga image kontainer runtime akhir tetap berukuran kecil dan ramping (Alpine/Debian-slim).
