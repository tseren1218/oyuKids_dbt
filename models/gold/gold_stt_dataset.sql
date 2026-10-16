-- STT (хүүхдийн монгол яриа) сургалтын manifest.
--   reference_exact : хүүхэд эх бичвэрийг яг уншсан → эх бичвэр = үнэн label
--   asr_pseudo      : ялимгүй алдаатай → STT transcript = pseudo-label (зөвхөн train)
with base as (
    select slv_attempts.*,
        case when missed_word_count = 0 and hyp_word_count = ref_word_count then 'reference_exact'
             when score >= {{ var('stt_pseudo_min_score') }}               then 'asr_pseudo' end as label_source,
        {{ split_by_speaker('speaker_id') }} as data_split
    from {{ ref('slv_attempts') }}
    where consent_stt = 1 and is_usable_audio = 1
)
select
    concat('stt_', attempt_id)                                                  as utterance_id,
    attempt_id                                                                  as source_attempt_id,
    audio_url                                                                   as audio_path,
    case when label_source = 'reference_exact' then reference_norm else transcript_norm end as label_text,
    label_source,
    score                                                                       as label_confidence,
    duration_s, speaker_id, age_band, grade, activity, item_level, created_date, data_split
from base
where label_source is not null
  and (data_split = 'train' or label_source = 'reference_exact')   -- dev/test зөвхөн баталгаатай label
