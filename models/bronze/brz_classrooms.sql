select {{ to_int('id') }} as classroom_id, {{ to_int('teacher_id') }} as teacher_id, {{ adapter.quote('name') }} as name,
       {{ to_int('grade') }} as grade, emoji, join_code, {{ to_ts('created_at') }} as created_at,
       current_timestamp as _ingested_at
from {{ source('oyu_app', 'classrooms') }}
