select {{ to_int('student_id') }} as student_id, {{ to_bool('guardian_consent') }} as guardian_consent,
       scope, {{ to_ts('granted_at') }} as granted_at, current_timestamp as _ingested_at
from {{ source('oyu_app', 'guardian_consents') }}
