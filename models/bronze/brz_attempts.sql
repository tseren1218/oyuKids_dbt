{{ config(materialized='incremental', unique_key='attempt_id', incremental_strategy='delete+insert',
          shard_key=['attempt_id'], sort_key=['created_at']) }}
select
    {{ to_int('id') }}               as attempt_id,
    {{ to_int('student_id') }}       as student_id,
    activity,
    {{ to_text('item_id') }}         as item_id,
    item_title,
    transcript,
    {{ to_int('duration_ms') }}      as duration_ms,
    {{ to_double('score') }}         as score,
    {{ to_int('stars') }}            as stars,
    {{ to_double('wpm') }}           as wpm,
    {{ to_text('details') }}         as details_json,
    {{ to_int('assignment_id') }}    as assignment_id,
    nullif(trim(audio_url), '')      as audio_url,
    {{ to_ts('created_at') }}        as created_at,
    current_timestamp                as _ingested_at
from {{ source('oyu_app', 'attempts') }}
{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %}
