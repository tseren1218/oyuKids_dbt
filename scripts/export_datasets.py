"""Gold (SingleStore) → сургалтын файлууд.
  out/stt/{split}.jsonl     NeMo/HF manifest  {"audio_filepath","text","duration",...}
  out/tts/metadata.csv      LJSpeech маягийн  id|text|normalized_text
  out/llm/{split}.jsonl     chat SFT          {"messages":[system,user,assistant]}
  out/annotation_queue.csv  багшаар баталгаажуулах дараалал

pip install singlestoredb
SINGLESTORE_HOST=... SINGLESTORE_USER=... SINGLESTORE_PASSWORD=... OYU_DWH_DB=oyu_dwh python scripts/export_datasets.py
(локал тест: python scripts/export_datasets.py --duckdb oyu.duckdb)"""
import csv, json, os, sys
from pathlib import Path

if "--duckdb" in sys.argv:
    import duckdb
    conn = duckdb.connect(sys.argv[sys.argv.index("--duckdb") + 1], read_only=True)
else:
    import singlestoredb as s2
    conn = s2.connect(host=os.environ["SINGLESTORE_HOST"], port=int(os.getenv("SINGLESTORE_PORT", 3306)),
                      user=os.environ["SINGLESTORE_USER"], password=os.environ.get("SINGLESTORE_PASSWORD", ""),
                      database=os.getenv("OYU_DWH_DB", "oyu_dwh"))


def rows(sql):
    cur = conn.cursor(); cur.execute(sql)
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, r)) for r in cur.fetchall()]


out = Path("out")
for d in ("stt", "tts", "llm"):
    (out / d).mkdir(parents=True, exist_ok=True)

for split in ("train", "dev", "test"):
    with open(out / "stt" / f"{split}.jsonl", "w", encoding="utf-8") as f:
        for r in rows(f"select * from gold_stt_dataset where data_split = '{split}'"):
            f.write(json.dumps({"audio_filepath": r["audio_path"], "text": r["label_text"], "duration": float(r["duration_s"]),
                                "speaker": r["speaker_id"], "age_band": r["age_band"], "label_source": r["label_source"]},
                               ensure_ascii=False) + "\n")
    with open(out / "llm" / f"{split}.jsonl", "w", encoding="utf-8") as f:
        for r in rows(f"select * from gold_llm_sft where data_split = '{split}'"):
            f.write(json.dumps({"task": r["task"], "messages": [
                {"role": "system", "content": r["system_prompt"]},
                {"role": "user", "content": r["instruction"] + "\n\n" + r["user_input"]},
                {"role": "assistant", "content": r["assistant_output"]}]}, ensure_ascii=False) + "\n")

with open(out / "tts" / "metadata.csv", "w", encoding="utf-8") as f:
    for r in rows("select * from gold_tts_dataset order by utterance_id"):
        f.write(f'{r["utterance_id"]}|{r["tts_text"]}|{r["normalized_text"]}\n')

q = rows("select * from gold_annotation_queue order by queue_rank limit 200")
if q:
    with open(out / "annotation_queue.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=q[0].keys()); w.writeheader(); w.writerows(q)

for p in sorted(out.rglob("*.*")):
    print(f"{p}  {sum(1 for _ in open(p, encoding='utf-8'))} мөр")
