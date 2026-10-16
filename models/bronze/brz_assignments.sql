select {{ to_int('id') }} as assignment_id, {{ to_int('classroom_id') }} as classroom_id, activity,
       {{ to_text('item_id') }} as item_id, title, {{ to_date('due_date') }} as due_date, instructions,
       {{ to_ts('created_at') }} as created_at, current_timestamp as _ingested_at
from {{ source('oyu_app', 'assignments') }}
