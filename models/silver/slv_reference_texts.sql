-- Хүүхэд ЮУ уншихаар байсан бэ — бүх activity-ийн эх бичвэр нэг хүснэгтэд.
with refs as (
    select 'reading' as activity, {{ to_text('passage_id') }} as ref_id, title, level, category,
           replace(body, {{ nl() }}, ' ') as reference_text
    from {{ ref('brz_passages') }}
    union all
    select 'poems', {{ to_text('poem_id') }}, title, level, 'poem',
           replace(body, {{ nl() }}, ' ')
    from {{ ref('brz_poems') }}
    union all
    select 'words', round_id, concat('Үг цээжлэх · ', level),
           case level when 'easy' then 1 when 'medium' then 2 else 3 end, 'word_list',
           replace(words_pipe, '|', ' ')
    from {{ ref('brz_word_rounds') }}
)
select refs.*, {{ normalize_mn('reference_text') }} as reference_norm
from refs
