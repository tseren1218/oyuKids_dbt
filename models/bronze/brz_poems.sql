select {{ to_int('id') }} as poem_id, title, author, {{ to_int(adapter.quote('level')) }} as level,
       body, emoji, current_timestamp as _ingested_at
from {{ source('oyu_app', 'poems') }}
