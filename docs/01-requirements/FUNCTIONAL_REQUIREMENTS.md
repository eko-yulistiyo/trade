# KEBUTUHAN FUNGSIONAL (FUNCTIONAL REQUIREMENTS)
**Dokumen:** `docs/01-requirements/FUNCTIONAL_REQUIREMENTS.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Kebutuhan Fungsional  

---

Dokumen ini memuat spesifikasi kebutuhan fungsional sistem yang terbagi ke dalam 8 modul domain utama. Setiap kebutuhan diberi identifikasi unik berseri `FR-<DOMAIN>-<NOMOR>`.

---

## Modul 1: Ingestion & Data Blockchain (Solana)

### FR-ING-01: Polling Transaksi On-Chain Solana
- **Deskripsi:** Sistem harus secara periodik mengambil riwayat transaksi terbaru dari wallet yang terdaftar dalam daftar pantau (*monitored wallets*) menggunakan Solana RPC.
- **Input:** Alamat wallet (`wallet_address`), signature transaksi terakhir yang berhasil diproses (`until_signature`).
- **Proses:** Memanggil API RPC Solana (`getSignaturesForAddress`), menyaring transaksi baru yang telah mencapai status finality `confirmed` atau `finalized`.
- **Output:** Daftar signature transaksi baru yang belum pernah diproses.
- **Kriteria Verifikasi:** Tidak ada signature yang terlewat atau diproses ulang secara redundan.

### FR-ING-02: Parsing & Klasifikasi Swap Transaksi DEX
- **Deskripsi:** Sistem harus mampu menguraikan (*parse*) instruksi dalam payload transaksi untuk mengidentifikasi apakah transaksi merupakan aktivitas pertukaran (*swap/trade*) di DEX (Raydium, Orca, Jupiter), transfer dana internal, atau penambahan likuiditas.
- **Input:** Payload data transaksi mentah dari Solana RPC / Helius Enhanced API.
- **Proses:** Memeriksa program ID, perubahan saldo akun SPL Token (*preTokenBalances* vs *postTokenBalances*), dan menentukan arah swap (`BUY` atau `SELL`).
- **Output:** Objek transaksi terstandarisasi: `{wallet, tx_signature, timestamp, dex, action: BUY/SELL, token_in, token_out, amount_in, amount_out, price_sol, fee}`.
- **Kriteria Verifikasi:** Transaksi transfer token biasa tidak boleh salah diklasifikasikan sebagai transaksi swap.

### FR-ING-03: Ingestion Snapshot Harga & Likuiditas Pasar
- **Deskripsi:** Sistem harus mengambil snapshot harga terkini dan likuiditas pool DEX untuk token yang relevan secara berkala.
- **Input:** Alamat mint token (`token_mint`).
- **Proses:** Memanggil API data pasar terintegrasi (DEXScreener / Birdeye / Raydium Pool API) dan menyimpan snapshot dengan timestamp.
- **Output:** Data record `market_snapshots` berisi harga USD, harga SOL, volume 24 jam, dan total likuiditas (USD).
- **Kriteria Verifikasi:** Data snapshot ditandai dengan status kebaruan (*freshness timestamp*) dan diverifikasi tidak lebih tua dari toleransi ambang *stale* (30 detik).

---

## Modul 2: Wallet Discovery & Monitoring

### FR-WLT-01: Perhitungan Metrik Kinerja Historis Wallet
- **Deskripsi:** Sistem harus menghitung metrik analitik objektif dari data riwayat transaksi suatu wallet kandidat.
- **Input:** Riwayat transaksi historis wallet (minimum 30 hari ke belakang).
- **Proses:** Menghitung Net Realized PnL, Total Trades, Win Rate, Maximum Drawdown (MDD), Profit Factor, serta rata-rata durasi kepemilikan aset (*average holding time*).
- **Output:** Skor komposit trader dan rekapitulasi performa bersih biaya.
- **Kriteria Verifikasi:** Biaya gas dan estimasi fee DEX wajib dikurangkan dalam perhitungan PnL bersih.

### FR-WLT-02: Skrining Anti-Manipulasi Wallet
- **Deskripsi:** Sistem harus mendeteksi indikasi manipulasi on-chain seperti *wash trading* (transaksi berulang bolak-balik pada pasangan yang sama untuk menaikkan volume) atau pendanaan sirkular.
- **Input:** Grafik transaksi internal antar wallet terkait.
- **Proses:** Menghitung rasio transaksi pada token volume rendah yang tidak wajar dan korelasi transfer keluar-masuk.
- **Output:** Nilai bendera risiko manipulasi (`manipulation_flag: true/false`, `confidence_score`).
- **Kriteria Verifikasi:** Wallet dengan indikasi *wash trading* tinggi otomatis ditolak dari rekomendasi penemuan.

### FR-WLT-03: Pengelolaan Watchlist & Approval Pengguna
- **Deskripsi:** Sistem harus menyediakan mekanisme persetujuan eksplisit oleh pengguna sebelum wallet yang ditemukan sistem dipindahkan ke status pemantauan aktif (*active copy-trading*).
- **Input:** ID wallet kandidat, aksi persetujuan operator (`APPROVE` atau `REJECT`).
- **Proses:** Memperbarui status wallet dari `DISCOVERED` atau `PENDING_REVIEW` menjadi `ACTIVE_MONITORED`.
- **Output:** Status baru wallet tercatat di database dengan catatan waktu persetujuan.
- **Kriteria Verifikasi:** Tidak ada wallet yang secara otomatis dieksekusi copy-trading tanpa persetujuan eksplisit pengguna.

---

## Modul 3: AI Model Gateway & Multi-Agent Architecture

### FR-AI-01: Abstraksi AI Model Gateway dengan Fallback
- **Deskripsi:** Sistem harus menyediakan gateway terpadu untuk meneruskan permintaan analisis ke penyedia LLM (OpenRouter sebagai primer, 9Route sebagai cadangan).
- **Input:** Payload prompt standar, batasan token (*max_tokens*), temperatur, skema format keluaran JSON.
- **Proses:** Mengirim HTTP request ke provider primer; jika terjadi kegagalan (HTTP 429/500/timeout), secara otomatis mengalihkan permintaan ke provider sekunder dengan *exponential backoff*.
- **Output:** Teks respons mentah model yang berhasil diterima beserta metadata (provider, model, token count, latency).
- **Kriteria Verifikasi:** Jika kedua provider gagal, sistem mengembalikan status error terkendali (*fail-closed*) tanpa membuat sistem terhenti (*crash*).

### FR-AI-02: Validasi Output Berstruktur (Structured Output Enforcement)
- **Deskripsi:** Sistem harus memvalidasi bahwa seluruh respons analisis dari agen AI mematuhi skema JSON yang telah didefinisikan secara ketat menggunakan Pydantic/JSON Schema.
- **Input:** Teks respons model AI.
- **Proses:** Mengurai teks JSON, mencocokkan setiap field dengan tipe data dan aturan batas nilai. Jika tidak valid, melakukan re-prompting maksimal 1 kali atau menolak sinyal.
- **Output:** Objek Python/JSON valid yang siap diproses oleh komponen deterministik.
- **Kriteria Verifikasi:** Respons yang mengandung halusinasi format, markdown tak beraturan, atau skema parsial otomatis ditolak.

### FR-AI-03: Agen Spesialis Analisis Token & Keamanan Kontrak
- **Deskripsi:** Agen AI harus menganalisis metadata token on-chain untuk mengevaluasi parameter bahaya teknis.
- **Input:** Data on-chain token: status `mint_authority`, status `freeze_authority`, persentase suplai pada 10 dompet teratas, likuiditas terkunci (*LP burn/lock status*).
- **Proses:** Mengevaluasi pola risiko penipuan dan menghasilkan skor keamanan token (0 s.d. 100).
- **Output:** Objek hasil: `{token_mint, safety_score, risk_level: LOW/MEDIUM/HIGH/CRITICAL, reasoning}`.
- **Kriteria Verifikasi:** Token dengan status `freeze_authority` aktif wajib diberi kategori risiko `CRITICAL`.

### FR-AI-04: Agen Spesialis Penghasil Sinyal Strategi
- **Deskripsi:** Agen AI harus mengombinasikan data kondisi pasar, aktivitas wallet yang dipantau, dan analisis teknis untuk mengusulkan sinyal perdagangan terstruktur.
- **Input:** Konteks pasar terkini, aksi wallet target, status keamanan token.
- **Proses:** Memformulasikan rekomendasi tindakan perdagangan.
- **Output:** Objek sinyal terstruktur `trading_signals`: `{signal_id, strategy_id, token_mint, action: BUY/SELL/HOLD, recommended_size_pct, rationale, confidence}`.
- **Kriteria Verifikasi:** Sinyal yang dihasilkan tidak memuat perintah eksekusi langsung, melainkan usulan yang harus diverifikasi oleh Risk Engine.

---

## Modul 4: Deterministic Risk Engine

### FR-RSK-01: Verifikasi Aturan Risiko Absolut (Non-Bypassable Risk Gate)
- **Deskripsi:** Risk Engine harus mengevaluasi setiap sinyal perdagangan terhadap kumpulan aturan risiko kuantitatif deterministik sebelum diizinkan dieksekusi.
- **Input:** Objek `trading_signals`, kondisi portofolio saat ini, data pasar terkini (Bybit Spot / Solana).
- **Proses:** Menjalankan 8 pemeriksaan serial:
  1. *Positive Expectancy Check:* Ekspektasi matematis bersih dari biaya $E > 0$.
  2. *Risk per Trade Check:* Toleransi risiko maksimal **0.5% dari Total Equity Terkini**.
  3. *Daily Loss Limit Check:* Akumulasi kerugian 24 jam terakhir harus $< 2.0\%$ dari ekuitas pembukaan (jika tersentuh, hentikan entry baru).
  4. *Drawdown Limit Check:* Drawdown maksimal $< 8.0\%$ dari High-Water Mark (jika tersentuh, bekukan strategi untuk evaluasi manual).
  5. *Spread & Liquidity Check:* Spread bid-ask $\le 0.08\%$ dan likuiditas pool/orderbook mencukupi.
  6. *Stop Loss Validation:* Stop Loss wajib terdefinisi secara numerik dan rasio Risk:Reward $\ge 1:1.5$.
  7. *Lot Size & Precision Check:* Memenuhi `min_order_qty` dan `tick_size` exchange/AMM.
  8. *Data Freshness Check:* Snapshot harga tidak lebih tua dari 30 detik.
- **Output:** Record `risk_checks`: `{check_id, signal_id, passed: true/false, failed_rules: [...], evaluated_at}`.
- **Kriteria Verifikasi:** Jika ada minimal 1 aturan yang gagal, status akhir wajib `NO_TRADE` dan sinyal dibatalkan.

---

## Modul 5: Trading Simulation & Accounting (Paper Broker & Compounding Engine)

### FR-SIM-01: Pembuatan & Pencocokan Paper Order (Order Matching & Fees)
- **Deskripsi:** Sistem harus membuat order virtual berbasis sinyal yang lolos verifikasi risiko dan mensimulasikan pemenuhan order (*fill*) berdasarkan harga pasar real-time Bybit Spot atau Solana DEX.
- **Input:** Objek `trading_signals` yang lolos `risk_checks`.
- **Proses:**
  - Menghitung besaran lot berbasis rumus risiko 0.5% ekuitas: $\text{Size} = (\text{Equity} \times 0.005) / |\text{Entry} - \text{SL}|$.
  - Mensimulasikan tipe order (Market / Limit Order) beserta potensi *Partial Fill*.
  - Membebankan biaya transaksi realistis (Fee Bybit Spot Taker 0.1% atau Solana DEX Fee 0.25% + Gas Fee 0.000005 SOL) serta estimasi *slippage*.
- **Output:** Record `paper_orders` dan record `paper_trades` dengan status `FILLED` atau `PARTIAL_FILLED`.
- **Kriteria Verifikasi:** Saldo kas virtual dan saldo token virtual terbarui secara akurat sesuai kaidah pembukuan ganda.

### FR-SIM-02: Akuntansi Posisi, Compounding Adaptif, & Manajemen Exit
- **Deskripsi:** Sistem harus memperbarui status posisi terbuka, mengelola *Partial Take Profit* (TP1 50%), *Trailing Stop*, dan menghitung PnL serta compounding portofolio secara otomatis.
- **Input:** Transaksi paper trade baru, snapshot harga pasar terkini, status posisi aktif.
- **Proses:**
  - Eksekusi Take Profit parsial (TP1: 50% posisi ditutup pada $1.5R$ dan Stop Loss digeser ke Breakeven).
  - Trailing Stop ATR dinamis pada kondisi pasar trending kuat.
  - Menghitung Realized PnL (FIFO) dan Unrealized PnL (*mark-to-market*).
  - *Compounding Adaptif:* Mengalokasikan keuntungan kembali ke basis ekuitas, dan secara adaptif mengurangi risiko per trade menjadi 0.35% atau 0.25% saat terjadi drawdown beruntun.
  - Memperbarui catatan *High-Water Mark* pada Equity Ledger.
- **Output:** Record `positions` terbarui, snapshot berkala di `portfolio_snapshots`, dan matriks performa (Win Rate, Profit Factor, Sharpe Ratio).
- **Kriteria Verifikasi:** Rumus: $\text{Net Realized PnL} = (\text{Nilai Jual} - \text{Nilai Beli}) - (\text{Total Biaya Transaksi} + \text{Slippage})$.

### FR-SIM-03: Mesin Backtesting Historis
- **Deskripsi:** Sistem harus dapat menjalankan simulasi strategi terhadap kumpulan data transaksi historis Solana tanpa look-ahead bias.
- **Input:** Parameter strategi, rentang tanggal historis, data snapshot harga dan transaksi lampau.
- **Proses:** Mengiterasi data waktu per baris (*tick-by-tick* atau *candle-by-candle*), menghasilkan sinyal dan mengevaluasi portofolio seolah-olah terjadi di waktu nyata.
- **Output:** Laporan kinerja strategi: Total Return, Max Drawdown, Sharpe Ratio, Win/Loss Ratio.
- **Kriteria Verifikasi:** Tidak ada data dari titik waktu $t+1$ yang dapat diakses oleh strategi pada titik waktu $t$.

---

## Modul 6: Web Dashboard & Control Center

### FR-UI-01: Ringkasan Metrik Portofolio Real-Time
- **Deskripsi:** Dashboard web harus menampilkan grafik ekuitas portofolio virtual, saldo kas, total PnL harian/keseluruhan, dan daftar posisi aktif.
- **Kriteria Verifikasi:** Tampilan data diperbarui secara responsif tanpa perlu memuat ulang (*refresh*) halaman penuh.

### FR-UI-02: Explorer Wallet & Token
- **Deskripsi:** Dashboard harus menyediakan antarmuka pencarian dan pemantauan detail untuk setiap wallet yang terdaftar serta token yang sedang dipantau.
- **Kriteria Verifikasi:** Menampilkan skor risiko token, riwayat swap terakhir, dan tombol persetujuan wallet (*Approve/Remove*).

### FR-UI-03: Peninjau Log Audit Sinyal & Evaluasi Risiko
- **Deskripsi:** Dashboard harus menyediakan tabel investigasi yang menampilkan setiap sinyal AI yang masuk, alasan rekomendasi, aturan risiko yang dievaluasi, dan status eksekusi.
- **Kriteria Verifikasi:** Operator dapat memfilter log berdasarkan status (`PASSED`, `REJECTED`, `EXPIRED`).

---

## Modul 7: Telegram Bot Interface

### FR-TG-01: Pengiriman Notifikasi Kejadian Kritis
- **Deskripsi:** Bot Telegram harus mengirimkan pesan notifikasi instan untuk kejadian: deteksi transaksi wallet target, sinyal baru, penolakan oleh Risk Engine, eksekusi paper order, dan peringatan batas kerugian.
- **Format:** Pesan terstruktur dengan emoji status, nama token, nominal, dan alasan.
- **Kriteria Verifikasi:** Pesan hanya dikirimkan ke `TELEGRAM_ALLOWED_CHAT_ID` yang terdaftar.

### FR-TG-02: Otorisasi & Penanganan Perintah Kendali Darurat
- **Deskripsi:** Bot harus menerima dan mengeksekusi perintah kontrol dari pengguna terverifikasi:
  - `/status`: Menampilkan ringkasan portofolio dan kesehatan sistem.
  - `/pause`: Menjeda pembuatan sinyal dan order baru.
  - `/resume`: Mengaktifkan kembali sistem dari status jeda.
  - `/kill`: Memicu *Emergency Stop* seketika.
- **Kriteria Verifikasi:** Perintah dari ID akun yang tidak berada dalam *allowlist* ditolak secara diam-diam (*silent ignore*) tanpa membeberkan informasi sistem.

---

## Modul 8: Audit Logging & System Safety (Emergency Stop)

### FR-AUD-01: Pencatatan Siklus Hidup Penuh (Audit Trail)
- **Deskripsi:** Sistem wajib mencatat setiap panggilan API eksternal (LLM dan RPC), parameter input, waktu respons, dan respons data ke dalam tabel `llm_requests` dan `system_events`.
- **Kriteria Verifikasi:** Tidak ada token rahasia atau header autentikasi yang tercatat ke dalam log database.

### FR-AUD-02: Mekanisme Penghentian Darurat Deterministik (Emergency Stop)
- **Deskripsi:** Sistem harus memiliki flag status global (`system_state: RUNNING / PAUSED / EMERGENCY_STOP`) di database/memori yang memblokir seluruh pembuatan order baru jika status bukan `RUNNING`.
- **Kriteria Verifikasi:** Saat pemicu `/kill` diaktifkan, loop ingestion dan loop eksekusi simulator berhenti memproses antrean baru dalam waktu ≤ 2 detik.
