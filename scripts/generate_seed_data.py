"""Oyu app-ийн хэрэглээг дуурайсан demo өгөгдөл (seeds/*.csv) үүсгэнэ.
Production дээр эдгээрийн оронд app DB → Airbyte → raw schema ашиглана."""
import csv, json, random
from datetime import datetime, timedelta, date
from pathlib import Path

random.seed(42)
OUT = Path(__file__).resolve().parents[1] / "seeds"
NOW = datetime(2026, 10, 16, 9, 0)
DAYS = 30

PASSAGES = [
    (1, "Манай гэр бүл", "essay", 1, "Манай гэр бүл таван хүнтэй. Аав маань жолооч, ээж маань багш. Би ах, дүү хоёртойгоо хамт сургуульд явдаг. Орой бид бүгдээрээ цай ууж, өдрийн ажлаа ярилцдаг.", "", "🏠"),
    (2, "Хонины сүрэг", "tale", 1, "Хөгшин малчин өглөө эрт хониныхоо сүргийг бэлчээрт туув. Хурга, ишиг нь ээжийнхээ араас гүйлдэнэ. Нар мандахад тал нутаг алтан шаргал өнгөөр гэрэлтэв.", "", "🐑"),
    (3, "Эрдэм", "quote", 1, "Эрдэм хүнийг чимдэг, эрдэнэ хүзүүг чимдэг.", "Ардын зүйр үг", "💎"),
    (4, "Номын ач тус", "essay", 2, "Ном бол мэдлэгийн булаг юм. Өдөр бүр арван минут ном уншдаг хүүхэд шинэ үг олныг сурч, сэтгэх чадвар нь хурдан хөгждөг. Тиймээс номыг найз шигээ хайрлаж, хамгаалж явах хэрэгтэй.", "", "📚"),
    (5, "Говийн тэмээ", "essay", 2, "Тэмээ бол говийн хөлөг онгоц гэж нэрлэгддэг. Тэр олон хоног ус уухгүй явж чаддаг бөгөөд хүнд ачаа үүрээд хол замыг туулдаг. Малчид тэмээний ноосоор дулаан хувцас хийдэг.", "", "🐫"),
    (6, "Үнэг ба тогоруу", "tale", 2, "Нэгэн өдөр үнэг тогоруу зочлохоор урив. Үнэг шөлөө хавтгай тавагт хийж өгөхөд тогоруу урт хошуугаараа юу ч ууж чадсангүй. Дараа нь тогоруу үнэгийг урьж, хоолоо нарийн хүзүүтэй саванд хийв.", "", "🦊"),
    (7, "Өвгөн номын санч", "novel", 3, "Хотын захад байдаг жижигхэн номын санд өвгөн номын санч өдөр бүр ирдэг байлаа. Тэрээр хүүхдүүдэд шинэ ном ирсэн тухай баяртайгаар ярьж, хамгийн сонирхолтой түүхүүдийг чангаар уншиж өгдөг байв. Хүүхдүүд ч түүний дуу хоолойг сонсохоор амралтын өдөр бүр цуглана.", "", "👴"),
    (8, "Байгаль хамгаалах", "essay", 3, "Бидний амьдарч буй дэлхий цорын ганц гэр орон юм. Хог хаягдлаа ангилж, ус цахилгаанаа хэмнэж, мод тарьж ургуулах нь хүн бүрийн хийж чадах энгийн боловч чухал алхам. Өнөөдрийн жижиг үйлдэл маргаашийн цэвэр орчныг бүтээнэ.", "", "🌳"),
]
POEMS = [
    (1, "Намар", "Жишээ шүлэг", 1, "Навч шарлан унана\nНар намхан тусна\nШувууд урагш нисэнэ\nНамар ирлээ гэнэ", "🍂"),
    (2, "Ээж", "Жишээ шүлэг", 1, "Ээж минь өглөө эрт босно\nЭлбэг дулаан цай чанана\nЭнхрий үрсээ сэрээнэ\nЭнэ хорвоод ээж л ганцхан", "🤱"),
    (3, "Хурдан морь", "Жишээ шүлэг", 2, "Хурдан морь минь давхина\nХөх тэнгэр доор нисэх мэт\nХөлийн чимээ нь тэнгэрт хүрч\nХөгжим мэт эгшиглэнэ", "🐎"),
    (4, "Сургууль", "Жишээ шүлэг", 2, "Сургууль минь гэрэлт өргөө\nСурах мэдлэг дүүрэн өргөө\nБагш минь замчлан хөтөлнө\nБахархан бид урагшилна", "🏫"),
    (5, "Эх орон", "Жишээ шүлэг", 3, "Уулс нь өндөр, тал нь өргөн\nУрсах гол нь тунгалаг цэнгэг\nУудам нутагтаа төрсөн би\nУдам дамжин хайрлан хамгаална", "🏔️"),
]
WORDS = {
    "easy": ["ээж", "аав", "гэр", "нар", "сар", "ус", "мод", "морь", "нохой", "муур", "ном", "цай", "сүү", "өвс", "уул"],
    "medium": ["сургууль", "найз", "багш", "тэмээ", "бэлчээр", "үүлс", "цэцэрлэг", "дэвтэр", "харандаа", "хурга", "шувуу", "өглөө"],
    "hard": ["мэдлэг", "хамгаалах", "цахилгаан", "сэтгэх", "бахархал", "тунгалаг", "амьдрал", "хөгжим", "нутаг", "эрдэнэ"],
}
LEVEL_NUM = {"easy": 1, "medium": 2, "hard": 3}
CONFUSE = {"ө": "о", "ү": "у", "э": "е", "и": "й", "х": "к", "ц": "ч", "ж": "з"}  # түгээмэл дуудлага/STT андуурал
FIRST = ["Тэмүүлэн", "Анужин", "Билгүүн", "Номин", "Хулан", "Тэмүжин", "Мишээл", "Ариун", "Энхжин", "Бат-Эрдэнэ", "Солонго", "Өнөр", "Төгөлдөр", "Сарнай", "Хонгор"]
AVATARS = ["🦊", "🐼", "🐯", "🐸", "🦄", "🐻", "🐱", "🐶", "🦁", "🐨"]


def w(name, header, rows):
    with open(OUT / f"{name}.csv", "w", newline="", encoding="utf-8") as f:
        wr = csv.writer(f); wr.writerow(header); wr.writerows(rows)


def corrupt(word):
    idx = [i for i, c in enumerate(word) if c in CONFUSE]
    if not idx:
        return word[:-1] if len(word) > 2 else word + "н"
    i = random.choice(idx)
    return word[:i] + CONFUSE[word[i]] + word[i + 1:]


def simulate(ref_text, p_err):
    """Эх бичвэрээс хүүхдийн уншлагын STT transcript-ийг дуурайна → (transcript, correct, total)."""
    words = [t.strip(".,!?;:").lower() for t in ref_text.split()]
    out, correct = [], 0
    for t in words:
        r = random.random()
        if r < p_err * 0.45:
            continue  # алгассан
        if r < p_err:
            out.append(corrupt(t))  # буруу уншсан / STT андуурсан
        else:
            out.append(t); correct += 1
    if random.random() < 0.08:
        out.insert(random.randrange(len(out) + 1), random.choice(["аа", "ммм", "өө"]))  # filler
    return " ".join(out), correct, len(words)


def stars(s):
    return 3 if s >= 0.95 else 2 if s >= 0.8 else 1 if s >= 0.6 else 0


users, members, consents, students = [], [], [], []
for tid, nm in [(1, "Б.Оюунцэцэг"), (2, "Д.Ганбаатар"), (3, "С.Нармандах")]:
    users.append((tid, "teacher", f"teacher{tid}", nm, "👩‍🏫", "", 0))
classrooms = [(1, 1, "2А анги", 2, "🦊", "OYU2A"), (2, 2, "3Б анги", 3, "🐼", "OYU3B"), (3, 3, "4В анги", 4, "🦄", "OYU4V")]
cr_created = (NOW - timedelta(days=DAYS + 5)).strftime("%Y-%m-%d %H:%M:%S")
sid = 101
for cid, _, _, grade, _, _ in classrooms:
    for _ in range(15):
        status = "invited" if random.random() < 0.07 else "active"
        users.append((sid, "student", f"s{sid}", random.choice(FIRST), random.choice(AVATARS), grade, random.randint(0, 20)))
        members.append((cid, sid, status, cr_created))
        if status == "active":
            students.append({"id": sid, "grade": grade, "cid": cid,
                             "skill": min(0.97, max(0.55, random.gauss(0.72 + grade * 0.04, 0.08))),
                             "activity": random.uniform(0.3, 0.9)})
        r = random.random()
        if r < 0.85:
            consents.append((sid, True, "stt,tts,llm", cr_created))
        elif r < 0.92:
            consents.append((sid, True, "stt", cr_created))
        sid += 1

assignments, aid = [], 1
for cid, _, _, grade, _, _ in classrooms:
    for k, act in enumerate(["reading", "poems", "words", "reading"]):
        if act == "reading":
            p = random.choice([p for p in PASSAGES if p[3] <= max(1, grade - 1)]); item, title = str(p[0]), p[1]
        elif act == "poems":
            p = random.choice([p for p in POEMS if p[3] <= max(1, grade - 1)]); item, title = str(p[0]), p[1]
        else:
            lvl = ["easy", "medium", "hard"][min(2, grade - 2)]; item, title = lvl, f"Үг цээжлэх · {lvl}"
        created = NOW - timedelta(days=DAYS - 7 * k)
        assignments.append((aid, cid, act, item, title, (created + timedelta(days=6)).date().isoformat(),
                            "Чангаар, тод уншаарай.", created.strftime("%Y-%m-%d %H:%M:%S")))
        aid += 1

attempts, rounds, att_id = [], [], 1
for d in range(DAYS, -1, -1):
    day = NOW - timedelta(days=d)
    for s in students:
        if random.random() > s["activity"]:
            continue
        for _ in range(random.randint(1, 3)):
            ts = day.replace(hour=random.randint(8, 20), minute=random.randint(0, 59), second=random.randint(0, 59))
            act = random.choices(["reading", "words", "poems"], [0.5, 0.25, 0.25])[0]
            open_as = [a for a in assignments if a[1] == s["cid"] and a[2] == act
                       and datetime.fromisoformat(a[7]) <= ts and date.fromisoformat(a[5]) >= ts.date()]
            asg = random.choice(open_as) if open_as and random.random() < 0.5 else None
            maxlvl = 1 if s["grade"] <= 2 else 2 if s["grade"] == 3 else 3
            details, wpm = {}, None
            if act == "reading":
                p = next(x for x in PASSAGES if str(x[0]) == asg[3]) if asg else random.choice([x for x in PASSAGES if x[3] <= maxlvl])
                item, title, ref, lvl = str(p[0]), p[1], p[4], p[3]
            elif act == "poems":
                p = next(x for x in POEMS if str(x[0]) == asg[3]) if asg else random.choice([x for x in POEMS if x[3] <= maxlvl])
                item, title, ref, lvl = str(p[0]), p[1], p[4], p[3]
            else:
                lk = asg[3] if asg else ["easy", "medium", "hard"][random.randrange(maxlvl)]
                ws = random.sample(WORDS[lk], 6)
                rid = f"wr_{att_id:06d}"
                rounds.append((rid, s["id"], lk, "|".join(ws), 3 + LEVEL_NUM[lk], asg[0] if asg else "", ts.strftime("%Y-%m-%d %H:%M:%S")))
                item, title, ref, lvl = lk, f"Үг цээжлэх · {lk}", " ".join(ws), LEVEL_NUM[lk]
            learning = 0.002 * (DAYS - d)  # хэрэглэх тусам сайжирна
            p_err = max(0.0, min(0.6, (1 - s["skill"]) * (0.6 + 0.4 * lvl) + random.gauss(0, 0.04) - learning))
            transcript, correct, total = simulate(ref, p_err)
            score = round(correct / total, 3)
            if act == "reading":
                wpm = round(max(15, random.gauss(25 + s["grade"] * 14, 8) * (0.8 + 0.2 * s["skill"])), 1)
                dur = int(total / wpm * 60000)
                details = {"correct": correct, "total": total}
            elif act == "poems":
                dur = int(total / max(20, random.gauss(55, 10)) * 60000)
                details = {"correct": correct, "total": total, "lines": len(ref.splitlines())}
            else:
                dur = int(total * random.uniform(1.0, 2.2) * 1000)
                details = {"round_id": rid, "recalled": correct, "total": total}
            if random.random() < 0.03:
                dur = random.randint(200, 900)  # санамсаргүй товшилт
            audio = "" if random.random() < 0.04 else f"s3://oyu-recordings/recordings/{ts:%Y/%m/%d}/{att_id}.wav"
            attempts.append((att_id, s["id"], act, item, title, transcript, dur, score, stars(score), wpm or "",
                             json.dumps(details, ensure_ascii=False), asg[0] if asg else "", audio, ts.strftime("%Y-%m-%d %H:%M:%S")))
            att_id += 1

w("raw_users", ["id", "role", "username", "name", "avatar", "grade", "streak_days"], users)
w("raw_passages", ["id", "title", "category", "level", "body", "source", "emoji"], PASSAGES)
w("raw_poems", ["id", "title", "author", "level", "body", "emoji"], POEMS)
w("raw_classrooms", ["id", "teacher_id", "name", "grade", "emoji", "join_code", "created_at"], [c + (cr_created,) for c in classrooms])
w("raw_memberships", ["classroom_id", "student_id", "status", "created_at"], members)
w("raw_assignments", ["id", "classroom_id", "activity", "item_id", "title", "due_date", "instructions", "created_at"], assignments)
w("raw_word_rounds", ["id", "student_id", "level", "words", "display_seconds", "assignment_id", "created_at"], rounds)
w("raw_attempts", ["id", "student_id", "activity", "item_id", "item_title", "transcript", "duration_ms", "score", "stars", "wpm",
                   "details", "assignment_id", "audio_url", "created_at"], attempts)
w("raw_guardian_consents", ["student_id", "guardian_consent", "scope", "granted_at"], consents)
print(f"users={len(users)} attempts={len(attempts)} word_rounds={len(rounds)} consents={len(consents)}")
