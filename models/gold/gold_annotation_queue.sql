-- Active learning: загвар хамгийн их эргэлзэж буй бичлэгийг багшаар баталгаажуулах дараалал.
-- Багш app дотор 1 товшилтоор зөвлөвөл → reference_exact label болж STT-д буцна (flywheel).
select
    attempt_id, audio_url, speaker_id, age_band, activity, item_title,
    reference_text, transcript_norm, missed_words, score,
    1 - abs(score - 0.85)                                              as queue_priority,
    row_number() over (order by abs(score - 0.85), created_at desc)    as queue_rank
from {{ ref('slv_attempts') }}
where consent_stt = 1 and is_usable_audio = 1
  and not (missed_word_count = 0 and hyp_word_count = ref_word_count)
  and score between 0.6 and {{ var('annotation_max_score') }}
