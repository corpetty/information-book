"""Simulation 4. Can the proposed experiments tell the models apart, and how big must they be?

(i)   A population of fixed retellers (a share c repeat faithfully, the rest always say
      their own thing, drawn from nu) against noisy retellers who each fade with the same
      c: the share of chains that end on the original, by depth. Theorem
      Noisy.fade_eq_mixture says the two are the same hop; this checks the simulation and
      shows what the curve is.
(ii)  Rerunning the same chain of people on the same original. With a share rho of fixed
      people and the rest noisy, how often do two reruns end the same?
(iii) Sizes. Chains needed to see the excess over chance of a two-way line-up at depth n;
      and the power of the book's "caveat loss per hop" pilot (content/experiments/
      caveat-loss-per-hop.md: about 30 finding-chains) to separate claim retention from
      caveat retention, and constant per-hop loss from loss concentrated at the first hop.
"""
import math

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from model import *

rng = np.random.default_rng(4)
M_IDEAS, C, DEPTH = 10, 0.8, 12
nu = np.ones(M_IDEAS) / M_IDEAS
X = 0


def run_chains(n_chains, depth, rho, reruns=1):
    """Each hop of each chain is a person. With probability rho the person is fixed: they
    are a faithful repeater (prob C) or a constant (drawn from nu) once and for all. With
    probability 1 - rho they are noisy: each time they repeat faithfully with prob C and
    otherwise draw afresh. Returns outcomes[rerun, chain, depth]."""
    fixed = rng.random((n_chains, depth)) < rho
    faithful = rng.random((n_chains, depth)) < C          # the fixed people's type
    const = rng.choice(M_IDEAS, size=(n_chains, depth), p=nu)
    out = np.zeros((reruns, n_chains, depth + 1), dtype=int)
    for r in range(reruns):
        cur = np.full(n_chains, X)
        out[r, :, 0] = cur
        for h in range(depth):
            keep_now = rng.random(n_chains) < C
            draw_now = rng.choice(M_IDEAS, size=n_chains, p=nu)
            noisy_next = np.where(keep_now, cur, draw_now)
            fixed_next = np.where(faithful[:, h], cur, const[:, h])
            cur = np.where(fixed[:, h], fixed_next, noisy_next)
            out[r, :, h + 1] = cur
    return out


# ---------- (i)
N = 40000
share_fixed = (run_chains(N, DEPTH, 1.0)[0] == X).mean(axis=0)
share_noisy = (run_chains(N, DEPTH, 0.0)[0] == X).mean(axis=0)
theory = [C ** n + (1 - C ** n) * nu[X] for n in range(DEPTH + 1)]
part_i = {"depths": list(range(DEPTH + 1)),
          "share_ending_on_original_fixed_people": [round(float(v), 4) for v in share_fixed],
          "share_ending_on_original_noisy_people": [round(float(v), 4) for v in share_noisy],
          "theory_c^n+(1-c^n)nu": [round(v, 4) for v in theory],
          "largest_gap_between_the_two_populations": round(float(np.abs(share_fixed - share_noisy).max()), 4)}

# ---------- (ii)
part_ii = []
for rho in (0.0, 0.25, 0.5, 0.75, 1.0):
    out = run_chains(20000, 6, rho, reruns=2)
    agree = (out[0, :, 6] == out[1, :, 6]).mean()
    part_ii.append({"share_of_fixed_people": rho, "two_reruns_end_the_same_at_depth_6": round(float(agree), 4)})

# ---------- (iii) sizes
def n_for_excess(a, alpha=0.05, power=0.8):
    """Smallest number of chains for which an exact one-sided binomial test of 'share right
    in a two-way line-up > 1/2' at level alpha has the given power when the true share is
    (1 + a) / 2."""
    from scipy.stats import binom
    p = (1 + a) / 2
    n = 1
    while True:
        k = int(binom.isf(alpha, n, 0.5)) + 1          # reject when at least k are right
        while k > 0 and binom.sf(k - 2, n, 0.5) <= alpha:
            k -= 1
        if binom.sf(k - 1, n, p) >= power:
            return n
        n += 1

sizes = [{"c": c, "depth": n, "advantage": round(c ** n, 4),
          "share_right_in_two_way_line_up": round((1 + c ** n) / 2, 4),
          "chains_needed_to_detect_it": n_for_excess(c ** n)}
         for c in (0.9, 0.7) for n in (1, 3, 6, 10)]


def pilot_power(n_findings, caveats_per_finding, hops, r_claim, r_caveat, first_hop_caveat=None,
                sims=4000):
    """Per-unit survival is followed hop by hop: a unit present at hop h-1 is present at hop
    h with probability r. Tests: (a) caveats are retained less than claims (two-proportion
    z-test on per-hop transitions, pooled over hops; one-sided at 2.5%); (b) caveat
    retention differs between the first hop and later hops (two-sided at 5%)."""
    from scipy.stats import norm
    z_crit = norm.ppf(0.975)
    hit_a = hit_b = 0
    for _ in range(sims):
        # claims: one per finding
        alive = np.ones(n_findings, bool); kc = nc = 0
        for h in range(hops):
            nc += alive.sum(); alive &= rng.random(n_findings) < r_claim; kc += alive.sum()
        alive = np.ones(n_findings * caveats_per_finding, bool)
        k_first = n_first = k_late = n_late = 0
        for h in range(hops):
            r = first_hop_caveat if (h == 0 and first_hop_caveat is not None) else r_caveat
            n_at = alive.sum(); alive &= rng.random(alive.size) < r; k_at = alive.sum()
            if h == 0: n_first, k_first = n_at, k_at
            else: n_late += n_at; k_late += k_at
        kv, nv = k_first + k_late, n_first + n_late
        if nc and nv:
            p = (kc + kv) / (nc + nv)
            se = math.sqrt(max(p * (1 - p), 1e-12) * (1 / nc + 1 / nv))
            hit_a += (kc / nc - kv / nv) / se > z_crit
        if n_first and n_late:
            p = (k_first + k_late) / (n_first + n_late)
            se = math.sqrt(max(p * (1 - p), 1e-12) * (1 / n_first + 1 / n_late))
            hit_b += abs(k_first / n_first - k_late / n_late) / se > z_crit
    return hit_a / sims, hit_b / sims

pilot = []
for n_findings in (10, 30, 100):
    for hops in (2, 3):
        for r_cav in (0.8, 0.7, 0.6):
            pa, _ = pilot_power(n_findings, 3, hops, 0.9, r_cav)
            pilot.append({"finding_chains": n_findings, "hops": hops, "claim_retention": 0.9,
                          "caveat_retention": r_cav, "power_to_see_caveats_lost_faster": round(pa, 3)})
front = []
for n_findings in (30, 100, 300):
    _, pb = pilot_power(n_findings, 3, 3, 0.9, 0.85, first_hop_caveat=0.6)
    _, p0 = pilot_power(n_findings, 3, 3, 0.9, 0.75)
    front.append({"finding_chains": n_findings, "hops": 3,
                  "caveat_retention_first_hop_0.6_then_0.85__power_to_see_front_loading": round(pb, 3),
                  "constant_0.75__false_alarm_rate": round(p0, 3)})

save("s4_design.json", {"populations": part_i, "reruns": part_ii, "sizes": sizes,
                        "pilot_power": pilot, "front_loading": front})

fig, axes = plt.subplots(1, 3, figsize=(16, 4.6))
axes[0].plot(share_fixed, "o-", label="fixed people, met at random")
axes[0].plot(share_noisy, "x--", label="noisy people")
axes[0].plot(theory, ":", label="c^n + (1 - c^n)·ν(x)")
axes[0].axhline(nu[X], color="grey", lw=0.5)
axes[0].set_title("share of chains ending on the original"); axes[0].set_xlabel("depth"); axes[0].legend()
axes[1].plot([r["share_of_fixed_people"] for r in part_ii],
             [r["two_reruns_end_the_same_at_depth_6"] for r in part_ii], "o-")
axes[1].set_title("same people, same original, rerun: agreement at depth 6")
axes[1].set_xlabel("share of retellers who are fixed functions"); axes[1].set_ylim(0, 1.03)
for hops, style in ((2, "o-"), (3, "s--")):
    for r_cav in (0.8, 0.7, 0.6):
        xs = [p["finding_chains"] for p in pilot if p["hops"] == hops and p["caveat_retention"] == r_cav]
        ys = [p["power_to_see_caveats_lost_faster"] for p in pilot if p["hops"] == hops and p["caveat_retention"] == r_cav]
        axes[2].plot(xs, ys, style, label=f"{hops} hops, caveats {r_cav} vs claims 0.9")
axes[2].set_xscale("log"); axes[2].set_title("power of the caveat-loss pilot"); axes[2].set_xlabel("finding-chains")
axes[2].axhline(0.8, color="grey", lw=0.5); axes[2].legend(fontsize=7)
fig.suptitle("Simulation 4: what the proposed experiments can and cannot separate")
fig.tight_layout(); fig.savefig(f"{OUT}/s4_design.png", dpi=110)
print(part_i["largest_gap_between_the_two_populations"], part_i["share_ending_on_original_fixed_people"][:7])
for r in part_ii: print(r)
for r in sizes: print(r)
for r in pilot: print(r)
for r in front: print(r)
