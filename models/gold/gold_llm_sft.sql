-- oyuLLM instruction-tuning өгөгдөл (system / instruction / user_input / assistant_output).
with a as (
    select slv_attempts.*, {{ split_by_speaker('speaker_id') }} as data_split
    from {{ ref('slv_attempts') }}
    where consent_llm = 1 and reference_norm is not null and activity in ('reading', 'poems')
),
feedback as (   -- 1) Уншлагад багш шиг зөвлөгөө өгөх
    select
        concat('fb_', attempt_id)                                         as sample_id,
        'reading_feedback'                                                as task,
        'Чи бага ангийн сурагчдад уншлага заадаг, урам өгдөг багш.'      as system_prompt,
        'Сурагчийн уншлагыг эх бичвэртэй харьцуулж, товч зөвлөгөө өг.'   as instruction,
        concat('Эх бичвэр: ', reference_text, {{ nl() }}, 'Сурагч уншсан нь: ', transcript_norm) as user_input,
        concat('Оноо: ', {{ to_int('round(score * 100)') }}, '%.', {{ nl() }},
               case when missed_word_count = 0 then 'Гайхалтай! Бүх үгийг зөв уншлаа.'
                    else concat('Анхаарах үгс: ', missed_words, '.') end, {{ nl() }},
               case when score >= 0.95 then 'Дараагийн түвшний бичвэрийг туршаад үзээрэй.'
                    when score >= 0.75 then 'Анхаарах үгсээ удаан, тод давтаад дахин уншаарай.'
                    else 'Бичвэрийг өгүүлбэр болгоноор хувааж, багштайгаа хамт дахин уншаарай.' end) as assistant_output,
        attempt_id as source_attempt_id, speaker_id, created_date, data_split
    from a
),
correction as ( -- 2) Хүүхдийн яриа/STT-ийн алдаатай текстийг сэргээх
    select
        concat('cr_', attempt_id), 'asr_correction',
        'Чи монгол хэлний зөв бичгийн туслах.',
        'Хүүхдийн уншлагаас яриа танилтаар гарсан алдаатай текстийг зөв бичгийн дүрмээр сэргээ.',
        transcript_norm, reference_norm,
        attempt_id, speaker_id, created_date, data_split
    from a
    where missed_word_count between 1 and 5 and length_ratio between 0.8 and 1.2
),
leveling as (   -- 3) Бичвэрийн хүндрэлийг үнэлэх (хэрэглээний бодит өгөгдлөөр)
    select
        concat('lv_', d.activity, '_', d.item_id), 'difficulty_rating',
        'Чи хүүхдийн уншлагын материалын мэргэжилтэн.',
        'Энэ бичвэр бага ангийн сурагчдад хэр хүнд вэ? Түвшин (1-3) болон тайлбар өг.',
        r.reference_text,
        concat('Зарласан түвшин: ', d.declared_level,
               '. Сурагчдын дундаж зөв уншилт: ', {{ to_int('round(d.avg_score * 100)') }},
               '% (', d.attempts, ' оролдлого). Зөвлөмж: ',
               case d.level_recommendation when 'level_up' then 'түвшинг ахиулах.'
                                           when 'level_down' then 'түвшинг бууруулах.'
                                           else 'одоогийн түвшин тохирсон.' end),
        null, null, null, 'train'
    from {{ ref('gold_item_difficulty') }} d
    join {{ ref('slv_reference_texts') }} r on r.activity = d.activity and r.ref_id = d.item_id
    where d.activity in ('reading', 'poems')
)
select * from feedback
union all select * from correction
union all select * from leveling
