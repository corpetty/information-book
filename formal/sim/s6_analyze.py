"""Simulation 6, step 3. Analyse the retelling chains and the judges' codings.

Reads llm/runs/*/h*.json, llm/judging/key.json and the judges' *_out.json files.
"""
import json
import math
import os
import re

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from model import OUT, save
from s6_materials import materials

HERE = os.path.dirname(os.path.abspath(__file__))
RUNS = os.path.join(HERE, "llm", "runs")
JUDGE = os.path.join(HERE, "llm", "judging")
LINES, HOPS = ("A1", "A2", "B1", "B2"), range(1, 6)
mats = {(m["topic"], m["variant"]): m for m in materials()}
key = json.load(open(os.path.join(JUDGE, "key.json")))


def wilson(k, n, z=1.96):
    if n == 0:
        return (float("nan"), float("nan"))
    p = k / n
    d = 1 + z * z / n
    c = p + z * z / (2 * n)
    h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return (round((c - h) / d, 3), round((c + h) / d, 3))


def load_out(prefix, n):
    rows = []
    for b in range(1, n + 1):
        path = os.path.join(JUDGE, f"{prefix}_{b}_out.json") if n > 1 else os.path.join(JUDGE, f"{prefix}_out.json")
        rows += json.load(open(path))
    return {r["item"]: r for r in rows}


res = {}

# ---------- texts: length and how much each hop changes
texts = {(line, h, int(it["id"][1:])): it["text"]
         for line in LINES for h in range(0, 6)
         for it in json.load(open(os.path.join(RUNS, line, f"h{h}.json")))}
words = lambda t: re.findall(r"[a-z0-9']+", t.lower())
res["mean_words_by_hop"] = {h: round(float(np.mean([len(words(texts[(l, h, t)])) for l in LINES for t in range(1, 9)])), 1)
                            for h in range(0, 6)}
def jacc(a, b):
    A, B = set(words(a)), set(words(b)); return len(A & B) / len(A | B)
res["word_overlap_with_previous_hop"] = {h: round(float(np.mean([jacc(texts[(l, h, t)], texts[(l, h - 1, t)])
                                                               for l in LINES for t in range(1, 9)])), 3) for h in HOPS}
res["share_copied_verbatim_from_previous_hop"] = {h: round(float(np.mean([texts[(l, h, t)] == texts[(l, h - 1, t)]
                                                                         for l in LINES for t in range(1, 9)])), 3) for h in HOPS}

# ---------- identification
ident = load_out("identify", 2)
by_hop = {h: [0, 0, 0] for h in HOPS}      # correct, total, said "guess"
for iid, k in key["identify"].items():
    r = ident[iid]
    by_hop[k["hop"]][0] += int(int(r["answer"]) == k["correct_answer"])
    by_hop[k["hop"]][1] += 1
    by_hop[k["hop"]][2] += int(str(r.get("could_tell", "")).lower() in ("guess", "no", "false"))
res["identification_by_hop"] = {h: {"right": c, "of": n, "share_right": round(c / n, 3),
                                    "advantage": round(2 * c / n - 1, 3),
                                    "advantage_95pct": [round(2 * x - 1, 3) for x in wilson(c, n)],
                                    "judge_said_it_was_a_guess": g}
                                for h, (c, n, g) in by_hop.items()}
a1 = res["identification_by_hop"][1]["advantage"]
res["advantage_vs_power_of_first_hop"] = {h: {"measured": res["identification_by_hop"][h]["advantage"],
                                               "first_hop_to_the_power": round(a1 ** h, 3)} for h in HOPS}

# ---------- coding of units
code = load_out("code", 2)
unit = {}                                   # (line, topic, hop) -> {"claim": status, "cond": [s1, s2, s3], "added": bool}
for cid, k in key["code"].items():
    r = code[cid]
    unit[(k["line"], k["topic"], k["hop"])] = {"claim": r["claim"], "cond": list(r["conditions"]),
                                               "added": bool(r.get("added", False))}
def share(pred, hop, what):
    vals = []
    for l in LINES:
        for t in range(1, 9):
            u = unit[(l, t, hop)]
            vals += [pred(u["claim"])] if what == "claim" else [pred(s) for s in u["cond"]]
    return sum(vals), len(vals)
kept = lambda s: s == "kept"
present = lambda s: s in ("kept", "weakened")
res["units_by_hop"] = {}
for h in HOPS:
    kc, nc = share(kept, h, "claim"); pc, _ = share(present, h, "claim")
    kv, nv = share(kept, h, "cond"); pv, _ = share(present, h, "cond")
    res["units_by_hop"][h] = {"claim_kept": round(kc / nc, 3), "claim_kept_or_weakened": round(pc / nc, 3),
                              "conditions_kept": round(kv / nv, 3), "conditions_kept_or_weakened": round(pv / nv, 3),
                              "conditions_kept_95pct": wilson(kv, nv),
                              "something_added": round(float(np.mean([unit[(l, t, h)]["added"] for l in LINES for t in range(1, 9)])), 3)}
# per-hop conditional retention of conditions: present at h given present at h-1 (hop 0: all present)
trans = {}
for h in HOPS:
    num = den = back = absent_before = 0
    for l in LINES:
        for t in range(1, 9):
            for j in range(3):
                before = True if h == 1 else present(unit[(l, t, h - 1)]["cond"][j])
                now = present(unit[(l, t, h)]["cond"][j])
                if before:
                    den += 1; num += int(now)
                else:
                    absent_before += 1; back += int(now)
    trans[h] = {"present_before": den, "still_present": num, "retention": round(num / den, 3) if den else None,
                "retention_95pct": wilson(num, den), "reappeared_after_absence": back, "absent_before": absent_before}
res["condition_retention_per_hop"] = trans
ctrans = {}
for h in HOPS:
    num = den = 0
    for l in LINES:
        for t in range(1, 9):
            before = True if h == 1 else present(unit[(l, t, h - 1)]["claim"])
            if before:
                den += 1; num += int(present(unit[(l, t, h)]["claim"]))
    ctrans[h] = {"present_before": den, "still_present": num, "retention": round(num / den, 3) if den else None}
res["claim_retention_per_hop"] = ctrans

# ordering and position
def cond_present(h, claim_first=None, pos=None):
    k = n = 0
    for l in LINES:
        for t in range(1, 9):
            if claim_first is not None and mats[(t, l[0])]["claim_first"] != claim_first:
                continue
            for j in range(3):
                if pos is not None and j != pos:
                    continue
                n += 1; k += int(present(unit[(l, t, h)]["cond"][j]))
    return k, n
res["conditions_present_by_order"] = {h: {"claim_stated_first": round(cond_present(h, True)[0] / cond_present(h, True)[1], 3),
                                           "conditions_stated_first": round(cond_present(h, False)[0] / cond_present(h, False)[1], 3)}
                                      for h in (1, 3, 5)}
res["conditions_present_by_kind"] = {h: {name: round(cond_present(h, pos=j)[0] / cond_present(h, pos=j)[1], 3)
                                          for j, name in enumerate(("who it was shown for", "strength of evidence", "size or limit of effect"))}
                                     for h in (1, 3, 5)}
def claim_present(h, claim_first):
    k = n = 0
    for l in LINES:
        for t in range(1, 9):
            if mats[(t, l[0])]["claim_first"] == claim_first:
                n += 1; k += int(present(unit[(l, t, h)]["claim"]))
    return f"{k} of {n}"
res["claim_present_by_order"] = {h: {"claim_stated_first": claim_present(h, True),
                                      "claim_stated_last": claim_present(h, False)} for h in (1, 3, 5)}
# replicate chains: do two chains from the same original keep the same conditions?
agree = n = 0
for v in "AB":
    for t in range(1, 9):
        for j in range(3):
            n += 1
            agree += int(present(unit[(v + "1", t, 5)]["cond"][j]) == present(unit[(v + "2", t, 5)]["cond"][j]))
res["two_chains_same_original_agree_on_condition_at_hop_5"] = round(agree / n, 3)

# ---------- two routes
pairs = load_out("pairs", 1)
k = sum(int(int(pairs[p]["answer"]) == key["pairs"][p]["correct_answer"]) for p in key["pairs"])
n = len(key["pairs"])
res["two_routes_at_hop_5"] = {"right": k, "of": n, "advantage": round(2 * k / n - 1, 3),
                              "advantage_95pct": [round(2 * x - 1, 3) for x in wilson(k, n)],
                              "one_route_at_hop_5": res["identification_by_hop"][5]["advantage"]}

save("s6_llm_chains.json", res)

fig, axes = plt.subplots(1, 3, figsize=(16, 4.6))
hs = list(HOPS)
axes[0].errorbar(hs, [res["identification_by_hop"][h]["advantage"] for h in hs],
                 yerr=[[res["identification_by_hop"][h]["advantage"] - res["identification_by_hop"][h]["advantage_95pct"][0] for h in hs],
                       [res["identification_by_hop"][h]["advantage_95pct"][1] - res["identification_by_hop"][h]["advantage"] for h in hs]],
                 marker="o", label="measured advantage")
axes[0].plot(hs, [a1 ** h for h in hs], "--", label="first-hop advantage to the power n")
axes[0].set_ylim(-0.1, 1.05); axes[0].set_xlabel("hops"); axes[0].set_title("which of two originals was the source?"); axes[0].legend(fontsize=8)
axes[1].plot([0] + hs, [1] + [res["units_by_hop"][h]["claim_kept_or_weakened"] for h in hs], "o-", label="claim present")
axes[1].plot([0] + hs, [1] + [res["units_by_hop"][h]["conditions_kept_or_weakened"] for h in hs], "s-", label="conditions present")
axes[1].plot([0] + hs, [1] + [res["units_by_hop"][h]["conditions_kept"] for h in hs], "s:", label="conditions kept in full")
axes[1].set_ylim(-0.05, 1.05); axes[1].set_xlabel("hops"); axes[1].set_title("what survives"); axes[1].legend(fontsize=8)
axes[2].plot(hs, [trans[h]["retention"] for h in hs], "s-", label="conditions: retention at this hop")
axes[2].plot(hs, [ctrans[h]["retention"] for h in hs], "o-", label="claim: retention at this hop")
axes[2].set_ylim(-0.05, 1.05); axes[2].set_xlabel("hop"); axes[2].set_title("per-hop retention (of what was still there)"); axes[2].legend(fontsize=8)
fig.suptitle("Simulation 6: retelling chains with a small language model as reteller (pilot, 32 chains)")
fig.tight_layout(); fig.savefig(f"{OUT}/s6_llm_chains.png", dpi=110)
print(json.dumps(res, indent=1))
