select {{ to_int('classroom_id') }} as classroom_id, {{ to_int('student_id') }} as student_id, {{ adapter.quote('status') }} as status,
       {{ to_ts('created_at') }} as created_at, current_timestamp as _ingested_at
from {{ source('oyu_app', 'memberships') }}
