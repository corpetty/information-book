"""Simulation 3. Trees and several routes: what redundancy buys against depth.

Not formalized in the library. Three computations.

(a) Broadcasting on a tree with branching d, every edge a fading hop on two ideas with a
    fair-coin fallback (a symmetric binary channel, second eigenvalue c). What the whole
    generation at depth n jointly retains about the root is estimated by sampling: the
    root is one of two originals, the tree is simulated, the exact posterior of the root
    given all the leaves is computed by belief propagation, and the advantage is
    2 * accuracy - 1. The literature gives the threshold d * c^2 = 1.

(b) The same tree when the fallback can never produce either original (a third idea,
    "something else", absorbs). Then one surviving copy proves which original was sent,
    and the advantage is the probability that a branching process survives: exact
    recursion, threshold d * c = 1.

(c) k independent chains of n fading hops reaching one receiver: exact advantage of the
    best test on the k outcomes, in the two cases above, against the bound proved for two
    routes (Noisy.two_routes_le: 1 - (1 - a)^2 when one route allows a).
"""
import math

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from model import *

rng = np.random.default_rng(3)


def broadcast_advantage(d, c, depth, trials):
    """Advantage of the Bayes test on generation `depth`, and of a majority vote."""
    eps = (1 - c) / 2
    P = np.array([[1 - eps, eps], [eps, 1 - eps]])
    root = rng.integers(0, 2, size=trials)
    level = root[:, None]
    for _ in range(depth):
        parents = np.repeat(level, d, axis=1)
        flip = rng.random(parents.shape) < eps
        level = np.where(flip, 1 - parents, parents)
    # majority vote (ties broken at random)
    ones = level.mean(axis=1)
    vote = np.where(ones == 0.5, rng.integers(0, 2, size=trials), (ones > 0.5).astype(int))
    acc_vote = (vote == root).mean()
    # exact posterior by belief propagation, in log space
    L = np.log(np.stack([level == 0, level == 1], axis=2) + 1e-300)
    for _ in range(depth):
        m = L.max(axis=2, keepdims=True)
        msg = np.log(np.exp(L - m) @ P.T) + m           # likelihood of subtree given parent
        L = msg.reshape(trials, -1, d, 2).sum(axis=2)
    guess = L[:, 0, :].argmax(axis=1)
    tie = L[:, 0, 0] == L[:, 0, 1]
    guess = np.where(tie, rng.integers(0, 2, size=trials), guess)
    acc = (guess == root).mean()
    return 2 * acc - 1, 2 * acc_vote - 1


# ---------- (a) symmetric: threshold d c^2 = 1
MAXDEPTH = {2: 12, 3: 8, 4: 6}
TRIALS = 6000
sym = []
fig, axes = plt.subplots(1, 4, figsize=(18, 4.6))
for ax, d in zip(axes[:3], (2, 3, 4)):
    cstar = 1 / math.sqrt(d)
    for c in (cstar - 0.15, cstar - 0.05, cstar, cstar + 0.05, cstar + 0.15):
        depths = list(range(1, MAXDEPTH[d] + 1))
        adv, vote = zip(*[broadcast_advantage(d, c, n, TRIALS) for n in depths])
        sym.append({"branching": d, "c": round(c, 3), "d_c_squared": round(d * c * c, 3),
                    "depths": depths, "advantage_bayes": [round(float(a), 3) for a in adv],
                    "advantage_majority": [round(float(a), 3) for a in vote],
                    "one_chain_c_to_n_at_max_depth": round(c ** depths[-1], 4)})
        ax.plot(depths, adv, marker="o", ms=3, label=f"c={c:.2f}, d·c²={d*c*c:.2f}")
    ax.set_title(f"branching {d}: fair-coin fallback")
    ax.set_xlabel("depth"); ax.set_ylim(-0.05, 1.05); ax.legend(fontsize=8)
axes[0].set_ylabel("advantage of the best test")

# ---------- (b) unforgeable original: threshold d c = 1
def survival(d, c, depth):
    s = 1.0
    for _ in range(depth):
        s = 1 - (1 - c * s) ** d
    return s

unf = []
for d in (2, 3, 4):
    for c in (0.9 / d, 1.0 / d, 1.1 / d, 1 / math.sqrt(d)):
        unf.append({"branching": d, "c": round(c, 3), "d_c": round(d * c, 3),
                    "advantage_at_depth_10_50_500": [round(survival(d, c, n), 4) for n in (10, 50, 500)]})
        if d == 2:
            axes[3].plot(range(0, 61), [survival(d, c, n) for n in range(0, 61)],
                         label=f"c={c:.2f}, d·c={d*c:.2f}")
axes[3].set_title("branching 2: fallback never gives the original")
axes[3].set_xlabel("depth"); axes[3].set_ylim(-0.05, 1.05); axes[3].legend(fontsize=8)
fig.suptitle("Simulation 3: what a whole generation of a tree retains about the root")
fig.tight_layout()
fig.savefig(f"{OUT}/s3_trees.png", dpi=110)

# ---------- (c) k routes to one receiver
def binom_pmf(k, p):
    return np.array([math.comb(k, j) * p ** j * (1 - p) ** (k - j) for j in range(k + 1)])

def routes_symmetric(k, a):
    return float(tv(binom_pmf(k, (1 + a) / 2), binom_pmf(k, (1 - a) / 2)))

def routes_unforgeable(k, a):
    return 1 - (1 - a) ** k

def routes_needed(fn, a, level=0.5, kmax=200000):
    lo, hi = 1, 1
    while fn(hi, a) < level:
        hi *= 2
        if hi > kmax:
            return None
    while lo < hi:
        mid = (lo + hi) // 2
        if fn(mid, a) >= level:
            hi = mid
        else:
            lo = mid + 1
    return lo

def routes_symmetric_fast(k, a):
    # normal approximation is not used: exact via log-pmf for large k
    from scipy.stats import binom
    j = np.arange(k + 1)
    return float(0.5 * np.abs(binom.pmf(j, k, (1 + a) / 2) - binom.pmf(j, k, (1 - a) / 2)).sum())

routes = []
c = 0.9
for n in (1, 5, 10, 20, 30, 40):
    a = c ** n
    routes.append({
        "c": c, "depth": n, "one_route": round(a, 4),
        "two_routes_symmetric": round(routes_symmetric(2, a), 4),
        "three_routes_symmetric": round(routes_symmetric(3, a), 4),
        "two_routes_unforgeable": round(routes_unforgeable(2, a), 4),
        "proved_bound_two_routes": round(1 - (1 - a) ** 2, 4),
        "routes_needed_for_half_symmetric": routes_needed(routes_symmetric_fast, a),
        "routes_needed_for_half_unforgeable": routes_needed(routes_unforgeable, a),
    })
save("s3_trees.json", {"symmetric_tree": sym, "unforgeable_tree": unf, "routes": routes})
for r in sym:
    print(r["branching"], r["c"], r["d_c_squared"], "bayes", r["advantage_bayes"][-1], "majority",
          r["advantage_majority"][-1], "one chain", r["one_chain_c_to_n_at_max_depth"])
for r in unf:
    print(r)
for r in routes:
    print(r)
