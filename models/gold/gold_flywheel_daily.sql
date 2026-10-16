-- Flywheel KPI: хэрэглээ → өгөгдөл → сургалтын бэлэн цаг.
with usage_d as (
    select created_date,
           count(distinct student_id)                                         as active_students,
           count(*)                                                           as attempts,
           avg(case when usage_type = 'organic' then 1.0 else 0 end)          as organic_share,
           avg(score)                                                         as avg_score,
           sum(case when has_audio = 1 then duration_s else 0 end) / 3600.0   as raw_audio_hours
    from {{ ref('slv_attempts') }} group by created_date
),
stt as (
    select created_date, sum(duration_s) / 3600.0 as stt_hours,
           sum(case when label_source = 'reference_exact' then duration_s else 0 end) / 3600.0 as stt_exact_hours
    from {{ ref('gold_stt_dataset') }} group by created_date
),
tts as (select created_date, sum(duration_s) / 3600.0 as tts_hours from {{ ref('gold_tts_dataset') }} group by created_date),
llm as (select created_date, count(*) as llm_samples from {{ ref('gold_llm_sft') }} where created_date is not null group by created_date)
select u.*,
       coalesce(s.stt_hours, 0)       as stt_hours,
       coalesce(s.stt_exact_hours, 0) as stt_exact_hours,
       coalesce(t.tts_hours, 0)       as tts_hours,
       coalesce(l.llm_samples, 0)     as llm_samples,
       coalesce(s.stt_hours, 0) / nullif(u.raw_audio_hours, 0)                    as stt_yield,
       sum(coalesce(s.stt_hours, 0)) over (order by u.created_date)               as stt_hours_cum,
       sum(coalesce(l.llm_samples, 0)) over (order by u.created_date)             as llm_samples_cum
from usage_d u
left join stt s on s.created_date = u.created_date
left join tts t on t.created_date = u.created_date
left join llm l on l.created_date = u.created_date
