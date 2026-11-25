"""Simulation 2. Distance from the original against distinguishability of originals.

The library proves nothing that relates the two. Ideas sit on a line of 101 points with
the usual distance. For five kinds of reteller, starting from idea 30, the script tracks
 - the expected distance of the n-th version from the original,
 - the advantage of the best test between the original and another original 1, 10 and 40
   places away,
 - the resolution: the smallest separation r such that originals r apart can still be told
   apart with advantage at least one half.
"""
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from model import *

M, X0, PROTO, N = 101, 30, 70, 400
pos = np.arange(M)


def shift_towards(m, target):
    P = np.zeros((m, m))
    for i in range(m):
        P[i, i + (1 if target > i else -1 if target < i else 0)] = 1.0
    return P


point = np.zeros(M); point[PROTO] = 1.0
hops = {
    "fading to a uniform fallback (c=0.9)": fade(0.9, np.ones(M) / M),
    "fading to one prototype (c=0.9)": fade(0.9, point),
    "unbiased drift (stay 0.5)": drift_line(M, 0.5),
    "drift pulled to a prototype (stay 0.5, bias 0.7)": pull_line(M, 0.5, PROTO, 0.7),
    "function: one step towards the prototype": shift_towards(M, PROTO),
}

rows = []
fig, axes = plt.subplots(3, len(hops), figsize=(4.2 * len(hops), 9.5), sharex=True)
for j, (name, P) in enumerate(hops.items()):
    dist, adv1, adv10, adv40, res = [], [], [], [], []
    K = np.eye(M)
    for n in range(N + 1):
        dist.append(float(K[X0] @ np.abs(pos - X0)))
        adv1.append(float(tv(K[X0], K[X0 + 1])))
        adv10.append(float(tv(K[X0], K[X0 + 10])))
        adv40.append(float(tv(K[X0], K[X0 + 40])))
        r = next((s for s in range(1, M - X0) if tv(K[X0], K[X0 + s]) >= 0.5), None)
        res.append(r)
        K = K @ P
    rows.append({
        "reteller": name,
        "distance_at_hops_1_10_100_400": [round(dist[k], 2) for k in (1, 10, 100, 400)],
        "advantage_neighbour_at_1_10_100": [round(adv1[k], 3) for k in (1, 10, 100)],
        "advantage_10_apart_at_1_10_100": [round(adv10[k], 3) for k in (1, 10, 100)],
        "advantage_40_apart_at_1_10_100": [round(adv40[k], 3) for k in (1, 10, 100)],
        "resolution_at_1_10_100": [res[k] for k in (1, 10, 100)],
    })
    axes[0, j].plot(dist); axes[0, j].set_title(name, fontsize=9)
    axes[1, j].plot(adv1, label="1 apart"); axes[1, j].plot(adv10, label="10 apart")
    axes[1, j].plot(adv40, label="40 apart"); axes[1, j].set_ylim(-0.03, 1.03)
    axes[2, j].plot([r if r is not None else np.nan for r in res]); axes[2, j].set_xlabel("hops")
axes[0, 0].set_ylabel("expected distance from the original")
axes[1, 0].set_ylabel("advantage between two originals"); axes[1, 0].legend(fontsize=8)
axes[2, 0].set_ylabel("resolution (separation still told apart)")
fig.suptitle("Simulation 2: distance from the original against distinguishability")
fig.tight_layout()
fig.savefig(f"{OUT}/s2_distance.png", dpi=110)
save("s2_distance.json", rows)
for r in rows:
    print(r)
