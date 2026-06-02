{{
    config(
        materialized = 'table'
    )
}}

WITH source AS (
    SELECT DISTINCT
        last_updated
    FROM {{ref('stg_crypto')}}
    WHERE last_updated IS NOT NULL
),

enriched AS(
    SELECT
        FORMAT_TIMESTAMP("%y%m%d%H%M", last_updated) AS time_id,

        last_updated,

        EXTRACT(YEAR FROM last_updated) as year,
        EXTRACT(MONTH FROM last_updated) AS month,
        EXTRACT(DAY FROM last_updated) AS day

    FROM source
)

SELECT * FROM enriched