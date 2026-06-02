# CryptoFlow 🚀
 
> A production-ready ELT pipeline that ingests real-time cryptocurrency data from CoinGecko API into BigQuery, transforms it using dbt, and organizes it into a Star Schema for analytics.
 
---
 
## Architecture
 
```
CoinGecko API
      ↓
  ingest.py          ← Python ingestion layer
      ↓
bronze.raw_crypto    ← Raw JSON snapshot (BigQuery)
      ↓ dbt
silver.stg_crypto    ← Cleaned & parsed data
      ↓ dbt
gold.dim_coins       ← Coin dimension
gold.dim_time        ← Time dimension
gold.fct_market_snapshot ← Market facts (price, market_cap, volume)
```
 
---
 
## Tech Stack
 
| Layer | Technology |
|---|---|
| Ingestion | Python + Requests |
| Storage | Google BigQuery |
| Transformation | dbt Core |
| Data Model | Star Schema (Medallion Architecture) |
| Authentication | GCP Service Account |
 
---
 
## Project Structure
 
```
cryptoflow/
├── src/
│   └── ingest.py           ← Ingestion script
├── dbt_crypto_etl/
│   ├── models/
│   │   ├── silver/
│   │   │   └── stg_crypto.sql
│   │   └── gold/
│   │       ├── dim_coins.sql
│   │       ├── dim_time.sql
│   │       └── fct_market_snapshot.sql
│   ├── macros/
│   │   └── generate_schema_name.sql
│   ├── packages.yml
│   ├── dbt_project.yml
│   └── profiles.yml
├── logs/
├── .env.example
└── README.md
```
 
---
 
## Data Model
 
### Bronze Layer
Raw JSON snapshot from CoinGecko API stored as-is.
 
| Column | Type | Description |
|---|---|---|
| raw_payload | JSON | Full API response |
| source_url | STRING | API endpoint |
| ingested_at | TIMESTAMP | Ingestion time |
| record_count | INTEGER | Number of coins |
 
### Silver Layer - `stg_crypto`
Cleaned and parsed data with quality checks.
 
| Column | Type | Description |
|---|---|---|
| coin_id | STRING | Unique coin identifier |
| symbol | STRING | Coin symbol (btc, eth...) |
| name | STRING | Full coin name |
| price | NUMERIC | Current price in USD |
| market_cap | NUMERIC | Market capitalization |
| MC_rank | INT64 | Market cap rank |
| total_volume | NUMERIC | 24h trading volume |
| last_updated | TIMESTAMP | Last price update |
| roi_times | NUMERIC | ROI multiplier |
| roi_currency | STRING | ROI base currency |
| roi_percentage | NUMERIC | ROI percentage |
 
### Gold Layer
 
**`dim_coins`** - Coin attributes
| Column | Type |
|---|---|
| coin_sk | STRING (surrogate key) |
| coin_id | STRING |
| symbol | STRING |
| name | STRING |
| roi_times | NUMERIC |
| roi_currency | STRING |
| roi_percentage | NUMERIC |
 
**`dim_time`** - Time dimension
| Column | Type |
|---|---|
| time_id | STRING |
| last_updated | TIMESTAMP |
| year | INT64 |
| month | INT64 |
| day | INT64 |
 
**`fct_market_snapshot`** - Market facts
| Column | Type |
|---|---|
| coin_id | STRING |
| coin_sk | STRING |
| time_id | STRING |
| price | NUMERIC |
| market_cap | NUMERIC |
| MC_rank | INT64 |
| total_volume | NUMERIC |
| market_cap_category | STRING |
| price_category | STRING |
 
---
 
## Setup
 
### Prerequisites
- Python 3.12
- Google Cloud account with BigQuery enabled
- GCP Service Account with BigQuery permissions
- dbt Core
### Installation
 
```bash
# Clone the repo
git clone https://github.com/yourusername/cryptoflow.git
cd cryptoflow
 
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
 
# Install dbt packages
cd dbt_crypto_etl
dbt deps
```
 
### Environment Variables
 
Create a `.env` file based on `.env.example`:
 
```dotenv
GCP_PROJECT=your-project-id
GCP_PRIVATE_KEY_ID=your-private-key-id
GCP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n"
GCP_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
GCP_CLIENT_ID=your-client-id
API_URL=https://api.coingecko.com/api/v1/coins/markets
```
 
### Run the Pipeline
 
```bash
# 1. Ingest data into Bronze
python src/ingest.py
 
# 2. Transform with dbt
cd dbt_crypto_etl
dbt run
 
# 3. Run tests
dbt test
 
# 4. Generate docs
dbt docs generate
dbt docs serve
```
 
---
 
## dbt Tests
 
| Test | Model | Column |
|---|---|---|
| unique | fct_market_snapshot | coin_sk |
| not_null | fct_market_snapshot | coin_sk, time_id, coin_id |
 
---
 
## Key Design Decisions
 
- **ELT over ETL** → Transform inside BigQuery using dbt for better performance and maintainability
- **Medallion Architecture** → Bronze/Silver/Gold layers for clear data lineage
- **Star Schema** → Optimized for analytics queries
- **SAFE_CAST** → Prevents pipeline crashes on bad data
- **Service Account JSON** → Secure authentication without keyfile on disk
- **generate_schema_name macro** → Clean dataset naming without prefixes
---
 
## License
 
MIT
 Author
Oussama M. — Data Engineer