#!/usr/bin/env bash
# Run this file and its sibling installers from the same pinned code package.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
if ! command -v Xvfb >/dev/null || ! command -v xauth >/dev/null; then
  apt-get update
  apt-get install -y coreutils curl unzip xz-utils python3 libx11-6 libxi6 libxxf86vm1 libxfixes3 libxrender1 libsm6 libgl1 libegl1 libxkbcommon0 xvfb xauth
fi
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${AMBUSH_REPO_DIR:-/workspace/ambush-loop}"
bash "${script_dir}/install.sh"
