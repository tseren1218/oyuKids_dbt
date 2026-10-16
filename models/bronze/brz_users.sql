select {{ to_int('id') }} as user_id, {{ adapter.quote('role') }} as role, username, {{ adapter.quote('name') }} as name, avatar,
       {{ to_int('grade') }} as grade, {{ to_int('streak_days') }} as streak_days,
       current_timestamp as _ingested_at
from {{ source('oyu_app', 'users') }}
