-- Бүтээгдэхүүн рүү буцах сигнал: бичвэр бүрийн бодит хүндрэл vs зарласан level.
with s as (
    select activity, item_id, max(item_title) as item_title, max(item_level) as declared_level,
           count(*)                                       as attempts,
           count(distinct student_id)                     as students,
           avg(score)                                     as avg_score,
           avg(wpm)                                       as avg_wpm,
           avg(case when stars = 3 then 1.0 else 0 end)   as pct_3_stars,
           avg(missed_word_count)                         as avg_missed_words
    from {{ ref('slv_attempts') }}
    group by activity, item_id
)
select s.*,
    1 - avg_score                                                   as observed_difficulty,
    rank() over (partition by activity order by avg_score)          as hardest_rank,
    case when avg_score >= 0.93 and declared_level < 3 then 'level_up'
         when avg_score <  0.75 and declared_level > 1 then 'level_down'
         else 'ok' end                                              as level_recommendation
from s
