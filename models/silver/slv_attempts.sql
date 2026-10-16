{{ config(materialized='incremental', unique_key='attempt_id', incremental_strategy='delete+insert',
          shard_key=['attempt_id'], sort_key=['created_at']) }}
-- Нэг мөр = нэг бичлэг, эх бичвэртэйгээ align хийгдсэн, чанарын flag-тай.
-- Алгассан үгсийг util_numbers-ээр үг үгээр задалж олно (SingleStore-д array/lambda хэрэггүй).
with a as (
    select brz.*,
           case when activity = 'words' then {{ json_str('details_json', 'round_id') }} else item_id end as ref_id
    from {{ ref('brz_attempts') }} brz
    {% if is_incremental() %}
    where created_at > (select max(created_at) from {{ this }})
    {% endif %}
),
joined as (
    select
        a.attempt_id, a.student_id, a.activity, a.item_id, a.ref_id, a.item_title,
        a.assignment_id, a.audio_url, a.duration_ms, a.score, a.stars, a.wpm, a.created_at,
        {{ to_date('a.created_at') }}                       as created_date,
        a.transcript,
        {{ normalize_mn('a.transcript') }}                  as transcript_norm,
        r.reference_text, r.reference_norm, r.level         as item_level,
        sp.speaker_id, sp.grade, sp.age_band, sp.consent_stt, sp.consent_tts, sp.consent_llm
    from a
    left join {{ ref('slv_reference_texts') }} r on r.activity = a.activity and r.ref_id = a.ref_id
    left join {{ ref('slv_speakers') }} sp       on sp.student_id = a.student_id
),
counted as (
    select joined.*,
        {{ word_count('reference_norm') }}  as ref_word_count,
        {{ word_count('transcript_norm') }} as hyp_word_count,
        duration_ms / 1000.0                as duration_s
    from joined
),
ref_words as (
    select c.attempt_id, n.n as pos, c.transcript_norm,
           {{ nth_word('c.reference_norm', 'n.n') }} as word
    from counted c
    join {{ ref('util_numbers') }} n on n.n <= c.ref_word_count
),
missed as (
    select attempt_id, count(*) as missed_word_count, {{ agg_words('word', 'pos', ', ') }} as missed_words
    from ref_words
    where not {{ has_word('transcript_norm', 'word') }}
    group by attempt_id
),
final as (
    select c.*,
        coalesce(m.missed_word_count, 0)                            as missed_word_count,
        m.missed_words,
        1.0 * c.hyp_word_count / nullif(c.ref_word_count, 0)        as length_ratio
    from counted c
    left join missed m on m.attempt_id = c.attempt_id
)
select
    attempt_id, student_id, speaker_id, grade, age_band, activity, item_id, ref_id, item_title, item_level,
    assignment_id, case when assignment_id is null then 'organic' else 'assigned' end as usage_type,
    audio_url, duration_ms, duration_s, score, stars, wpm,
    transcript, transcript_norm, reference_text, reference_norm,
    ref_word_count, hyp_word_count, missed_word_count, missed_words, length_ratio,
    coalesce(consent_stt, 0) as consent_stt,
    coalesce(consent_tts, 0) as consent_tts,
    coalesce(consent_llm, 0) as consent_llm,
    -- чанарын flag-ууд (0/1)
    case when audio_url is not null then 1 else 0 end                                                     as has_audio,
    case when duration_ms between {{ var('min_duration_ms') }} and {{ var('max_duration_ms') }} then 1 else 0 end as duration_ok,
    case when length_ratio between 0.5 and 1.5 then 1 else 0 end                                          as alignment_ok,
    case when audio_url is not null
          and duration_ms between {{ var('min_duration_ms') }} and {{ var('max_duration_ms') }}
          and reference_norm is not null
          and length_ratio between 0.5 and 1.5 then 1 else 0 end                                          as is_usable_audio,
    created_at, created_date
from final
