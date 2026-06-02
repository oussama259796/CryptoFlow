{{
    config(
        materialized = 'table'
    )
}}

WITH source AS (
    SELECT
        coin_id,
        symbol,
        name,
        roi_times,
        roi_currency,
        roi_percentage
        FROM {{ref('stg_crypto')}}
),
enriched AS (
    SELECT
        coin_id,
        {{ dbt_utils.generate_surrogate_key(['coin_id']) }} AS coin_sk,
        
        CASE
            WHEN symbol IS NULL THEN name
            ELSE symbol
        END AS symbol,

        CASE
            WHEN name IS NULL THEN symbol
            ELSE name
        END AS name,

        roi_times,
        roi_currency,
        roi_percentage

        FROM source
)

SELECT * FROM enriched