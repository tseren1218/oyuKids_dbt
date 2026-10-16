select {{ to_int('id') }} as passage_id, title, category, {{ to_int(adapter.quote('level')) }} as level,
       body, {{ adapter.quote('source') }} as source_ref, emoji, current_timestamp as _ingested_at
from {{ source('oyu_app', 'passages') }}
