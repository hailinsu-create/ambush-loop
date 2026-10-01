#!/usr/bin/env bash
set -euo pipefail
export AMBUSH_TOOLS_DIR=/workspace/ambush-environment/tools
export AMBUSH_DOWNLOAD_CACHE=/workspace/ambush-environment/downloads
export AMBUSH_REPO_DIR=/workspace/ambush-loop
export XDG_CACHE_HOME="$AMBUSH_TOOLS_DIR/cache"
export XDG_DATA_HOME="$AMBUSH_TOOLS_DIR/data"
export XDG_CONFIG_HOME="$AMBUSH_TOOLS_DIR/config"
export npm_config_cache=/workspace/ambush-environment/cache/npm
export PATH="$AMBUSH_TOOLS_DIR/bin:/workspace/ambush-environment/xvfb/usr/bin:$PATH"
setup_sha=99e6b70e831e28d672a14ab61029a71d1f9f982e
mkdir -p /workspace/ambush-environment
if ! git -C "$AMBUSH_REPO_DIR" cat-file -e "$setup_sha^{commit}" 2>/dev/null; then
  git -C "$AMBUSH_REPO_DIR" fetch --depth=1 https://github.com/hailinsu-create/ambush-loop.git "$setup_sha"
fi
test "$(git -C "$AMBUSH_REPO_DIR" rev-parse "$setup_sha^{commit}")" = "$setup_sha"
setup_package="$(mktemp -d /workspace/ambush-environment/bootstrap.XXXXXX)"
trap 'rm -rf -- "$setup_package"' EXIT
git -C "$AMBUSH_REPO_DIR" archive "$setup_sha" .codex/cloud | tar -x -C "$setup_package"
bash "$setup_package/.codex/cloud/environment-setup.sh"
