# GLOSARIUM ISTILAH (GLOSSARY)
**Dokumen:** `docs/00-overview/GLOSSARY.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi  

---

Dokumen ini memuat definisi baku dan terminologi teknis yang digunakan di seluruh dokumen arsitektur, diagram, basis data, dan modul aplikasi **AUTO-TRADE-AA**.

---

## 1. Terminologi Domain Trading & Finansial

| Istilah | Definisi Konseptual |
|---|---|
| **Backtesting** | Metode pengujian strategi perdagangan menggunakan data historis pasar untuk mengukur efektivitas dan parameter risiko strategi di masa lalu. |
| **Paper Trading** | Simulasi perdagangan secara *real-time* menggunakan data harga pasar terkini tanpa menggunakan uang/aset sungguhan. Seluruh saldo, order, dan posisi bersifat virtual. |
| **Copy-Trading** | Metode perdagangan di mana aktivitas transaksi dari satu atau lebih wallet target (*master trader / tracked wallet*) dideteksi, dievaluasi, dan ditiru secara proporsional. |
| **Slippage** | Selisih antara harga yang diharapkan saat order diajukan dan harga aktual saat order dieksekusi. |
| **Maximum Drawdown (MDD)** | Penurunan nilai puncak (*peak*) portofolio ke titik terendah (*trough*) sebelum puncak baru tercapai, dinyatakan dalam persentase. |
| **Realized PnL** | Keuntungan atau kerugian bersih yang telah terealisasi setelah suatu posisi perdagangan ditutup secara penuh atau parsial. |
| **Unrealized PnL** | Keuntungan atau kerugian mengambang (*floating*) dari posisi terbuka yang dihitung berdasarkan harga pasar terkini (*mark-to-market*). |
| **Order Fill** | Pemenuhan eksekusi order perdagangan, baik terisi penuh (*fully filled*) maupun sebagian (*partially filled*). |
| **Position Sizing** | Penentuan kuantitas atau alokasi nominal modal yang diperdagangkan pada satu transaksi tertentu untuk mengontrol eksposur risiko. |
| **Daily Loss Limit** | Batas maksimal akumulasi kerugian yang diperbolehkan dalam kurun waktu 24 jam sebelum sistem secara otomatis menghentikan pembuatan order baru. |

---

## 2. Terminologi Blockchain & Jaringan Solana

| Istilah | Definisi Konseptual |
|---|---|
| **Solana RPC (Remote Procedure Call)** | Antarmuka jaringan protokol yang memungkinkan aplikasi berkomunikasi dengan node blockchain Solana untuk membaca data transaksi, akun, atau mengirimkan instruksi. |
| **WebSocket Stream** | Koneksi dua arah persisten untuk menerima pembaruan status akun, blok, atau transaksi on-chain secara langsung (*push-based notification*). |
| **SPL Token** | Standar token pada blockchain Solana (*Solana Program Library Token*), setara dengan standar ERC-20 pada Ethereum. |
| **Mint Address** | Alamat akun on-chain unik yang merepresentasikan kontrak penerbitan suatu token SPL di Solana. |
| **Freeze Authority** | Entitas akun yang memiliki wewenang untuk membekukan aset token di dalam akun pengguna. Merupakan parameter risiko kritis dalam analisis keamanan token. |
| **Mint Authority** | Entitas akun yang memiliki wewenang untuk mencetak token baru. Jika tidak dicabut (*revoked*), pasokan token dapat diencerkan secara sepihak. |
| **AMM (Automated Market Maker)** | Protokol bursa terdesentralisasi (misal Raydium, Orca) yang menggunakan kolam likuiditas (*liquidity pools*) dan rumus matematis untuk menentukan harga aset secara algoritmik. |
| **Transaction Signature** | Hash unik 64-byte berbasis Base58 yang menjadi bukti dan identitas unik dari suatu transaksi di jaringan Solana. |
| **Look-Ahead Bias** | Kesalahan metodologis dalam backtesting di mana data masa depan yang belum terjadi pada titik waktu simulasi secara tidak sengaja digunakan dalam pengambilan keputusan. |

---

## 3. Terminologi AI & Rekayasa Agen (Multi-Agent Engineering)

| Istilah | Definisi Konseptual |
|---|---|
| **Hermes Agent** | Orkestrator tingkat sistem yang mengelola siklus hidup, pembagian tugas, dan koordinasi antar-agen spesialis dalam alur kerja analisis. |
| **AI Model Gateway** | Komponen lapisan adaptor yang menyediakan antarmuka terpadu untuk mengakses berbagai penyedia model LLM (OpenRouter, 9Route) dengan manajemen kuota, fallback, dan retry. |
| **Structured JSON Output** | Format respons dari model bahasa besar yang dibatasi secara sintaksis dan skema agar selalu menghasilkan objek JSON valid yang dapat diurai oleh program. |
| **Prompt Injection** | Vektor serangan di mana data masukan eksternal (misal metadata token atau nama token manipulatif) mengecoh instruksi sistem model AI untuk memanipulasi keputusannya. |
| **Probabilistic vs. Deterministic** | Pemisahan antara sifat AI yang berbasis kemungkinan (*probabilistic*, dapat bervariasi) dan mesin aturan kode yang selalu menghasilkan keluaran pasti untuk masukan yang sama (*deterministic*). |

---

## 4. Terminologi Arsitektur Perangkat Lunak & Keamanan

| Istilah | Definisi Konseptual |
|---|---|
| **Modular Monolith** | Pola arsitektur di mana seluruh sistem berada dalam satu basis kode dan proses deployment terpadu, namun komponen di dalamnya dipisahkan secara tegas ke dalam modul-modul independen berdasarkan batas domain. |
| **Deterministic Risk Gate** | Modul evaluasi aturan kode yang memvalidasi setiap usulan transaksi terhadap kriteria keamanan yang telah ditetapkan secara mutlak, sebelum diteruskan ke mesin eksekusi. |
| **Fail-Closed** | Prinsip arsitektur keselamatan di mana jika suatu subsistem mengalami kegagalan, kehilangan koneksi, atau menerima data yang meragukan, sistem akan memilih keadaan paling aman (menolak transaksi baru, bukan melanjutkan tanpa verifikasi). |
| **Least Privilege** | Prinsip keamanan informasi di mana setiap modul, agen, atau pengguna hanya diberikan hak akses minimum yang mutlak diperlukan untuk menyelesaikan fungsinya. |
| **Idempotency** | Karakteristik operasi di mana pemanggilan operasi tersebut sebanyak satu kali atau berkali-kali dengan parameter yang sama akan menghasilkan efek yang identik tanpa efek samping ganda (mencegah eksekusi ganda transaksi yang sama). |
| **Kill Switch / Emergency Stop** | Mekanisme kontrol manual maupun otomatis yang mematikan seluruh operasi penyerapan sinyal dan eksekusi order secara seketika dalam kondisi darurat. |
| **Stale Data** | Kondisi data pasar atau saldo yang telah melewati batas usia toleransi (*timeout TTL*), sehingga tidak lagi dianggap akurat untuk mendasari keputusan transaksi. |
