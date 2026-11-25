"""Simulation 6, step 2. Build the blind judging batches from the retelling chains.

Two tasks, given to separate judges who never see hop numbers or which chain an item is from:
  identify  the retelling and the two variants of its topic in random order: which one was
            the source? (forced choice, plus whether the judge could tell or had to guess)
  code      the retelling and the claim and three conditions of its true source: for each,
            kept, weakened or dropped; and whether anything was added.
A third small batch gives the judge two depth-5 retellings from independent chains of the
same original, to see whether a second route helps.
"""
import json
import os
import random

from s6_materials import materials

HERE = os.path.dirname(os.path.abspath(__file__))
RUNS = os.path.join(HERE, "llm", "runs")
JUDGE = os.path.join(HERE, "llm", "judging")
os.makedirs(JUDGE, exist_ok=True)
LINES, HOPS = ("A1", "A2", "B1", "B2"), range(1, 6)
rnd = random.Random(6)

mats = {(m["topic"], m["variant"]): m for m in materials()}
items = []
for line in LINES:
    for h in HOPS:
        for it in json.load(open(os.path.join(RUNS, line, f"h{h}.json"))):
            topic = int(it["id"][1:])
            items.append({"line": line, "hop": h, "topic": topic, "variant": line[0], "text": it["text"]})

key = {"identify": {}, "code": {}, "pairs": {}}

# identify
order = items[:]; rnd.shuffle(order)
batches = [[], []]
for i, it in enumerate(order):
    iid = f"i{i + 1:03d}"
    first = rnd.choice("AB"); second = "B" if first == "A" else "A"
    key["identify"][iid] = {**{k: it[k] for k in ("line", "hop", "topic", "variant")},
                            "correct_answer": 1 if first == it["variant"] else 2}
    batches[i % 2].append({"item": iid, "retelling": it["text"],
                           "original_1": mats[(it["topic"], first)]["text"],
                           "original_2": mats[(it["topic"], second)]["text"]})
for b, batch in enumerate(batches, start=1):
    json.dump(batch, open(os.path.join(JUDGE, f"identify_{b}.json"), "w"), indent=1)

# code
order = items[:]; rnd.shuffle(order)
batches = [[], []]
for i, it in enumerate(order):
    cid = f"c{i + 1:03d}"
    m = mats[(it["topic"], it["variant"])]
    key["code"][cid] = {k: it[k] for k in ("line", "hop", "topic", "variant")}
    batches[i % 2].append({"item": cid, "retelling": it["text"], "claim": m["claim"],
                           "conditions": m["caveats"]})
for b, batch in enumerate(batches, start=1):
    json.dump(batch, open(os.path.join(JUDGE, f"code_{b}.json"), "w"), indent=1)

# pairs: two independent chains, depth 5
pairs = []
by = {(it["line"], it["hop"], it["topic"]): it for it in items}
for topic in range(1, 9):
    for v in "AB":
        pairs.append((topic, v))
rnd.shuffle(pairs)
batch = []
for i, (topic, v) in enumerate(pairs):
    pid = f"p{i + 1:02d}"
    first = rnd.choice("AB"); second = "B" if first == "A" else "A"
    key["pairs"][pid] = {"topic": topic, "variant": v, "correct_answer": 1 if first == v else 2}
    batch.append({"item": pid,
                  "retelling_a": by[(v + "1", 5, topic)]["text"],
                  "retelling_b": by[(v + "2", 5, topic)]["text"],
                  "original_1": mats[(topic, first)]["text"],
                  "original_2": mats[(topic, second)]["text"]})
json.dump(batch, open(os.path.join(JUDGE, "pairs.json"), "w"), indent=1)
json.dump(key, open(os.path.join(JUDGE, "key.json"), "w"), indent=1)
print(len(items), "retellings;", [len(json.load(open(os.path.join(JUDGE, f)))) for f in
      ("identify_1.json", "identify_2.json", "code_1.json", "code_2.json", "pairs.json")])
