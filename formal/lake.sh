#!/usr/bin/env sh
# Run lake with the toolchain pinned in ./lean-toolchain.
# Uses a system-wide elan/lake if one is on PATH; otherwise falls back to an
# ephemeral `nix shell` that provides elan, with a project-local ELAN_HOME so
# nothing is written outside this directory.
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here" || exit 1
if command -v lake >/dev/null 2>&1; then
  exec lake "$@"
fi
export ELAN_HOME="$here/.elan"
exec nix shell nixpkgs#elan -c lake "$@"
