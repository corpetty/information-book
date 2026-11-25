"""Simulation 5. Covering numbers of a real repertoire: the budget-against-tolerance curve.

Theorem (Lossy.exists_relay_iff): some relay with budget B delivers every idea of a set
within tolerance eps if and only if fewer than 2^(B+1) balls of radius eps cover the set.
So the least budget is floor(log2 N(eps)), with N the covering number. The model does not
say what N is for real ideas. Here it is computed for two repertoires from this book:

  claims     the canonical claims in ../../data/claims.json and, when the file is present,
             the claim candidates in ../../data/claim-candidates.jsonl (a generated,
             git-ignored file: run `make harvest` at the repository root to create it)
  sentences  every prose sentence of the chapters in ../../content

Both inputs are the book's current text, so the numbers move when the book is edited. The
counts used are written into the output.

The distance is a stand-in, not a measured distance between ideas: texts are turned into
tf-idf vectors, reduced to 50 dimensions (latent semantic analysis, fitted on the
sentences), and compared by angle, scaled so that 0 is the same direction and 1 opposite.
It is lexical: two sentences saying the same thing in different words are far apart.

Covering numbers are bracketed with the farthest-point greedy rule. After k centres the
largest distance of any text to its nearest centre is r_k. Then k balls of radius r_k cover
the set, and the first k + 1 centres are pairwise at least r_k apart, so no cover by balls
of radius below r_k / 2 has fewer than k + 1 balls.

The theorem is about covers whose centres may be any point, not only texts of the set. A
second upper bound allows that: clusters are grown around a centre that is the normalised
mean of its members, nudged towards the farthest one, as long as every member stays within
the tolerance. The smaller of the two upper bounds is reported.
"""
import glob
import json
import math
import os
import re

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from model import OUT, save

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
STOP = set("""a an the and or but if then of to in on at by for with from as is are was were be been
being it its this that these those there here not no nor so than too very can could should would
may might must will shall do does did done have has had having i you he she we they them his her
their our your my me us what which who whom whose when where why how all any both each few more
most other some such only own same s t just also into over under again further once about above
below between through during before after up down out off because while one two""".split())


def tokens(text):
    return [w for w in re.findall(r"[a-z][a-z'-]+", text.lower()) if w not in STOP and len(w) > 2]


def load_claims():
    d = json.load(open(os.path.join(ROOT, "data", "claims.json")))
    texts = [c.get("summary") or c.get("label") for c in d["claims"]]
    cand = os.path.join(ROOT, "data", "claim-candidates.jsonl")
    if os.path.exists(cand):
        for line in open(cand):
            texts.append(json.loads(line)["text"])
    else:
        print("note: data/claim-candidates.jsonl is missing (run `make harvest`); "
              "using the canonical claims only")
    return [t for t in texts if t and len(tokens(t)) >= 3]


def load_sentences():
    out = []
    for path in sorted(glob.glob(os.path.join(ROOT, "content", "*.md"))):
        text = open(path).read()
        text = re.sub(r"^---.*?---", "", text, flags=re.S)           # front matter
        text = re.sub(r"\[\[([^\]|]*\|)?([^\]]*)\]\]", r"\2", text)    # wiki links
        text = re.sub(r"[#*_`>]", " ", text)
        for para in text.split("\n"):
            for s in re.split(r"(?<=[.!?])\s+", para):
                if len(tokens(s)) >= 6:
                    out.append(s.strip())
    return out


def embed(fit_texts, texts, dim=50):
    vocab = {}
    docs = [tokens(t) for t in fit_texts]
    for d in docs:
        for w in set(d):
            vocab[w] = vocab.get(w, 0) + 1
    words = sorted(w for w, n in vocab.items() if n >= 2)
    index = {w: i for i, w in enumerate(words)}
    idf = np.array([math.log(len(docs) / vocab[w]) + 1 for w in words])

    def tfidf(ts):
        Mx = np.zeros((len(ts), len(words)))
        for i, t in enumerate(ts):
            for w in tokens(t):
                j = index.get(w)
                if j is not None:
                    Mx[i, j] += 1
        Mx = np.log1p(Mx) * idf
        return Mx

    A = tfidf(fit_texts)
    _, _, Vt = np.linalg.svd(A, full_matrices=False)
    V = Vt[:dim].T
    Z = tfidf(texts) @ V
    norms = np.linalg.norm(Z, axis=1)
    keep = norms > 1e-9
    return Z[keep] / norms[keep, None]


def angular(U, v):
    return np.arccos(np.clip(U @ v, -1, 1)) / math.pi


def greedy_radii(U):
    n = len(U)
    nearest = angular(U, U[0])
    radii = [float(nearest.max())]                 # r_1: one centre
    for _ in range(1, n):
        nxt = int(nearest.argmax())
        if nearest[nxt] <= 1e-12:
            break
        nearest = np.minimum(nearest, angular(U, U[nxt]))
        radii.append(float(nearest.max()))
    return radii                                    # radii[k-1] = r_k


def bracket(radii, eps):
    upper = next((k for k, r in enumerate(radii, start=1) if r <= eps), len(radii))
    lower = 1 + max((k for k, r in enumerate(radii, start=1) if r > 2 * eps), default=0)
    return lower, upper


def cover_any_centre(U, eps, rng):
    """An upper bound on the covering number with centres allowed anywhere on the sphere.
    Every text is marked covered only once it is within eps of a chosen centre."""
    n = len(U)
    uncovered = np.ones(n, bool)
    k = 0
    for p in rng.permutation(n):
        if not uncovered[p]:
            continue
        members, c = [int(p)], U[p].copy()
        while True:
            idx = np.where(uncovered)[0]
            idx = idx[~np.isin(idx, members)]
            if len(idx) == 0:
                break
            grown = False
            for j in idx[np.argsort(angular(U[idx], c))][:8]:
                trial = members + [int(j)]
                cc = U[trial].sum(0)
                cc /= np.linalg.norm(cc)
                for _ in range(30):
                    dd = angular(U[trial], cc)
                    if dd.max() <= eps:
                        break
                    cc = cc + 0.1 * U[trial[int(dd.argmax())]]
                    cc /= np.linalg.norm(cc)
                if angular(U[trial], cc).max() <= eps:
                    members, c, grown = trial, cc, True
                    break
            if not grown:
                break
        uncovered[angular(U, c) <= eps] = False
        k += 1
    return k


sentences = load_sentences()
claims = load_claims()
rng = np.random.default_rng(5)
sets = {
    "claims": embed(sentences, claims),
    "sentences": embed(sentences, sentences),
}
# a baseline with no structure: as many random directions in the same 50 dimensions
for name in ("claims", "sentences"):
    G = rng.normal(size=sets[name].shape)
    sets[name + " (random directions, same number)"] = G / np.linalg.norm(G, axis=1)[:, None]

EPS = [0.5, 0.45, 0.4, 0.35, 0.3, 0.25, 0.2, 0.15, 0.1]
result = {}
fig, axes = plt.subplots(1, 2, figsize=(13, 4.8))
for name, U in sets.items():
    radii = greedy_radii(U)
    D = np.arccos(np.clip(U[:400] @ U[:400].T, -1, 1)) / math.pi
    iu = np.triu_indices(len(D), 1)
    small = len(U) <= 400
    rows = []
    for eps in EPS:
        lo, hi = bracket(radii, eps)
        anyc = cover_any_centre(U, eps, np.random.default_rng(0)) if small else None
        up = min(hi, anyc) if anyc is not None else hi
        rows.append({"tolerance": eps, "lower_bound": lo, "upper_bound_centres_among_texts": hi,
                     "upper_bound_centres_anywhere": anyc, "covering_number_between": [lo, up],
                     "least_budget_bits_between": [int(math.floor(math.log2(lo))), int(math.floor(math.log2(up)))]})
    result[name] = {"texts": int(len(U)), "bits_to_land_exactly": int(math.floor(math.log2(len(U)))),
                    "pairwise_distance_5pct_median_95pct": [round(float(q), 3) for q in np.quantile(D[iu], [0.05, 0.5, 0.95])],
                    "by_tolerance": rows}
    ax = axes[0] if name.startswith("claims") else axes[1]
    ls = "-" if "random" not in name else "--"
    ax.plot(EPS, [r["least_budget_bits_between"][1] for r in rows], ls, marker="o", ms=3, label=name + ": upper")
    ax.plot(EPS, [r["least_budget_bits_between"][0] for r in rows], ls, marker="x", ms=3, lw=0.8, label=name + ": lower")
    ax.set_xlabel("tolerance (angle / π)"); ax.set_ylabel("budget in bits, floor(log2 N)")
    ax.set_xlim(0.05, 0.55); ax.legend(fontsize=7)
axes[0].set_title(f"{result['claims']['texts']} claims of the book")
axes[1].set_title(f"{result['sentences']['texts']} sentences of the book")
fig.suptitle("Simulation 5: bits needed to land every text within a tolerance (lexical distance)")
fig.tight_layout(); fig.savefig(f"{OUT}/s5_covering.png", dpi=110)
save("s5_covering.json", result)
for name, r in result.items():
    print(name, r["texts"], "exact:", r["bits_to_land_exactly"], "bits; pairwise", r["pairwise_distance_5pct_median_95pct"])
    for row in r["by_tolerance"]:
        print("   ", row["tolerance"], row["lower_bound"], row["upper_bound_centres_among_texts"],
              row["upper_bound_centres_anywhere"], row["least_budget_bits_between"])
