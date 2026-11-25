"""Shared pieces for the simulations of the retelling model in ../Complexity/Noisy.lean.

A hop is a row-stochastic matrix P: P[x, z] is the probability that a reteller told x
passes on z. A chain of hops is the matrix product. The advantage of the best test between
two originals x and x' is the total variation distance between rows x and x' of the chain.
"""
import json
import os

import numpy as np

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT, exist_ok=True)


def save(name, obj):
    with open(os.path.join(OUT, name), "w") as f:
        json.dump(obj, f, indent=1)


def tv(p, q):
    """Total variation distance: the largest advantage of any test between p and q."""
    return 0.5 * np.abs(p - q).sum()


def pair_tv(K):
    """Matrix of total variation distances between all pairs of rows of K."""
    return 0.5 * np.abs(K[:, None, :] - K[None, :, :]).sum(axis=2)


def dobrushin(K):
    """Dobrushin's coefficient: the largest one-hop advantage over all pairs of inputs."""
    return pair_tv(K).max()


def second_eig(P):
    ev = np.sort(np.abs(np.linalg.eigvals(P)))[::-1]
    return float(ev[1])


def fade(c, nu):
    """Keep the idea with probability c, otherwise draw from nu."""
    m = len(nu)
    return c * np.eye(m) + (1 - c) * np.tile(np.asarray(nu, float), (m, 1))


def lazy_cycle(m, p):
    """Stay with probability p, otherwise step to the next idea round a cycle."""
    P = p * np.eye(m)
    for i in range(m):
        P[i, (i + 1) % m] += 1 - p
    return P


def drift_line(m, p):
    """Stay with probability p, otherwise step left or right on a line (reflecting ends)."""
    P = np.zeros((m, m))
    for i in range(m):
        P[i, i] += p
        P[i, max(i - 1, 0)] += (1 - p) / 2
        P[i, min(i + 1, m - 1)] += (1 - p) / 2
    return P


def pull_line(m, p, target, bias):
    """Stay with probability p; otherwise step one place, towards `target` with probability
    `bias` and away from it with probability 1 - bias (reflecting ends)."""
    P = np.zeros((m, m))
    for i in range(m):
        P[i, i] += p
        if i == target:
            P[i, max(i - 1, 0)] += (1 - p) / 2
            P[i, min(i + 1, m - 1)] += (1 - p) / 2
            continue
        step = 1 if target > i else -1
        P[i, i + step] += (1 - p) * bias
        P[i, min(max(i - step, 0), m - 1)] += (1 - p) * (1 - bias)
    return P


def random_dense(m, rng):
    return rng.dirichlet(np.ones(m), size=m)


def random_sparse(m, k, rng):
    P = np.zeros((m, m))
    for i in range(m):
        cols = rng.choice(m, size=k, replace=False)
        P[i, cols] = rng.dirichlet(np.ones(k))
    return P
