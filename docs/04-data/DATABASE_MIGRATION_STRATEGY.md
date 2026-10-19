# STRATEGI MIGRASI BASIS DATA (DATABASE MIGRATION STRATEGY)
**Dokumen:** `docs/04-data/DATABASE_MIGRATION_STRATEGY.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Basis Data  

---

Dokumen ini mendefinisikan prosedur evolusi skema, versioning migrasi, serta pedoman eksekusi perubahan struktur basis data menggunakan **Alembic** (alat migrasi resmi ekosistem SQLAlchemy/SQLModel).

---

## 1. Alat & Konvensi Penamaan Migrasi (Tooling & Standards)

1. **Migration Tool:** Menggunakan **Alembic** terintegrasi dengan model deklaratif SQLModel/SQLAlchemy di dalam modul backend Python.
2. **Lokasi File Migrasi:** Direktori `backend/alembic/versions/`.
3. **Konvensi Penamaan File Migrasi:**  
   `<nomor_revisi>_<deskripsi_singkat_perubahan>.py`  
   Contoh: `001_initial_schema_baseline.py`, `002_add_trailing_stop_to_positions.py`.
4. **Rantai Migrasi Linear (Linear Migration Chain):**  
   Dilarang keras membuat *merge heads* atau cabang migrasi bercabang. Setiap file revisi wajib memiliki `down_revision` tunggal yang jelas menuju revisi sebelumnya.

---

## 2. Struktur Dasar Skrip Migrasi Alembic

Setiap file migrasi wajib menyediakan dua fungsi deterministik: `upgrade()` dan `downgrade()`:

```python
"""001_initial_schema_baseline

Revision ID: 001_initial_schema
Revises: None
Create Date: 2026-10-14 15:00:00
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

def upgrade() -> None:
    # 1. Buat ekstensi UUID jika belum ada
    op.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";')
    op.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto";')
    
    # 2. Pembuatan tabel inti sesuai Data Dictionary
    # op.create_table('wallets', ...)
    # op.create_table('tokens', ...)
    pass

def downgrade() -> None:
    # Prosedur rollback simetris
    pass
```

---

## 3. Pedoman Zero-Downtime & Keselamatan Migrasi

Untuk menjaga ketersediaan layanan dan mencegah penguncian tabel berdurasi panjang (*table locks*):
1. **Penambahan Kolom Wajib Bersifat Non-Destruktif:**
   - Kolom baru wajib diberi nilai default atau dibuat `NULLABLE` saat pertama kali dibuat.
   - Jangan menambahkan kolom `NOT NULL` tanpa nilai default pada tabel yang sudah memiliki jutaan baris data.
2. **Pembuatan Indeks Bebas Kunci (`CONCURRENTLY`):**
   - Penambahan indeks baru pada tabel besar (seperti `wallet_observations` atau `market_snapshots`) wajib menggunakan sintaks PostgreSQL `CREATE INDEX CONCURRENTLY` agar operasi penulisan transaksi tidak terhenti.
3. **Pola Expand & Contract untuk Perubahan Nama Kolom:**
   - Jangan me-rename kolom secara langsung pada kode produksi.
   - Langkah 1 (*Expand*): Tambahkan kolom baru dan salin data.
   - Langkah 2 (*Migrate*): Ubah kode aplikasi untuk membaca dari kolom baru.
   - Langkah 3 (*Contract*): Hapus kolom lama pada rilis berikutnya.

---

## 4. Alur Kerja Eksekusi Migrasi di Docker Compose

Prosedur standar saat memulai lingkungan kontainer lokal:
1. Kontainer `backend` menjalankan pengecekan status migrasi secara otomatis saat *startup* sebelum API siap melayani traffic:  
   `alembic upgrade head`
2. Jika migrasi berhasil, proses FastAPI melanjutkan inisialisasi server Uvicorn.
3. Jika migrasi gagal, kontainer backend otomatis berhenti (*exit code 1*) untuk mencegah aplikasi berjalan di atas skema yang tidak cocok (*schema mismatch*).

### Perintah Operasional CLI (Host Developer):
```bash
# Membuat migrasi baru setelah mengubah model data
docker compose exec backend alembic revision --autogenerate -m "nama_perubahan"

# Menjalankan upgrade migrasi ke revisi terbaru
docker compose exec backend alembic upgrade head

# Memeriksa riwayat versi migrasi saat ini
docker compose exec backend alembic current

# Melakukan rollback 1 langkah ke belakang
docker compose exec backend alembic downgrade -1
```
