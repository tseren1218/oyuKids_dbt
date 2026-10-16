# oyu_flywheel — SingleStore дээр STT / TTS / LLM өгөгдөл үүсгэх dbt project

```
SingleStore: OYU_SRC_DB (app)  ──dbt-singlestore──▶  OYU_DWH_DB:  brz_* → slv_* → gold_*  ──▶ out/ (jsonl, csv)
```
Datalake ашиглахгүй. SingleStore-д schema байхгүй тул layer-уудыг хүснэгтийн prefix-ээр (`brz_` / `slv_` / `gold_`) ялгаж, нэг database дотор байрлуулна.

| Layer | Моделиуд | Юу хийдэг |
|---|---|---|
| **bronze** | `brz_*` (9) | App хүснэгтүүдийг 1:1 хуулна. `brz_attempts`, `brz_word_rounds` нь incremental |
| **silver** | `slv_speakers` | Хүүхдийн ID-г salt-тай hash болгоно. Нэр, avatar хасна. Зөвшөөрлийн scope (stt/tts/llm) |
| | `slv_reference_texts` | passage + poem + word_round-ийг нэг эх бичвэрийн хүснэгтэд нэгтгэнэ |
| | `slv_attempts` *(incremental, shard/sort key)* | Transcript ↔ эх бичвэр align: алгассан үгс (`util_numbers`-ээр задална), чанарын flag |
| **gold** | `gold_stt_dataset` | `reference_exact` + `asr_pseudo` (зөвхөн train) label |
| | `gold_tts_dataset` | 3 одтой, алдаагүй уншлага/шүлэг |
| | `gold_llm_sft` | `reading_feedback`, `asr_correction`, `difficulty_rating` |
| | `gold_annotation_queue` | Багшаар баталгаажуулах бичлэгүүд (active learning) |
| | `gold_item_difficulty` | Бичвэрийн бодит хүндрэл → level_up / level_down |
| | `gold_flywheel_daily` | Өдөр тутмын KPI |

## Ажиллуулах
```bash
pip install "dbt-core==1.11.*" dbt-singlestore singlestoredb
# SingleStore дээр нэг удаа:  CREATE DATABASE oyu_dwh;
export SINGLESTORE_HOST=<svc>.<ns>.svc.cluster.local SINGLESTORE_USER=... SINGLESTORE_PASSWORD=...
export OYU_DWH_DB=oyu_dwh OYU_PSEUDO_SALT=<нууц>

# A) Бодит app хүснэгтүүд дээр
export OYU_SRC_DB=<app database> OYU_SRC_PREFIX=''
dbt seed  --profiles-dir . -s util_numbers
dbt build --profiles-dir . --exclude resource_type:seed

# B) Demo өгөгдлөөр (app хүснэгт хараахан байхгүй бол)
python scripts/generate_seed_data.py
dbt seed  --profiles-dir .
dbt build --profiles-dir . --exclude resource_type:seed

python scripts/export_datasets.py               # → out/stt, out/tts, out/llm
```
`guardian_consents` хүснэгт app-д байхгүй бол үүсгэнэ: `student_id, guardian_consent, scope ('stt,tts,llm'), granted_at`.

Тест: `--target local` (DuckDB) дээр SingleStore-гүйгээр SQL логикийг шалгана. 47/47 PASS.
