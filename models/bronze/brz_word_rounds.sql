{{ config(materialized='incremental', unique_key='round_id', incremental_strategy='delete+insert') }}
select {{ to_text('id') }} as round_id, {{ to_int('student_id') }} as student_id, {{ adapter.quote('level') }} as level,
       words as words_pipe, {{ to_int('display_seconds') }} as display_seconds,
       {{ to_int('assignment_id') }} as assignment_id, {{ to_ts('created_at') }} as created_at,
       current_timestamp as _ingested_at
from {{ source('oyu_app', 'word_rounds') }}
{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %}
