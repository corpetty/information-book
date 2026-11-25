"""Simulation 1. How loose is the product law?

Theorem (Noisy.advantage_le_of_contracts): the advantage after n hops is at most the
product of the one-hop constants. For one hop P repeated, that is dobrushin(P) ** n.
Here the true advantage after n hops, dobrushin(P ** n), is computed exactly and compared
with the bound and with the asymptotic rate |second eigenvalue| ** n.
"""
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from model import *

rng = np.random.default_rng(1)
N = 200
hops = {
    "fading, c=0.9, 20 ideas": fade(0.9, np.ones(20) / 20),
    "lazy cycle, 3 ideas, stay 0.9": lazy_cycle(3, 0.9),
    "lazy cycle, 10 ideas, stay 0.9": lazy_cycle(10, 0.9),
    "lazy cycle, 50 ideas, stay 0.9": lazy_cycle(50, 0.9),
    "drift on a line, 50 ideas, stay 0.8": drift_line(50, 0.8),
    "random dense, 20 ideas": random_dense(20, rng),
    "random sparse (3 per row), 20 ideas": random_sparse(20, 3, rng),
    "half fading c=0.9, half drift": 0.5 * fade(0.9, np.ones(50) / 50) + 0.5 * drift_line(50, 0.8),
}


def first_below(seq, level):
    for n, v in enumerate(seq):
        if v < level:
            return n
    return None


rows = []
fig, axes = plt.subplots(2, 4, figsize=(17, 7.5), sharey=True)
for ax, (name, P) in zip(axes.ravel(), hops.items()):
    c = dobrushin(P)
    lam = second_eig(P)
    true = []
    K = np.eye(len(P))
    for n in range(N + 1):
        true.append(dobrushin(K))
        K = K @ P
    bound = [c ** n for n in range(N + 1)]
    rows.append({
        "hop": name,
        "one_hop_constant": round(float(c), 4),
        "second_eigenvalue": round(lam, 4),
        "hops_until_true_advantage_below_half": first_below(true, 0.5),
        "hops_until_bound_below_half": first_below(bound, 0.5),
        "hops_until_true_advantage_below_tenth": first_below(true, 0.1),
        "hops_until_bound_below_tenth": first_below(bound, 0.1),
        "true_advantage_at_10": round(float(true[10]), 4),
        "bound_at_10": round(float(bound[10]), 4),
        "max_ratio_true_over_bound_first_60": round(float(max(t / b for t, b in zip(true[:61], bound[:61]) if b > 0)), 2),
    })
    ax.semilogy(true, label="true advantage", lw=2)
    ax.semilogy(bound, "--", label="bound: (one-hop constant)^n")
    ax.semilogy([lam ** n for n in range(N + 1)], ":", label="|second eigenvalue|^n")
    ax.set_title(name, fontsize=10)
    ax.set_ylim(1e-4, 1.5)
    ax.set_xlim(0, N)
    ax.set_xlabel("hops")
axes[0, 0].set_ylabel("advantage (worst pair of originals)")
axes[1, 0].set_ylabel("advantage (worst pair of originals)")
axes[0, 0].legend(fontsize=8)
fig.suptitle("Simulation 1: true advantage after n hops against the proved bound")
fig.tight_layout()
fig.savefig(f"{OUT}/s1_tightness.png", dpi=110)
save("s1_tightness.json", rows)
for r in rows:
    print(r)
