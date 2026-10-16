-- Нэг хүүхэд train/dev/test-ийн 2+ split-д орвол алдаа.
select speaker_id from {{ ref('gold_stt_dataset') }}
group by speaker_id having count(distinct data_split) > 1
