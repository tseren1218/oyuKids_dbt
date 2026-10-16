-- Хүүхэд бүрийн нууцлагдсан (pseudonymized) профайл + асран хамгаалагчийн зөвшөөрөл.
-- Нэр, username, avatar энд орохгүй.
with students as (
    select * from {{ ref('brz_users') }} where role = 'student'
),
consent as (
    select student_id,
           max(case when guardian_consent then 1 else 0 end) as has_consent,
           max(scope) as scope
    from {{ ref('brz_guardian_consents') }}
    group by student_id
)
select
    s.user_id                                   as student_id,   -- зөвхөн silver (хязгаарлагдмал хандалт)
    {{ pseudonymize('s.user_id') }}             as speaker_id,
    s.grade,
    case when s.grade <= 2 then '6-8' when s.grade <= 4 then '8-10' else '10-12' end as age_band,
    coalesce(c.has_consent, 0)                                                         as has_consent,
    case when c.has_consent = 1 and c.scope like '%stt%' then 1 else 0 end             as consent_stt,
    case when c.has_consent = 1 and c.scope like '%tts%' then 1 else 0 end             as consent_tts,
    case when c.has_consent = 1 and c.scope like '%llm%' then 1 else 0 end             as consent_llm
from students s
left join consent c on c.student_id = s.user_id
