-- Gold-д зөвшөөрөлгүй хүүхдийн бичлэг орсон бол алдаа.
select g.utterance_id
from {{ ref('gold_stt_dataset') }} g
join {{ ref('slv_attempts') }} a on a.attempt_id = g.source_attempt_id
where a.consent_stt <> 1
union all
select g.utterance_id
from {{ ref('gold_tts_dataset') }} g
join {{ ref('slv_attempts') }} a on a.attempt_id = g.source_attempt_id
where a.consent_tts <> 1
