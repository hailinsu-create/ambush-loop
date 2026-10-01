#!/usr/bin/env bash
# Exact bootstrap configured for Ambush Loop Cloud on 2026-10-01.
# The public commit is pinned so a default-main checkout need not contain the installers.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y coreutils curl unzip xz-utils libx11-6 libxi6 libxxf86vm1 libxfixes3 libxrender1 libsm6 libgl1 libegl1 libxkbcommon0 xvfb
cd /workspace/ambush-loop
task_setup="$(mktemp -d)"
base="https://raw.githubusercontent.com/hailinsu-create/ambush-loop/5f6cdff8ae541b2eaf4e9d942dfe8af588740ca3/.codex/cloud"
curl --fail --location --retry 3 "${base}/install.sh" --output "${task_setup}/install.sh"
curl --fail --location --retry 3 "${base}/install-look.sh" --output "${task_setup}/install-look.sh"
bash "${task_setup}/install.sh"
