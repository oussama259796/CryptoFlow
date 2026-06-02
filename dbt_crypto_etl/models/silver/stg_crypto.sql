{{
    config(
        materialized = 'table'
    )
}}

WITH source AS(
    SELECT
        raw_payload,
        source_url,
        ingested_at
        FROM {{source('bronze_layer', 'raw_crypto')}}
),
unnested AS(
    SELECT 
        source_url,
        ingested_at,
        coin
        FROM source,
        UNNEST(JSON_QUERY_ARRAY(raw_payload)) AS coin
),
parsed AS (
    SELECT
        JSON_VALUE(coin, '$.id') AS coin_id,
        JSON_VALUE(coin, '$.symbol') AS symbol,
        JSON_VALUE(coin, '$.name') AS name,
        SAFE_CAST(JSON_VALUE(coin, '$.current_price')AS NUMERIC) AS price,
        SAFE_CAST(JSON_VALUE(coin, '$.market_cap')AS NUMERIC) AS market_cap,
        SAFE_CAST(JSON_VALUE(coin, '$.market_cap_rank')AS INT64) AS MC_rank,
        SAFE_CAST(JSON_VALUE(coin, '$.total_volume')AS NUMERIC) AS total_volume,
        SAFE_CAST(JSON_VALUE(coin, '$.last_updated') AS TIMESTAMP) AS last_updated,
        SAFE_CAST(JSON_VALUE(coin, '$.roi.times')AS NUMERIC) AS roi_times,
        JSON_VALUE(coin, '$.roi.currency') AS roi_currency,
        SAFE_CAST(JSON_VALUE(coin, '$.roi.percentage')AS NUMERIC) AS roi_percentage,

        source_url,
        ingested_at

    FROM unnested
),
quality_checked AS(
    SELECT
        coin_id,
        symbol,
        name,
        price,

        CASE
            WHEN market_cap <= 0 THEN NULL
            ELSE market_cap
        END market_cap,

        MC_rank, 
        total_volume,

        CASE
            WHEN last_updated IS NULL THEN ingested_at
            WHEN last_updated > CURRENT_TIMESTAMP THEN ingested_at
            ELSE last_updated
        END last_updated,

        roi_times,
        roi_currency,
        roi_percentage,
        source_url,
        ingested_at,
        ROW_NUMBER() OVER(
                        PARTITION BY coin_id
                        ORDER BY ingested_at DESC
                        ) AS rn
    FROM parsed
    WHERE coin_id IS NOT NULL
    
),
deduped AS (
    SELECT * FROM quality_checked
    WHERE rn = 1
)

SELECT * FROM deduped