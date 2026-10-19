# SPESIFIKASI TEKNIS AGEN AI (AI AGENT SPECIFICATION)
**Dokumen:** `docs/02-architecture/AI_AGENT_SPECIFICATION.md`  
**Proyek:** AI Crypto Trading & Copy-Trading Platform (AUTO-TRADE-AA)  
**Versi:** 1.0.0 (Tahap 0)  
**Status:** Draf Resmi Arsitektur AI  

---

Dokumen ini mendefinisikan kontrak antarmuka teknis, skema Pydantic, matriks hak akses alat (*tooling permissions*), serta alur eksekusi (*execution lifecycle*) untuk seluruh agen spesialis dalam ekosistem **Hermes Multi-Agent Framework**.

---

## 1. Prinsip Desain Agen (Agent Design Principles)

1. **Probabilistic Reasoning, Deterministic Action:** Agen AI bertindak semata-mata sebagai analis kualitatif dan pemberi rekomendasi sinyal terstruktur. Agen dilarang memiliki hak akses penulisan ke saldo, pembuatan order langsung, atau memotong gerbang risiko.
2. **Keluaran Wajib Berstruktur (Pydantic Strict Schema):** Tidak ada respons teks bebas (*free-form prose*) yang diizinkan mengalir ke Trading Engine. Seluruh keluaran wajib diurai menjadi model data Pydantic yang valid.
3. **Pemuatan Keahlian Dinamis (Dynamic Skill Loading):** Agen memuat file instruksi dari direktori `.agents/skills/` secara on-demand sesuai sub-tugas yang dijalankan guna memangkas konsumsi token LLM hingga 70%.
4. **Isolasi Konteks:** Setiap agen hanya menerima data yang relevan dengan tanggung jawab domainnya (*contextual least privilege*).

---

## 2. Matriks Hak Akses Alat (Tooling & Permissions Matrix)

| Komponen Agen | Izin Baca Data Pasar | Izin Panggil Model AI | Izin Akses Skill (.agents/skills) | Izin Tulis Database Sinyal | Izin Eksekusi Order / Saldo |
|---|---|---|---|---|---|
| **Hermes Orchestrator** | **YA** (Internal State) | **TIDAK** (Delegasi) | **YA** (Pilih Skill) | **YA** (Update Status) | **DILARANG MUTLAK** |
| **Token Safety Agent** | **YA** (On-Chain SPL) | **YA** (via Gateway) | **YA** (`token-and-contract-safety`) | **TIDAK** (Kirim ke Hermes) | **DILARANG MUTLAK** |
| **Market Context Agent** | **YA** (Orderbook/OHLCV) | **YA** (via Gateway) | **YA** (`market-regime-detection`) | **TIDAK** (Kirim ke Hermes) | **DILARANG MUTLAK** |
| **Trader Profiling Agent**| **YA** (History Wallet) | **YA** (via Gateway) | **TIDAK** (Kalkulasi Matematis) | **YA** (Update Score Wallet)| **DILARANG MUTLAK** |
| **Strategy Signal Agent**| **YA** (Synthesized State) | **YA** (via Gateway) | **YA** (`signal-scoring-hybrid`) | **YA** (Buat Draft Sinyal) | **DILARANG MUTLAK** |

---

## 3. Rincian Kontrak Spesifikasi Tiap Agen

### 3.1 Token Safety Agent
- **Tanggung Jawab:** Mengaudit smart contract token Solana SPL dan simbol Bybit Spot untuk mengeliminasi risiko *honeypot*, pencetakan tak terbatas, atau pembekuan saldo.
- **Skill Terkait:** `.agents/skills/token-and-contract-safety/SKILL.md`
- **Skema Masukan (Input Model):**
  ```python
  class TokenSafetyInput(BaseModel):
      token_address: str
      chain: Literal["solana", "bybit_spot"]
      freeze_authority: Optional[str] = None
      mint_authority: Optional[str] = None
      top_10_holder_pct: float
      lp_burned_or_locked_pct: float
      pool_liquidity_usd: float
      created_at_timestamp: int
  ```
- **Skema Keluaran (Output Model):**
  ```python
  class TokenSafetyOutput(BaseModel):
      token_address: str
      safety_score: float = Field(ge=0.0, le=100.0)
      risk_level: Literal["LOW", "MEDIUM", "HIGH", "CRITICAL"]
      freeze_authority_revoked: bool
      mint_authority_revoked: bool
      is_honeypot_risk: bool
      reasons: list[str]
      approved_for_trading: bool
  ```
- **Aturan Batas:** Jika `freeze_authority_revoked == False` atau `mint_authority_revoked == False`, `approved_for_trading` wajib `False` dan `risk_level = "CRITICAL"`.

---

### 3.2 Market Context & Regime Agent
- **Tanggung Jawab:** Menentukan rezim pasar (Trending vs Sideways) menggunakan indikator teknikal multi-timeframe (M5, M15, H1, H4).
- **Skill Terkait:** `.agents/skills/market-regime-detection/SKILL.md`
- **Skema Masukan (Input Model):**
  ```python
  class MarketContextInput(BaseModel):
      symbol: str
      timeframe: str = "H1"
      current_price: float
      ema_20: float
      ema_50: float
      ema_200: float
      rsi_14: float
      macd_histogram: float
      adx_14: float
      atr_14: float
      vwap: float
      spread_pct: float
      volume_24h_usd: float
  ```
- **Skema Keluaran (Output Model):**
  ```python
  class MarketContextOutput(BaseModel):
      symbol: str
      regime: Literal["TRENDING_BULLISH", "TRENDING_BEARISH", "SIDEWAYS_RANGE", "VOLATILE_HIGH_RISK"]
      trend_strength_adx: float
      volatility_state: Literal["LOW", "NORMAL", "HIGH", "EXTREME"]
      recommended_strategy_type: Literal["TREND_FOLLOWING", "MOMENTUM_BREAKOUT", "MEAN_REVERSION", "NO_TRADE"]
      is_market_condition_ok: bool
      confidence: float = Field(ge=0.0, le=1.0)
  ```

---

### 3.3 Strategy Signal Agent (Hybrid Engine)
- **Tanggung Jawab:** Menyintesis hasil evaluasi keselamatan dan konteks pasar menjadi usulan sinyal perdagangan terstruktur.
- **Skill Terkait:** `.agents/skills/signal-scoring-hybrid/SKILL.md`
- **Skema Masukan (Input Model):**
  ```python
  class StrategySignalInput(BaseModel):
      symbol: str
      token_safety: TokenSafetyOutput
      market_context: MarketContextOutput
      candidate_action: Literal["BUY", "SELL", "HOLD"]
      current_price: float
      support_level: float
      resistance_level: float
      copy_trade_context: Optional[dict] = None
  ```
- **Skema Keluaran (Output Model):**
  ```python
  class StrategySignalOutput(BaseModel):
      signal_id: str
      symbol: str
      strategy_type: Literal["TREND_FOLLOWING", "MOMENTUM_BREAKOUT", "MEAN_REVERSION", "COPY_TRADE"]
      action: Literal["BUY", "SELL", "HOLD"]
      target_entry_price: float
      suggested_stop_loss: float
      suggested_take_profit_1: float  # Level TP1 (50% parsial @ 1.5R)
      suggested_take_profit_2: float  # Level TP2 (penuh @ 3.0R)
      recommended_risk_pct: float = 0.005  # Batas mutlak 0.5% ekuitas
      confidence_score: float = Field(ge=0.0, le=1.0)
      estimated_winrate_pct: float
      rationale: str
      expires_in_seconds: int = 300
  ```

---

## 4. Alur Kerja Siklus Hidup Eksekusi (Agent Lifecycle Workflow)

```
[ Pemicu Event: Polling / Swap DEX ]
                 │
                 ▼
     [ 1. Inisialisasi Agent Run ] ──► Catat status STARTED di `agent_runs`
                 │
                 ▼
     [ 2. Evaluasi Token Safety ]
        ├── Muat skill: token-and-contract-safety
        └── Jalankan Token Safety Agent
                 │
                 ├── Jika GAGAL: Update status FAILED ──► Kirim Alert & Selesai
                 └── Jika LOLOS:
                         │
                         ▼
     [ 3. Evaluasi Market Context & Regime ]
        ├── Muat skill: market-regime-detection
        └── Jalankan Market Context Agent
                 │
                 ├── Jika Volatile Ekstrem: Status NO_TRADE ──► Selesai
                 └── Jika Normal:
                         │
                         ▼
     [ 4. Sintesis Sinyal Perdagangan ]
        ├── Muat skill: signal-scoring-hybrid
        └── Jalankan Strategy Signal Agent
                 │
                 ▼
     [ 5. Validasi Skema Pydantic Ketat ]
        ├── Gagal Schema: Coba Re-prompt 1x
        └── Sukses: Simpan ke `trading_signals` (Status: PENDING)
                 │
                 ▼
     [ 6. Teruskan ke Deterministic Risk Gate ]
```
