{{
    config(
        materialized = 'table'
    )
}}

WITH source AS(
    SELECT * 
    FROM {{ref('stg_crypto')}}
),
final AS(
    SELECT
        coin_id,
        {{ dbt_utils.generate_surrogate_key(['coin_id']) }} AS coin_sk,
        FORMAT_TIMESTAMP("%y%m%d%H%M", last_updated) AS time_id,

        s.price,
        s.market_cap,
        s.MC_rank,
        s.total_volume,

        CASE
            WHEN s.market_cap > 100000000000 THEN 'large_cap'
            WHEN s.market_cap > 1000000000  THEN 'mid_cap'
            ELSE 'small_cap'
        END AS market_cap_category,

        CASE
            WHEN s.price > 1000 THEN 'high_value'
            WHEN s.price > 1    THEN 'mid_value'
            ELSE 'low_value'
        END AS price_category



    FROM source s
)

SELECT * FROM final
