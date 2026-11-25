#!/usr/bin/env python3
"""Simulation 7, second pass over the run in llm/cli_run/.

`s7_llm_chains_cli.py --analyze` gives shares per arm and hop. This adds what is needed to
read them: whether the word limits were obeyed, how consistent the judge was, uncertainty
that respects the design (the eight topics are the independent units, so everything is
bootstrapped over topics), whether loss settles or goes on, how reruns of the same original
compare, and how far "arrived intact" is from "can still be told apart".

    python3 s7_more.py            writes out/s7_followup.json and out/s7_followup.png
"""
import itertools
import json
import math
import os
import random
import re
from collections import Counter, defaultdict

from s7_llm_chains_cli import ARMS, HERE, MATS, OUT, key_of, load_run

RUN = os.path.join(HERE, "llm", "cli_run")
HOPS = 6
TOPICS = list(range(1, 9))
LEVEL = {"kept": 2, "weakened": 1, "dropped": 0}
KINDS = ("who", "second", "size_or_limit")
BOOT = 2000


def nwords(t):
    return len(t.split())


def load():
    R, J = load_run(RUN)
    arms = [a for a in ARMS if any(r["arm"] == a for r in R.values())]
    chains = sorted({r["chain"] for r in R.values()})
    return R, J, arms, chains


R, J, ARMLIST, CHAINS = load()


def code(arm, t, v, c, hop):
    """(claim level, [three condition levels]) of one retelling; hop 0 is the original."""
    if hop == 0:
        return 2, [2, 2, 2]
    j = J[key_of(arm, t, v, c, hop)]
    return LEVEL[j["claim"]], [LEVEL[s] for s in j["own"]]


def units(arm, topics):
    return [(arm, t, v, c) for t in topics for v in "AB" for c in CHAINS]


def boot(stat, rnd=None):
    """Point estimate and a 95% percentile interval, resampling the eight topics."""
    rnd = rnd or random.Random(7)
    point = stat(TOPICS)
    reps = []
    for _ in range(BOOT):
        x = stat([rnd.choice(TOPICS) for _ in TOPICS])
        if x is not None:
            reps.append(x)
    reps.sort()
    if point is None or not reps:
        return {"value": None, "ci": [None, None]}
    lo, hi = reps[int(0.025 * len(reps))], reps[min(len(reps) - 1, int(0.975 * len(reps)))]
    out = {"value": round(point, 3), "ci": [round(lo, 3), round(hi, 3)]}
    if len(reps) < BOOT:        # the statistic was undefined on some resamples; the interval
        out["share_of_resamples_undefined"] = round(1 - len(reps) / BOOT, 3)   # covers the rest
    return out


def ratio(num, den):
    return num / den if den else None


# ------------------------------------------------------------------ what each section computes
def compliance():
    out = {}
    for arm in ARMLIST:
        lim = ARMS[arm][1]
        rows = [r for r in R.values() if r["arm"] == arm]
        n = [nwords(r["text"]) for r in rows]
        out[arm] = {"limit": lim, "mean_words": round(sum(n) / len(n), 1), "min": min(n), "max": max(n),
                    "share_over_limit": round(sum(x > lim for x in n) / len(n), 3),
                    "mean_words_by_hop": [round(sum(nwords(r["text"]) for r in rows if r["hop"] == h) /
                                                sum(r["hop"] == h for r in rows), 1) for h in range(1, HOPS + 1)]}
    out["original_words"] = {"mean": round(sum(nwords(m["text"]) for m in MATS.values()) / len(MATS), 1),
                             "min": min(nwords(m["text"]) for m in MATS.values()),
                             "max": max(nwords(m["text"]) for m in MATS.values())}
    return out


def judge_checks():
    """Three checks on the coding that need no second coder."""
    other = sum(s != "dropped" for j in J.values() for s in j["other"])
    # a condition coded absent and then present later in the same chain: information cannot
    # come back, so these are coding flips (or a judge reading a vague phrase two ways)
    back = at_risk = up = up_risk = 0
    for arm in ARMLIST:
        for u in units(arm, TOPICS):
            for h in range(2, HOPS + 1):
                a, b = code(*u, h - 1)[1], code(*u, h)[1]
                for i in range(3):
                    if a[i] == 0:
                        at_risk += 1; back += int(b[i] > 0)
                    if a[i] == 1:
                        up_risk += 1; up += int(b[i] == 2)
    # the same text judged in separate calls (a verbatim copy down a chain, or two chains that
    # produced the same sentence): how often do the codes agree?
    groups = defaultdict(list)
    for k, r in R.items():
        groups[(r["arm"], r["topic"], r["variant"], r["text"])].append(k)
    pairs = same3 = samep = 0
    for ks in groups.values():
        for a, b in itertools.combinations(ks, 2):
            ca = [LEVEL[J[a]["claim"]]] + [LEVEL[s] for s in J[a]["own"]]
            cb = [LEVEL[J[b]["claim"]]] + [LEVEL[s] for s in J[b]["own"]]
            for x, y in zip(ca, cb):
                pairs += 1; same3 += int(x == y); samep += int((x > 0) == (y > 0))
    return {"other_variant_conditions_coded_present": other,
            "other_variant_codes": 3 * len(J),
            "absent_then_present": back, "absent_at_risk": at_risk,
            "weakened_then_kept_in_full": up, "weakened_at_risk": up_risk,
            "identical_text_code_pairs": pairs,
            "identical_text_same_three_level_code": round(ratio(same3, pairs), 3),
            "identical_text_same_present_or_absent": round(ratio(samep, pairs), 3),
            "something_added_flagged": sum(j["added"] for j in J.values())}


def share(arm, hop, what):
    """A statistic of the retellings of one arm at one hop, as a function of a topic sample."""
    def stat(topics):
        num = den = 0
        for u in units(arm, topics):
            cl, co = code(*u, hop)
            if what == "present":
                num += sum(x > 0 for x in co); den += 3
            elif what == "full":
                num += sum(x == 2 for x in co); den += 3
            elif what == "claim":
                num += int(cl > 0); den += 1
            elif what == "intact":            # claim there, all three conditions with specifics
                num += int(cl > 0 and all(x == 2 for x in co)); den += 1
            elif what == "all_present":
                num += int(cl > 0 and all(x > 0 for x in co)); den += 1
            elif what == "identifiable":      # at least one own condition left
                num += int(any(x > 0 for x in co)); den += 1
        return ratio(num, den)
    return stat


def net_loss(arm, hops, what="present"):
    """Mean over the given hops of the net share lost in one hop: 1 - share(h) / share(h-1).
    Net, so that coding flips in both directions cancel instead of counting as loss."""
    thr = 1 if what == "present" else 2
    def stat(topics):
        vals = []
        for h in hops:
            a = sum(x >= thr for u in units(arm, topics) for x in code(*u, h - 1)[1])
            b = sum(x >= thr for u in units(arm, topics) for x in code(*u, h)[1])
            if a:
                vals.append(1 - b / a)
        return sum(vals) / len(vals) if vals else None
    return stat


def diff(f, g):
    def stat(topics):
        a, b = f(topics), g(topics)
        return None if a is None or b is None else a - b
    return stat


def fleiss(arm, hop, thr):
    """Agreement between the three chains of the same original on the fate of a condition,
    beyond what the overall share would give by chance. 1: the fate is fixed by the content;
    0: the three chains lose conditions independently."""
    def stat(topics):
        items = []
        for t in topics:
            for v in "AB":
                for i in range(3):
                    items.append(sum(code(arm, t, v, c, hop)[1][i] >= thr for c in CHAINS))
        m, n = len(CHAINS), len(items)
        p = sum(items) / (m * n)
        if p in (0, 1):
            return None
        pobs = sum(k * (k - 1) + (m - k) * (m - k - 1) for k in items) / (n * m * (m - 1))
        pexp = p * p + (1 - p) * (1 - p)
        return (pobs - pexp) / (1 - pexp)
    return stat


def reruns():
    out = {}
    for arm in ARMLIST:
        same = tot = 0
        for t in TOPICS:
            for v in "AB":
                for a, b in itertools.combinations(CHAINS, 2):
                    tot += 1
                    same += int(R[key_of(arm, t, v, a, 1)]["text"] == R[key_of(arm, t, v, b, 1)]["text"])
        patt = Counter()
        for t in TOPICS:
            for v in "AB":
                for i in range(3):
                    patt[sum(code(arm, t, v, c, HOPS)[1][i] > 0 for c in CHAINS)] += 1
        out[arm] = {"identical_first_retellings": [same, tot],
                    "chains_of_three_keeping_a_condition_at_last_hop": {str(k): patt[k] for k in (3, 2, 1, 0)},
                    "agreement_beyond_chance_present": boot(fleiss(arm, HOPS, 1)),
                    "agreement_beyond_chance_kept_in_full": boot(fleiss(arm, HOPS, 2))}
    return out


def claim_position():
    """Claim coded gone, originals that state the claim first against last. Each topic has
    one variant of each order, so the test is exact over the 2^8 ways of swapping the two
    labels within a topic (the topic is the unit everywhere else too)."""
    out = {}
    for when in ("last hop", "any hop"):
        hops = [HOPS] if when == "last hop" else list(range(1, HOPS + 1))
        for scope in ARMLIST + ["all arms"]:
            arms = ARMLIST if scope == "all arms" else [scope]
            lost = {o: sum(code(a, o[0], o[1], c, h)[0] == 0 for a in arms for c in CHAINS for h in hops)
                    for o in MATS}
            n_per = len(arms) * len(CHAINS) * len(hops)
            first = [o for o in sorted(MATS) if MATS[o]["claim_first"]]
            last = [o for o in sorted(MATS) if not MATS[o]["claim_first"]]
            d = []                                   # per topic: lost when last minus lost when first
            for t in TOPICS:
                f = next(o for o in first if o[0] == t); l = next(o for o in last if o[0] == t)
                d.append(lost[l] - lost[f])
            obs = sum(d)
            extreme = sum(abs(sum(x * sg for x, sg in zip(d, signs))) >= abs(obs)
                          for signs in itertools.product((1, -1), repeat=len(d)))
            out.setdefault(when, {})[scope] = {
                "claim_gone_when_first": [sum(lost[o] for o in first), n_per * len(first)],
                "claim_gone_when_last": [sum(lost[o] for o in last), n_per * len(last)],
                "originals_with_any_first": sum(lost[o] > 0 for o in first),
                "originals_with_any_last": sum(lost[o] > 0 for o in last),
                "p_two_sided": round(extreme / 2 ** len(d), 4)}
    return out


def how_conditions_went():
    """When a condition was first coded gone, what was it at the hop before?"""
    out = {}
    for arm in ARMLIST + ["all arms"]:
        arms = ARMLIST if arm == "all arms" else [arm]
        full = vague = ever_vague = 0
        for a in arms:
            for u in units(a, TOPICS):
                for i in range(3):
                    seq = [code(*u, h)[1][i] for h in range(0, HOPS + 1)]
                    if 0 in seq:
                        h = seq.index(0)
                        full += int(seq[h - 1] == 2); vague += int(seq[h - 1] == 1)
                        ever_vague += int(1 in seq[:h])
        out[arm] = {"conditions_ever_coded_gone": full + vague, "in_full_at_the_hop_before": full,
                    "vaguer_at_the_hop_before": vague, "vaguer_at_some_earlier_hop": ever_vague}
    return out


def claim_against_conditions():
    """The book's prediction is that the claim outlives its conditions. At the last hop: share
    of claims present minus share of conditions present, and how many retellings are a claim
    with at most one condition left."""
    out = {}
    for arm in ARMLIST:
        def gap(topics, arm=arm):
            cs = [code(*u, HOPS) for u in units(arm, topics)]
            return sum(cl > 0 for cl, _ in cs) / len(cs) - sum(x > 0 for _, co in cs for x in co) / (3 * len(cs))
        cs = [code(*u, HOPS) for u in units(arm, TOPICS)]
        out[arm] = {"claim_present_minus_condition_present": boot(gap),
                    "claim_present_with_at_most_one_condition": sum(cl > 0 and sum(x > 0 for x in co) <= 1 for cl, co in cs),
                    "of": len(cs)}
    return out


def claim_fate():
    """The headline claim: in full, vaguer, or gone, and how often it is gone while the
    conditions are still there (the headline cut and the small print kept)."""
    out = {}
    for arm in ARMLIST:
        rows = {}
        for h in range(1, HOPS + 1):
            cs = [code(*u, h) for u in units(arm, TOPICS)]
            n = len(cs)
            rows[h] = {"in_full": round(sum(cl == 2 for cl, _ in cs) / n, 3),
                       "vaguer": round(sum(cl == 1 for cl, _ in cs) / n, 3),
                       "gone": sum(cl == 0 for cl, _ in cs),
                       "gone_with_two_or_more_conditions_present":
                           sum(cl == 0 and sum(x > 0 for x in co) >= 2 for cl, co in cs),
                       "of": n}
        chains_ever = sum(any(code(*u, h)[0] == 0 for h in range(1, HOPS + 1)) for u in units(arm, TOPICS))
        out[arm] = {"by_hop": rows, "chains_where_the_claim_was_ever_coded_gone": chains_ever,
                    "chains": len(units(arm, TOPICS))}
    back = risk = 0
    for arm in ARMLIST:
        for u in units(arm, TOPICS):
            for h in range(2, HOPS + 1):
                if code(*u, h - 1)[0] == 0:
                    risk += 1; back += int(code(*u, h)[0] > 0)
    out["coded_gone_then_present_at_the_next_hop"] = [back, risk]
    return out


def kappa(pairs, levels):
    n = len(pairs)
    po = sum(a == b for a, b in pairs) / n
    pe = sum((sum(a == l for a, _ in pairs) / n) * (sum(b == l for _, b in pairs) / n) for l in levels)
    return None if pe == 1 else round((po - pe) / (1 - pe), 3)


def second_coder():
    """A second coder (another model, blind to the first coding, to arm and to hop) coded a
    stratified random sample of 150 retellings, five per arm and hop. Files in
    llm/cli_run/second_coder/: items.json (what it saw), key.json, codes.json."""
    d = os.path.join(RUN, "second_coder")
    if not os.path.exists(os.path.join(d, "codes.json")):
        return None
    key = json.load(open(os.path.join(d, "key.json")))
    codes = {c["id"]: c for c in json.load(open(os.path.join(d, "codes.json")))}
    cl, own, other2 = [], [], 0
    meaning = defaultdict(Counter)
    by_arm = defaultdict(lambda: {"first": [0, 0, 0], "second": [0, 0, 0]})
    shifted, added = [], [0, 0]
    for n, kk in key.items():
        c2, k = codes[int(n)], kk["key"]
        j, r = J[k], R[k]
        cl.append((LEVEL[j["claim"]], LEVEL[c2["claim"]]))
        for lab, (who, idx) in kk["owner"].items():
            x = LEVEL[c2["conditions"][lab]]
            if who == "own":
                own.append((LEVEL[j["own"][idx]], x))
                for name, y in (("first", LEVEL[j["own"][idx]]), ("second", x)):
                    by_arm[r["arm"]][name][0] += int(y > 0); by_arm[r["arm"]][name][1] += int(y == 2)
                    by_arm[r["arm"]][name][2] += 1
            else:
                other2 += int(x > 0)
        meaning[r["arm"]][c2.get("meaning", "same")] += 1
        meaning["all arms"][c2.get("meaning", "same")] += 1
        if c2.get("meaning") == "shifted":
            shifted.append({"key": k, "text": r["text"], "note": c2.get("note", ""),
                            "first_coder_claim": j["claim"]})
        added[0] += int(j["added"]); added[1] += int(bool(c2.get("added")))
    binar = lambda ps: [(a > 0, b > 0) for a, b in ps]
    full = [(a == 2, b == 2) for a, b in own]
    intact, sh = [], {"first": 0, "second": 0, "both": 0}
    shift_by_orig, n_by_orig = Counter(), Counter()
    for n, kk in key.items():
        c2, k = codes[int(n)], kk["key"]
        j = J[k]
        o1 = [LEVEL[x] for x in j["own"]]
        o2 = [LEVEL[c2["conditions"][lab]] for lab, (who, idx) in sorted(kk["owner"].items(), key=lambda z: z[1][1]) if who == "own"]
        c1, cc2 = LEVEL[j["claim"]], LEVEL[c2["claim"]]
        intact.append((c1 > 0 and all(x == 2 for x in o1), cc2 > 0 and all(x == 2 for x in o2)))
        orig = (R[k]["topic"], R[k]["variant"])
        n_by_orig[orig] += 1
        if c2.get("meaning") == "shifted":
            shift_by_orig[orig] += 1
            a1 = c1 > 0 and all(x > 0 for x in o1); a2 = cc2 > 0 and all(x > 0 for x in o2)
            sh["first"] += int(a1); sh["second"] += int(a2); sh["both"] += int(a1 and a2)
    def shifted_share(topics):
        num = sum(shift_by_orig[(t, v)] for t in topics for v in "AB")
        den = sum(n_by_orig[(t, v)] for t in topics for v in "AB")
        return ratio(num, den)
    conf = lambda ps: {f"{a}->{b}": sum(1 for x, y in ps if x == a and y == b)
                       for a in (2, 1, 0) for b in (2, 1, 0)}
    return {"retellings": len(key),
            "conditions": {"codes": len(own),
                           "same_three_level": round(sum(a == b for a, b in own) / len(own), 3),
                           "kappa_three_level": kappa(own, (0, 1, 2)),
                           "same_present_or_absent": round(sum(a == b for a, b in binar(own)) / len(own), 3),
                           "kappa_present_or_absent": kappa(binar(own), (True, False)),
                           "first_to_second (2 in full, 1 vaguer, 0 gone)": conf(own)},
            "claim": {"codes": len(cl),
                      "same_three_level": round(sum(a == b for a, b in cl) / len(cl), 3),
                      "kappa_three_level": kappa(cl, (0, 1, 2)),
                      "same_present_or_absent": round(sum(a == b for a, b in binar(cl)) / len(cl), 3),
                      "kappa_present_or_absent": kappa(binar(cl), (True, False)),
                      "first_to_second (2 in full, 1 vaguer, 0 gone)": conf(cl)},
            "share_present_and_in_full_by_arm": {
                a: {w: {"present": round(v[w][0] / v[w][2], 3), "in_full": round(v[w][1] / v[w][2], 3)}
                    for w in ("first", "second")} for a, v in by_arm.items()},
            "conditions_in_full_or_not": {"same": round(sum(a == b for a, b in full) / len(full), 3),
                                          "kappa": kappa(full, (True, False))},
            "arrived_intact": {"same": round(sum(a == b for a, b in intact) / len(intact), 3),
                               "kappa": kappa(intact, (True, False)),
                               "first_says_intact": sum(a for a, _ in intact),
                               "second_says_intact": sum(b for _, b in intact)},
            "shifted_share": boot(shifted_share),
            "shifted_by_original": {f"{t}{v}": [shift_by_orig[(t, v)], n_by_orig[(t, v)]]
                                    for (t, v) in sorted(n_by_orig) if shift_by_orig[(t, v)]},
            "shifted_with_claim_and_all_conditions_present": sh,
            "other_variant_conditions_coded_present_by_second": other2,
            "something_added_first_and_second": added,
            "meaning_by_arm": {a: dict(c) for a, c in meaning.items()},
            "shifted": shifted}


def kinds():
    out = {}
    for scope in ARMLIST + ["all arms"]:
        arms = ARMLIST if scope == "all arms" else [scope]
        def by(i, thr):
            def stat(topics):
                xs = [code(*u, HOPS)[1][i] >= thr for a in arms for u in units(a, topics)]
                return sum(xs) / len(xs)
            return stat
        out[scope] = {KINDS[i]: {"present": boot(by(i, 1)), "kept_in_full": boot(by(i, 2))} for i in range(3)}
        out[scope]["second_minus_others_present"] = boot(
            lambda tp: by(1, 1)(tp) - (by(0, 1)(tp) + by(2, 1)(tp)) / 2)
    return out


def length_and_content():
    """Words against what survived, at the last hop, and the shortest version found that
    still had the claim and all three conditions with their specifics."""
    by_n = defaultdict(list)
    for arm in ARMLIST:
        for u in units(arm, TOPICS):
            cl, co = code(*u, HOPS)
            by_n[sum(x > 0 for x in co)].append(nwords(R[key_of(*u, HOPS)]["text"]))
    shortest = {}
    for (t, v), m in sorted(MATS.items()):
        best = None
        for k, r in R.items():
            if r["topic"] == t and r["variant"] == v:
                cl, co = LEVEL[J[k]["claim"]], [LEVEL[s] for s in J[k]["own"]]
                if cl == 2 and all(x == 2 for x in co):
                    n = nwords(r["text"])
                    if best is None or n < best[0]:
                        best = (n, r["text"], k)
        shortest[f"{t}{v}"] = {"original_words": nwords(m["text"]),
                               "shortest_intact_words": best[0] if best else None,
                               "text": best[1] if best else None, "key": best[2] if best else None}
    enough = {}
    for arm in ARMLIST:
        n = bad = not_intact = too_short = 0
        for k, r in R.items():
            if r["arm"] != arm:
                continue
            need = shortest[f"{r['topic']}{r['variant']}"]["shortest_intact_words"]
            cl, co = LEVEL[J[k]["claim"]], [LEVEL[x] for x in J[k]["own"]]
            lost = not (cl > 0 and all(x == 2 for x in co))
            not_intact += int(lost)
            if need is not None and nwords(r["text"]) >= need:
                n += 1; bad += int(lost)
            elif need is not None:
                too_short += int(lost)
        enough[arm] = {"retellings_at_least_as_long_as_the_shortest_intact_version": n, "of_which_not_intact": bad,
                       "not_intact": not_intact, "of_which_shorter_than_any_intact_version": too_short}
    src = Counter(v["key"].split("|")[0] for v in shortest.values() if v["key"])
    return {"long_enough_but_not_intact": enough, "arm_of_the_shortest_intact_version": dict(src),
            "mean_words_at_last_hop_by_conditions_present":
            {str(k): {"n": len(v), "mean_words": round(sum(v) / len(v), 1)} for k, v in sorted(by_n.items())},
            "shortest_intact_version_per_original": shortest}


def main():
    res = {"note": "intervals are 95% percentile bootstrap intervals over the 8 topics",
           "compliance": compliance(), "judge": judge_checks(), "arms": {}}
    for arm in ARMLIST:
        A = {"by_hop": {}}
        for h in range(1, HOPS + 1):
            A["by_hop"][h] = {w: boot(share(arm, h, w)) for w in
                              ("present", "full", "claim", "intact", "all_present", "identifiable")}
        A["conditions_left_at_last_hop"] = dict(sorted(Counter(
            sum(x > 0 for x in code(*u, HOPS)[1]) for u in units(arm, TOPICS)).items(), reverse=True))
        early, late = net_loss(arm, [2, 3]), net_loss(arm, [4, 5, 6])
        A["net_loss_per_hop_present"] = {"hop_1": boot(net_loss(arm, [1])),
                                         "hops_2_to_6": boot(net_loss(arm, [2, 3, 4, 5, 6])),
                                         "hops_2_to_3": boot(early), "hops_4_to_6": boot(late),
                                         "late_minus_early": boot(diff(late, early))}
        fe, fl = net_loss(arm, [2, 3], "full"), net_loss(arm, [4, 5, 6], "full")
        A["net_loss_per_hop_kept_in_full"] = {"hop_1": boot(net_loss(arm, [1], "full")),
                                              "hops_2_to_6": boot(net_loss(arm, [2, 3, 4, 5, 6], "full")),
                                              "hops_2_to_3": boot(fe), "hops_4_to_6": boot(fl),
                                              "late_minus_early": boot(diff(fl, fe))}
        # if each condition went on being lost independently at the rate of hops 2 to 6, the
        # number of hops after which half the retellings would have no condition left:
        # (1 - r^n)^3 = 1/2. Given for the rate and for the two ends of its interval. The three
        # kinds of condition are not lost at equal rates, so this is a planning figure only.
        hops_to_half = lambda loss: (round(math.log(1 - 0.5 ** (1 / 3)) / math.log(1 - loss))
                                     if loss is not None and 0 < loss < 1 else None)
        late = net_loss(arm, [2, 3, 4, 5, 6])(TOPICS)
        ci = A["net_loss_per_hop_present"]["hops_2_to_6"]["ci"]
        A["extrapolated_hops_to_half_unidentifiable"] = {
            "at_the_rate": hops_to_half(late), "range": [hops_to_half(ci[1]), hops_to_half(ci[0])]}
        res["arms"][arm] = A

    con = {}
    pairs = [("careful20", "careful10"), ("careful40", "careful20"), ("careful40", "careful10"),
             ("careful20", "punchy20"), ("careful20", "gist20")]
    for a, b in pairs:
        if a in ARMLIST and b in ARMLIST:
            con[f"{a} minus {b}"] = {w: boot(diff(share(a, HOPS, w), share(b, HOPS, w)))
                                     for w in ("present", "full", "intact", "claim")}
    res["contrasts_at_last_hop"] = con
    res["reruns"] = reruns()
    res["claim_position"] = claim_position()
    res["claim_fate"] = claim_fate()
    res["how_conditions_went"] = how_conditions_went()
    res["claim_against_conditions"] = claim_against_conditions()
    res["second_coder"] = second_coder()
    res["kinds_at_last_hop"] = kinds()
    res["length_and_content"] = length_and_content()
    json.dump(res, open(os.path.join(OUT, "s7_followup.json"), "w"), indent=1)

    c = res["compliance"]
    print("word limits:", {a: (c[a]["mean_words"], c[a]["share_over_limit"]) for a in ARMLIST})
    print("judge:", res["judge"])
    for arm in ARMLIST:
        A = res["arms"][arm]
        print(f"\n== {arm}")
        for h in (1, 3, 6):
            print(f"  hop {h}: " + ", ".join(f"{w} {A['by_hop'][h][w]['value']} {A['by_hop'][h][w]['ci']}"
                                             for w in ("present", "full", "intact", "identifiable")))
        print("  net loss, present:", {k: (v["value"], v["ci"]) for k, v in A["net_loss_per_hop_present"].items()})
        print("  net loss, in full:", {k: (v["value"], v["ci"]) for k, v in A["net_loss_per_hop_kept_in_full"].items()})
        print("  conditions left at last hop:", A["conditions_left_at_last_hop"],
              " extrapolated hops to half unidentifiable:", A["extrapolated_hops_to_half_unidentifiable"])
        print("  reruns:", res["reruns"][arm])
    print("\ncontrasts at last hop:")
    for k, v in con.items():
        print(" ", k, {w: (x["value"], x["ci"]) for w, x in v.items()})
    for when, cp in res["claim_position"].items():
        print(f"\nclaim position, {when}:", {k: (v["claim_gone_when_first"], v["claim_gone_when_last"], v["p_two_sided"])
                                              for k, v in cp.items()})
    print("\nhow conditions went:", res["how_conditions_went"])
    print("\nclaim against conditions:", {k: (v["claim_present_minus_condition_present"]["value"],
                                              v["claim_present_minus_condition_present"]["ci"],
                                              v["claim_present_with_at_most_one_condition"]) for k, v in res["claim_against_conditions"].items()})
    print("\nclaim fate:")
    for arm in ARMLIST:
        f = res["claim_fate"][arm]
        print(f"  {arm}: ever gone in {f['chains_where_the_claim_was_ever_coded_gone']} of {f['chains']} chains; " +
              "; ".join(f"hop {h}: full {r['in_full']}, vaguer {r['vaguer']}, gone {r['gone']} ({r['gone_with_two_or_more_conditions_present']} with conditions)"
                        for h, r in f["by_hop"].items() if h in (1, 3, 6)))
    print("  coded gone, then present at the next hop:", res["claim_fate"]["coded_gone_then_present_at_the_next_hop"])
    print("\nkinds:", json.dumps({k: {q: (w["present"]["value"], w["present"]["ci"]) if "present" in w else (w["value"], w["ci"])
                                      for q, w in v.items()} for k, v in res["kinds_at_last_hop"].items()}, indent=1))
    print("\nlength:", res["length_and_content"]["mean_words_at_last_hop_by_conditions_present"])
    for o, s in res["length_and_content"]["shortest_intact_version_per_original"].items():
        print(f"  {o}: {s['original_words']} -> {s['shortest_intact_words']}  {s['text']}")

    if res["second_coder"]:
        sc = res["second_coder"]
        print("\nsecond coder:", json.dumps({k: v for k, v in sc.items() if k != "shifted"}, indent=1))
        for x in sc["shifted"]:
            print(f"  shifted [{x['key']}] {x['text']}  -- {x['note']}")

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        fig, axes = plt.subplots(1, 4, figsize=(20, 4.8))
        hs = list(range(1, HOPS + 1))
        for arm in ARMLIST:
            A = res["arms"][arm]["by_hop"]
            for ax, w in zip(axes[:3], ("present", "full", "intact")):
                y = [A[h][w]["value"] for h in hs]
                line, = ax.plot([0] + hs, [1] + y, "o-", label=arm, ms=4)
                ax.fill_between(hs, [A[h][w]["ci"][0] for h in hs], [A[h][w]["ci"][1] for h in hs],
                                color=line.get_color(), alpha=0.12)
            axes[3].plot(hs, [A[h]["identifiable"]["value"] for h in hs], "o-", label=arm, ms=4)
        for ax, title in zip(axes, ("a condition is still present", "a condition still has its specifics",
                                    "arrived intact: claim and all three\nconditions with specifics",
                                    "source can still be told apart\n(at least one condition left)")):
            ax.set_title(title, fontsize=10); ax.set_xlabel("hops"); ax.set_ylim(-0.03, 1.03)
        axes[0].legend(fontsize=8, loc="lower left")
        fig.suptitle("Simulation 7: 1,440 language-model retellings; bands are 95% intervals over the 8 topics")
        fig.tight_layout(); fig.savefig(os.path.join(OUT, "s7_followup.png"), dpi=110)
    except Exception as e:                               # noqa: BLE001
        print(f"(no figure: {e})")


if __name__ == "__main__":
    main()
