#!/usr/bin/env python3
"""Simulation 7. Retelling chains with a language model, scripted through the `claude` CLI.

The pilot (simulation 6) ran 32 chains through subagents. This script runs the larger study
with one model call per retelling, so every hop sees nothing but the previous version:

  arms      careful10 / careful20 / careful40   "pass it on in your own words", at most
                                                10 / 20 / 40 words (a budget sweep)
            punchy20                            "short, striking, easy to repeat", 20 words
            gist20                              "you remember the gist, not the details"
  chains    3 independent chains per original per arm (these are reruns of the same chain
            with the same reteller, so their disagreement measures noise in the reteller)
  hops      6
  judging   one blind call per retelling: the claim and the six conditions of BOTH variants
            of the topic, in random order; each coded kept / weakened / dropped. Which
            variant a retelling came from is then read off the conditions that survive.

Default size: 16 originals x 5 arms x 3 chains x 6 hops = 1,440 retellings and as many
judging calls. Everything is written to llm/cli_run/ as it arrives; rerunning the script
continues where it stopped.

    python3 s7_llm_chains_cli.py --smoke      8 retellings and 8 judgings, to check the login works
    python3 s7_llm_chains_cli.py              the full run
    python3 s7_llm_chains_cli.py --analyze    only redo the analysis of what is on disk
    python3 s7_llm_chains_cli.py --dry-run    no model calls (fake reteller and judge)

Requires the `claude` command to be logged in (`claude auth login`).
"""
import argparse
import concurrent.futures as cf
import hashlib
import json
import math
import os
import random
import re
import subprocess
import sys
import tempfile
import threading
import time

from s6_materials import materials

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")

ARMS = {
    "careful10": ("careful", 10),
    "careful20": ("careful", 20),
    "careful40": ("careful", 40),
    "punchy20": ("punchy", 20),
    "gist20": ("gist", 20),
}
STYLE = {
    "careful": "A friend just told you the text in the user's message, in conversation. Pass it "
               "on to someone else in your own words, in at most {w} words. Say what you would "
               "naturally pass on; you do not have to keep everything.",
    "punchy": "A friend just told you the text in the user's message, in conversation. Pass it "
              "on the way people do in casual talk: make it short, striking and easy to repeat, "
              "in at most {w} words.",
    "gist": "A friend told you the text in the user's message a while ago. You remember the "
            "gist, not the details. Pass on what you remember, in your own words, in at most "
            "{w} words.",
}
RETELL_TAIL = (" Do not add facts that were not in what you were told. Output only your "
               "retelling, with no preamble and no quotation marks.")
JUDGE_SYSTEM = (
    "You are a coder in a retelling experiment. The user's message gives a retelling, a claim, "
    "and six conditions labelled c1 to c6. The retelling descends from a source that stated "
    "the claim and three of the six conditions; the other three belong to a different source "
    "and should normally be absent. For the claim and for each condition, judge from the "
    "retelling alone whether it still conveys it:\n"
    '  "kept"      it conveys it with its specifics, in any wording\n'
    '  "weakened"  it is partly there or vaguer (for example "older adults" for "adults over '
    '65", "a small study" for "a trial of 48 people for six weeks", or one half of a two-part '
    "condition)\n"
    '  "dropped"   it does not convey it at all\n'
    'Also set "added" to true if the retelling states a fact that is in neither the claim nor '
    "any of the six conditions.\n"
    "Output only a JSON object of this form and nothing else:\n"
    '{"claim": "kept", "conditions": {"c1": "dropped", "c2": "kept", "c3": "weakened", '
    '"c4": "dropped", "c5": "dropped", "c6": "dropped"}, "added": false}'
)
CODES = ("kept", "weakened", "dropped")

MATS = {(m["topic"], m["variant"]): m for m in materials()}
lock = threading.Lock()
stats = {"calls": 0, "cost": 0.0, "failed": 0}


# ----------------------------------------------------------------------------- model calls
FLAG_SETS = [
    ["--tools", "", "--no-session-persistence", "--setting-sources", "", "--strict-mcp-config"],
    ["--tools", "", "--no-session-persistence", "--strict-mcp-config"],
    ["--tools", "", "--no-session-persistence"],
    [],
]


class Caller:
    def __init__(self, dry_run):
        self.dry_run = dry_run
        self.flags = None
        self.cwd = tempfile.mkdtemp(prefix="retell_")

    def raw(self, system, prompt, model, flags):
        cmd = ["claude", "-p", prompt, "--model", model, "--system-prompt", system,
               "--output-format", "json"] + flags
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=180, cwd=self.cwd)
        try:
            d = json.loads(p.stdout)
        except json.JSONDecodeError:
            raise RuntimeError((p.stderr or p.stdout or "no output").strip()[:300])
        if d.get("is_error"):
            raise RuntimeError(str(d.get("result"))[:300])
        with lock:
            stats["calls"] += 1
            stats["cost"] += float(d.get("total_cost_usd") or 0)
        return str(d.get("result", "")).strip()

    def probe(self, model):
        """Find a set of flags under which the CLI answers cleanly."""
        last = None
        for flags in FLAG_SETS:
            try:
                r = self.raw("Reply with exactly the two letters OK and nothing else.", "Go.",
                             model, flags)
            except Exception as e:                       # noqa: BLE001
                last = e
                if "authenticate" in str(e).lower() or "log in" in str(e).lower():
                    break
                continue
            if re.sub(r"[^a-z]", "", r.lower()) == "ok":
                self.flags = flags
                return
            last = RuntimeError(f"unexpected reply to the probe: {r[:120]!r}")
        sys.exit(f"The `claude` command did not answer: {last}\n"
                 "If this is a login problem, run `claude auth login` and try again.")

    def call(self, system, prompt, model):
        for attempt in range(4):
            try:
                return self.raw(system, prompt, model, self.flags)
            except Exception as e:                       # noqa: BLE001
                err = e
                time.sleep(3 * (attempt + 1) ** 2)
        with lock:
            stats["failed"] += 1
        raise RuntimeError(f"gave up after 4 attempts: {err}")


def words(t):
    return re.findall(r"[a-z0-9']+", t.lower())


def content_words(t):
    stop = set("a an the and or but of to in on at by for with from as is are was were be been it "
               "its this that only not no so than also had has have who what which when about "
               "people".split())
    return [w for w in words(t) if w not in stop and len(w) > 2]


def fake_retell(text, budget, rnd):
    sents = [s for s in re.split(r"(?<=[.!?])\s+", text) if s]
    if len(sents) > 1 and rnd.random() < 0.5:
        sents.pop(rnd.randrange(len(sents)))
    out = " ".join(sents).split()
    return " ".join(out[:budget])


def fake_judge(retelling, claim, conds):
    have = set(content_words(retelling))
    def code(t):
        cw = content_words(t)
        share = sum(w in have for w in cw) / max(len(cw), 1)
        return "kept" if share > 0.7 else "weakened" if share > 0.35 else "dropped"
    return {"claim": code(claim), "conditions": {k: code(v) for k, v in conds.items()}, "added": False}


# ----------------------------------------------------------------------------- storage
def load_jsonl(path):
    rows = {}
    if os.path.exists(path):
        for line in open(path):
            line = line.strip()
            if line:
                r = json.loads(line)
                rows[r["key"]] = r
    return rows


def append_jsonl(path, row):
    with lock:
        with open(path, "a") as f:
            f.write(json.dumps(row) + "\n")


def key_of(arm, topic, variant, chain, hop):
    return f"{arm}|{topic}|{variant}|{chain}|{hop}"


# ----------------------------------------------------------------------------- run
def run_chain(caller, args, store, path, arm, topic, variant, chain):
    style, budget = ARMS[arm]
    system = STYLE[style].format(w=budget) + RETELL_TAIL
    text = MATS[(topic, variant)]["text"]
    rnd = random.Random(key_of(arm, topic, variant, chain, 0))
    for hop in range(1, args.hops + 1):
        k = key_of(arm, topic, variant, chain, hop)
        if k in store:
            text = store[k]["text"]
            continue
        if caller.dry_run:
            new = fake_retell(text, budget, rnd)
        else:
            try:
                new = caller.call(system, text, args.reteller_model)
            except RuntimeError as e:
                print(f"  chain {k} stopped: {e}", flush=True)
                return
        new = new.strip().strip('"').strip()
        row = {"key": k, "arm": arm, "topic": topic, "variant": variant, "chain": chain,
               "hop": hop, "text": new}
        store[k] = row
        append_jsonl(path, row)
        text = new


def judge_one(caller, args, row, path, done):
    k = row["key"]
    if k in done:
        return
    topic, variant = row["topic"], row["variant"]
    other = "B" if variant == "A" else "A"
    conds = [("own", c) for c in MATS[(topic, variant)]["caveats"]] + \
            [("other", c) for c in MATS[(topic, other)]["caveats"]]
    rnd = random.Random(int(hashlib.sha256(k.encode()).hexdigest(), 16))
    rnd.shuffle(conds)
    labelled = {f"c{i + 1}": c for i, (_, c) in enumerate(conds)}
    owner = {f"c{i + 1}": o for i, (o, _) in enumerate(conds)}
    claim = MATS[(topic, variant)]["claim"]
    prompt = ("Retelling: " + row["text"] + "\n\nClaim: " + claim + "\n\nConditions:\n" +
              "\n".join(f"{c}: {t}" for c, t in labelled.items()))
    if caller.dry_run:
        verdict = fake_judge(row["text"], claim, labelled)
    else:
        verdict = None
        for _ in range(2):
            try:
                reply = caller.call(JUDGE_SYSTEM, prompt, args.judge_model)
            except RuntimeError as e:
                print(f"  judging {k} failed: {e}", flush=True)
                return
            m = re.search(r"\{.*\}", reply, re.S)
            try:
                v = json.loads(m.group(0)) if m else None
            except json.JSONDecodeError:
                v = None
            if v and v.get("claim") in CODES and isinstance(v.get("conditions"), dict) and \
                    all(v["conditions"].get(c) in CODES for c in labelled):
                verdict = v
                break
        if verdict is None:
            print(f"  judging {k}: reply was not usable", flush=True)
            return
    out = {"key": k, "claim": verdict["claim"],
           "own": [verdict["conditions"][c] for c in sorted(labelled) if owner[c] == "own"],
           "own_text": [labelled[c] for c in sorted(labelled) if owner[c] == "own"],
           "other": [verdict["conditions"][c] for c in sorted(labelled) if owner[c] == "other"],
           "added": bool(verdict.get("added", False))}
    done[k] = out
    append_jsonl(path, out)


def progress(label, futures):
    t0, n = time.time(), len(futures)
    for i, f in enumerate(cf.as_completed(futures), start=1):
        f.result()
        if i % max(1, n // 20) == 0 or i == n:
            print(f"  {label}: {i}/{n} done, {time.time() - t0:.0f}s, "
                  f"{stats['calls']} calls, ${stats['cost']:.2f} reported by the CLI", flush=True)


# ----------------------------------------------------------------------------- analysis
def wilson(k, n, z=1.96):
    if n == 0:
        return [None, None]
    p = k / n
    d = 1 + z * z / n
    c = p + z * z / (2 * n)
    h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return [round((c - h) / d, 3), round((c + h) / d, 3)]


def load_run(run_dir):
    """Retellings and judgements of a run, with each judgement's "own" conditions put back in
    the order of the materials.

    The judge saw the six conditions in a random order and "own" is stored in that order, so
    without this step position i is a different condition at every hop and in every chain.
    (The first version of the analysis skipped it: its per-hop retention, by-kind and rerun
    figures compared different conditions. Shares summed over the three conditions were not
    affected.)"""
    R = load_jsonl(os.path.join(run_dir, "retellings.jsonl"))
    J = load_jsonl(os.path.join(run_dir, "judgments.jsonl"))
    for k, j in J.items():
        if k in R and "own_text" in j:
            cav = MATS[(R[k]["topic"], R[k]["variant"])]["caveats"]
            by_text = dict(zip(j["own_text"], j["own"]))
            if not all(c in by_text for c in cav):
                raise ValueError(f"judgement {k}: its conditions are not those of the materials")
            j["own"], j["own_text"] = [by_text[c] for c in cav], list(cav)
    return R, J


def analyze(run_dir, hops, tag):
    R, J = load_run(run_dir)
    present = lambda s: s in ("kept", "weakened")
    res = {"retellings": len(R), "judged": len(J), "arms": {}}
    arms = [a for a in ARMS if any(r["arm"] == a for r in R.values())]
    for arm in arms:
        A = {"by_hop": {}}
        chains = sorted({(r["topic"], r["variant"], r["chain"]) for r in R.values() if r["arm"] == arm})
        for hop in range(1, hops + 1):
            rows = [R[k] for k in (key_of(arm, t, v, c, hop) for t, v, c in chains) if k in R]
            js = [J[r["key"]] for r in rows if r["key"] in J]
            if not rows:
                continue
            prev = lambda r: (MATS[(r["topic"], r["variant"])]["text"] if hop == 1 else
                              R.get(key_of(arm, r["topic"], r["variant"], r["chain"], hop - 1), {}).get("text"))
            pairs = [(r["text"], prev(r)) for r in rows if prev(r)]
            jac = [len(set(words(a)) & set(words(b))) / max(len(set(words(a)) | set(words(b))), 1)
                   for a, b in pairs]
            h = {"retellings": len(rows), "judged": len(js),
                 "mean_words": round(sum(len(words(r["text"])) for r in rows) / len(rows), 1),
                 "word_overlap_with_previous": round(sum(jac) / len(jac), 3) if jac else None,
                 "copied_verbatim": round(sum(a == b for a, b in pairs) / len(pairs), 3) if pairs else None}
            if js:
                n = len(js)
                own_p = [sum(present(s) for s in j["own"]) for j in js]
                oth_p = [sum(present(s) for s in j["other"]) for j in js]
                right = sum(o > 0 and x == 0 for o, x in zip(own_p, oth_p))
                wrong = sum(o == 0 and x > 0 for o, x in zip(own_p, oth_p))
                h.update({
                    "claim_present": round(sum(present(j["claim"]) for j in js) / n, 3),
                    "conditions_present": round(sum(own_p) / (3 * n), 3),
                    "conditions_kept_in_full": round(sum(s == "kept" for j in js for s in j["own"]) / (3 * n), 3),
                    "no_condition_left": round(sum(o == 0 for o in own_p) / n, 3),
                    "advantage": round((right - wrong) / n, 3),
                    "advantage_95pct_of_share_identified": wilson(right, n),
                    "conditions_of_the_other_variant_coded_present": round(sum(oth_p) / (3 * n), 3),
                    "something_added": round(sum(j["added"] for j in js) / n, 3),
                })
                for name, cf_ in (("claim_first", True), ("claim_last", False)):
                    sub = [j for r, j in ((r, J[r["key"]]) for r in rows if r["key"] in J)
                           if MATS[(r["topic"], r["variant"])]["claim_first"] == cf_]
                    if sub:
                        h[f"claim_present_when_{name}"] = round(sum(present(j["claim"]) for j in sub) / len(sub), 3)
                        h[f"conditions_present_when_{name}"] = round(
                            sum(present(s) for j in sub for s in j["own"]) / (3 * len(sub)), 3)
                kinds = ("who", "evidence", "size_or_limit")
                h["conditions_present_by_kind"] = {
                    kinds[i]: round(sum(present(j["own"][i]) for j in js) / n, 3) for i in range(3)}
            A["by_hop"][hop] = h
        # per-hop retention of conditions still present, and of the claim
        ret = {}
        for hop in range(1, hops + 1):
            num = den = cnum = cden = 0
            for t, v, c in chains:
                k, kp = key_of(arm, t, v, c, hop), key_of(arm, t, v, c, hop - 1)
                if k not in J or (hop > 1 and kp not in J):
                    continue
                for i in range(3):
                    before = True if hop == 1 else present(J[kp]["own"][i])
                    if before:
                        den += 1; num += int(present(J[k]["own"][i]))
                before = True if hop == 1 else present(J[kp]["claim"])
                if before:
                    cden += 1; cnum += int(present(J[k]["claim"]))
            if den:
                ret[hop] = {"conditions": round(num / den, 3), "conditions_95pct": wilson(num, den),
                            "claim": round(cnum / cden, 3) if cden else None}
        A["retention_per_hop"] = ret
        # reruns: same original, same arm, different chains
        same = tot = agree = atot = 0
        for t in range(1, 9):
            for v in "AB":
                cs = sorted(c for (tt, vv, c) in chains if tt == t and vv == v)
                for i in range(len(cs)):
                    for j in range(i + 1, len(cs)):
                        a, b = key_of(arm, t, v, cs[i], 1), key_of(arm, t, v, cs[j], 1)
                        if a in R and b in R:
                            tot += 1; same += int(R[a]["text"] == R[b]["text"])
                        a, b = key_of(arm, t, v, cs[i], hops), key_of(arm, t, v, cs[j], hops)
                        if a in J and b in J:
                            for q in range(3):
                                atot += 1
                                agree += int(present(J[a]["own"][q]) == present(J[b]["own"][q]))
        A["reruns"] = {"identical_text_at_hop_1": round(same / tot, 3) if tot else None,
                       "same_fate_of_a_condition_at_last_hop": round(agree / atot, 3) if atot else None}
        res["arms"][arm] = A
    os.makedirs(OUT, exist_ok=True)
    json.dump(res, open(os.path.join(OUT, f"{tag}.json"), "w"), indent=1)

    lines = [f"retellings {res['retellings']}, judged {res['judged']}"]
    for arm, A in res["arms"].items():
        lines.append(f"\n== {arm}")
        lines.append("hop  n  words  overlap  verbatim  claim  cond  cond_full  none_left  advantage  other_present")
        for hop, h in A["by_hop"].items():
            g = lambda k: "-" if h.get(k) is None else h[k]
            lines.append(f"{hop:>3} {h['retellings']:>3} {g('mean_words'):>6} {g('word_overlap_with_previous'):>8} "
                         f"{g('copied_verbatim'):>9} {g('claim_present'):>6} {g('conditions_present'):>5} "
                         f"{g('conditions_kept_in_full'):>10} {g('no_condition_left'):>10} {g('advantage'):>10} "
                         f"{g('conditions_of_the_other_variant_coded_present'):>13}")
        lines.append("per-hop retention (conditions / claim): " +
                     ", ".join(f"{hp}: {r['conditions']} / {r['claim']}" for hp, r in A["retention_per_hop"].items()))
        last = A["by_hop"].get(max(A["by_hop"])) if A["by_hop"] else {}
        lines.append(f"last hop, claim first vs last: claim {last.get('claim_present_when_claim_first')} vs "
                     f"{last.get('claim_present_when_claim_last')}; conditions "
                     f"{last.get('conditions_present_when_claim_first')} vs {last.get('conditions_present_when_claim_last')}")
        lines.append(f"last hop, conditions by kind: {last.get('conditions_present_by_kind')}")
        lines.append(f"reruns: {A['reruns']}")
    summary = "\n".join(lines)
    open(os.path.join(OUT, f"{tag}_summary.txt"), "w").write(summary + "\n")

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        fig, axes = plt.subplots(1, 4, figsize=(19, 4.6))
        for arm, A in res["arms"].items():
            hs = [h for h in A["by_hop"] if "advantage" in A["by_hop"][h]]
            if not hs:
                continue
            axes[0].plot(hs, [A["by_hop"][h]["advantage"] for h in hs], "o-", label=arm)
            axes[1].plot([0] + hs, [1] + [A["by_hop"][h]["conditions_present"] for h in hs], "o-", label=arm)
            axes[2].plot([0] + hs, [1] + [A["by_hop"][h]["claim_present"] for h in hs], "o-", label=arm)
            axes[3].plot(hs, [A["by_hop"][h]["copied_verbatim"] for h in hs], "o-", label=arm)
        for ax, title in zip(axes, ("advantage: which variant was the source", "conditions still present",
                                    "claim still present", "copied word for word from the previous hop")):
            ax.set_title(title, fontsize=10); ax.set_xlabel("hops"); ax.set_ylim(-0.05, 1.05)
        axes[0].legend(fontsize=8)
        fig.suptitle("Simulation 7: language-model retelling chains by instruction and word budget")
        fig.tight_layout(); fig.savefig(os.path.join(OUT, f"{tag}.png"), dpi=110)
    except Exception as e:                               # noqa: BLE001
        print(f"(no figure: {e})")
    return summary


# ----------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--arms", default=",".join(ARMS), help="comma-separated; default all five")
    ap.add_argument("--chains", type=int, default=3, help="independent chains per original per arm")
    ap.add_argument("--hops", type=int, default=6)
    ap.add_argument("--topics", default="1,2,3,4,5,6,7,8")
    ap.add_argument("--workers", type=int, default=4, help="model calls in parallel")
    ap.add_argument("--reteller-model", default="haiku")
    ap.add_argument("--judge-model", default="sonnet")
    ap.add_argument("--smoke", action="store_true", help="tiny run: 1 topic, 2 arms, 1 chain, 2 hops")
    ap.add_argument("--dry-run", action="store_true", help="no model calls")
    ap.add_argument("--analyze", action="store_true", help="only analyse what is on disk")
    ap.add_argument("--yes", action="store_true", help="do not ask before starting")
    args = ap.parse_args()

    tag = "s7_llm_chains"
    sub = "cli_run"
    if args.smoke:
        args.arms, args.chains, args.hops, args.topics = "careful20,punchy20", 1, 2, "1"
        tag, sub = "s7_smoke", "cli_smoke"
    if args.dry_run:
        tag, sub = tag + "_dryrun", sub + "_dryrun"
    run_dir = os.path.join(HERE, "llm", sub)
    os.makedirs(run_dir, exist_ok=True)
    arms = [a for a in args.arms.split(",") if a]
    for a in arms:
        if a not in ARMS:
            sys.exit(f"unknown arm {a}; choose from {', '.join(ARMS)}")
    topics = [int(t) for t in args.topics.split(",")]

    if not args.analyze:
        rpath, jpath = os.path.join(run_dir, "retellings.jsonl"), os.path.join(run_dir, "judgments.jsonl")
        R, J = load_jsonl(rpath), load_jsonl(jpath)
        todo = [(a, t, v, c) for a in arms for t in topics for v in "AB" for c in range(1, args.chains + 1)]
        want = len(todo) * args.hops
        need_r = sum(key_of(a, t, v, c, h) not in R for a, t, v, c in todo for h in range(1, args.hops + 1))
        need_j = sum(key_of(a, t, v, c, h) not in J for a, t, v, c in todo for h in range(1, args.hops + 1))
        print(f"{want} retellings wanted; {need_r} still to make, {need_j} still to judge "
              f"(reteller: {args.reteller_model}, judge: {args.judge_model}, {args.workers} in parallel)")
        caller = Caller(args.dry_run)
        if not args.dry_run and (need_r or need_j):
            caller.probe(args.reteller_model)
            print("the `claude` command answers; flags used:", " ".join(repr(f) for f in caller.flags) or "(none)")
            # keep a record of what answered: the result files do not say otherwise
            with open(os.path.join(run_dir, "run_info.jsonl"), "a") as f:
                f.write(json.dumps({"started": time.strftime("%Y-%m-%d %H:%M:%S"),
                                    "reteller_model": args.reteller_model, "judge_model": args.judge_model,
                                    "flags": caller.flags, "to_make": need_r, "to_judge": need_j}) + "\n")
            if not args.yes and not args.smoke:
                if input(f"Start about {need_r + need_j} model calls? [y/N] ").strip().lower() != "y":
                    sys.exit("stopped")
        with cf.ThreadPoolExecutor(args.workers) as ex:
            progress("chains", [ex.submit(run_chain, caller, args, R, rpath, *x) for x in todo])
            rows = [R[k] for k in (key_of(a, t, v, c, h) for a, t, v, c in todo
                                   for h in range(1, args.hops + 1)) if k in R]
            progress("judging", [ex.submit(judge_one, caller, args, r, jpath, J) for r in rows])
        if stats["failed"]:
            print(f"{stats['failed']} calls failed after retries; run the script again to fill the gaps")
        print(f"model calls: {stats['calls']}; cost reported by the CLI: ${stats['cost']:.2f}")

    summary = analyze(run_dir, args.hops, tag)
    print("\n" + summary)
    print(f"\nWritten: out/{tag}.json, out/{tag}_summary.txt, out/{tag}.png, llm/{sub}/")


if __name__ == "__main__":
    main()
