# MODEL DATA DAN ARSITEKTUR BASIS DATA (DATA MODEL)
**Dokumen:** `docs/04-data/DATA_MODEL.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Basis Data  

---

Dokumen ini mendefinisikan arsitektur model data, domain entitas, dan prinsip perancangan skema basis data **PostgreSQL 16** sebagai sumber kebenaran tunggal (*Single Source of Truth*) untuk platform **AUTO-TRADE-AA**.

---

## 1. Prinsip Fundamental Pemodelan Data

1. **Pemisahan Tegas antara Data Eksternal, Analisis, dan Eksekusi:**
   Data transaksi on-chain mentah (`wallet_observations`), inferensi model AI (`llm_requests`, `trading_signals`), evaluasi keselamatan deterministik (`risk_checks`), dan eksekusi order virtual (`paper_orders`, `paper_trades`) disimpan dalam tabel terpisah secara modular.
2. **Identitas Internal yang Stabil (UUID v4 Primary Keys):**
   Seluruh tabel menggunakan tipe data `UUID` acak (UUID v4) sebagai Primary Key internal. Hal ini menjamin stabilitas relasi internal sekalipun format alamat on-chain atau simbol bursa eksternal mengalami perubahan representasi.
3. **Pola Hibrida Relasional + JSONB:**
   Kolom relasional dengan tipe data ketat (`NUMERIC`, `TIMESTAMP`, `BOOLEAN`, `VARCHAR`) digunakan untuk data operasional, kalkulasi matematika, filter query, dan foreign key. Kolom `JSONB` terindeks (*GIN index*) digunakan untuk menyimpan payload mentah on-chain (`raw_payload`) dan respons lengkap LLM (`response_json`).
4. **Nol Penyimpanan Kunci Privat (Zero Private Key Storage):**
   Tidak ada tabel, kolom, atau metadata yang dirancang untuk menyimpan *private key*, *seed phrase*, atau kredensial dompet pengguna.
5. **Integritas Pembukuan Finansial (Double-Entry Balancing):**
   Setiap transaksi eksekusi simulasi (`paper_trades`) wajib terhubung ke tabel `positions` dan memperbarui saldo kas virtual di `portfolio_snapshots` guna mencegah anomali selisih saldo (*phantom balance*).

---

## 2. Taksonomi Kelompok Entitas (Entity Domains)

Model data dibagi menjadi 5 kelompok domain logis:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. DOMAIN OBSERVASI PASAR & BLOCKCHAIN                                      │
│    • WALLETS (Daftar alamat wallet pantauan / trader target)                │
│    • TOKENS (Master data token Solana SPL & instrumen Bybit Spot)           │
│    • WALLET_OBSERVATIONS (Log transaksi on-chain Solana / Bybit)            │
│    • MARKET_SNAPSHOTS (Data harga spot, spread, depth, volume per menit)    │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Memicu Analisis
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. DOMAIN ORKESTRASI AI & STRATEGI                                          │
│    • STRATEGIES & STRATEGY_VERSIONS (Definisi dan versioning strategi)      │
│    • AGENT_RUNS (Siklus hidup eksekusi agen Hermes)                         │
│    • LLM_REQUESTS (Audit log inferensi OpenRouter / 9Route)                 │
│    • TRADING_SIGNALS (Rekomendasi sinyal perdagangan terstruktur)           │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Mengajukan Sinyal
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. DOMAIN RISIKO & KESELAMATAN (DETERMINISTIC RISK GATE)                     │
│    • RISK_CHECKS (Hasil evaluasi 9 pintu risiko numerik mutlak)             │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Lolos Verifikasi (PASS)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 4. DOMAIN SIMULASI EKSEKUSI & PORTOFOLIO                                    │
│    • PAPER_ORDERS (Order virtual: Market / Limit Order)                     │
│    • PAPER_TRADES (Eksekusi fill virtual, slippage, & fee Bybit/DEX)        │
│    • POSITIONS (Posisi terbuka, SL, Partial TP1 50%, TP2, Trailing Stop)   │
│    • PORTFOLIO_SNAPSHOTS (Equity Ledger, Daily Loss %, High-Water Mark)     │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Logging Status Sistem
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 5. DOMAIN KONTROL & KEJADIAN SISTEM                                         │
│    • USER_SETTINGS (Parameter global, batas risiko, threshold)              │
│    • SYSTEM_EVENTS (Audit log kejadian darurat, Circuit Breaker, kill)      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Siklus Hidup Status Entitas Kunci (Lifecycle States)

### 3.1 Status Wallet (`WALLETS.status`)
- `DISCOVERED`: Dompet baru ditemukan oleh algoritma pemindaian awal.
- `PENDING_REVIEW`: Lolos filter performa awal, menunggu persetujuan operator.
- `ACTIVE_MONITORED`: Disetujui oleh operator; aktif dipantau untuk copy-trading.
- `ARCHIVED`: Ditolak atau dinonaktifkan dari pemantauan.

### 3.2 Status Sinyal (`TRADING_SIGNALS.status`)
- `PENDING`: Sinyal baru dihasilkan oleh AI Strategy Agent.
- `REJECTED`: Ditolak oleh Deterministic Risk Gate (melanggar minimal 1 pintu risiko).
- `EXECUTED`: Berhasil lolos risiko dan diterbitkan menjadi `paper_orders`.
- `EXPIRED`: Tidak dieksekusi hingga batas waktu `expires_at` terlewati.

### 3.3 Status Order Paper Trading (`PAPER_ORDERS.status`)
- `SUBMITTED`: Order terdaftar di antrean Paper Broker Simulator.
- `PARTIAL_FILLED`: Sebagian kuantitas terisi berdasarkan simulasi likuiditas.
- `FILLED`: 100% kuantitas terisi penuh.
- `CANCELLED`: Dibatalkan oleh sistem atau intervensi pengguna.
- `REJECTED`: Gagal pada tahap validasi simulator matching.

### 3.4 Status Posisi Portofolio (`POSITIONS.status`)
- `OPEN`: Posisi baru aktif dibuka penuh.
- `PARTIALLY_CLOSED`: Level TP1 (1.5R) tercapai, 50% kuantitas telah dijual dan Stop Loss digeser ke Breakeven.
- `CLOSED`: Seluruh kuantitas posisi telah ditutup (terkena SL, TP2, Trailing Stop, atau exit manual).
