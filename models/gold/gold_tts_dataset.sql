-- TTS (хүүхдэд ээлтэй уншлагын хэм) — зөвхөн төгс уншсан, хэм нь тогтвортой бичлэг.
select
    concat('tts_', attempt_id)                       as utterance_id,
    attempt_id                                       as source_attempt_id,
    audio_url                                        as audio_path,
    reference_text                                   as tts_text,          -- цэг таслалтай (prosody)
    reference_norm                                   as normalized_text,
    case activity when 'poems' then 'recitation' else 'read_aloud' end as style,
    speaker_id, age_band, wpm, duration_s, item_level, created_date,
    {{ split_by_speaker('speaker_id') }}             as data_split
from {{ ref('slv_attempts') }}
where consent_tts = 1 and is_usable_audio = 1
  and activity in ('reading', 'poems')
  and stars = 3 and missed_word_count = 0 and hyp_word_count = ref_word_count
  and duration_s between 2 and 40
  and (wpm is null or wpm between {{ var('tts_min_wpm') }} and {{ var('tts_max_wpm') }})
