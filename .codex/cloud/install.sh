#!/usr/bin/env bash
set -euo pipefail

version="4.7.2"
root="${HOME}/.local/opt/godot-${version}"
bin_dir="${HOME}/.local/bin"
archive="${TMPDIR:-/tmp}/godot-${version}.zip"
url="https://github.com/godotengine/godot/releases/download/${version}-stable/Godot_v${version}-stable_linux.x86_64.zip"

mkdir -p "${root}" "${bin_dir}"
if [[ ! -x "${root}/godot" ]]; then
  curl --fail --location --retry 3 --output "${archive}" "${url}"
  unzip -o "${archive}" -d "${root}"
  mv "${root}/Godot_v${version}-stable_linux.x86_64" "${root}/godot"
  chmod +x "${root}/godot"
fi

ln -sfn "${root}/godot" "${bin_dir}/godot"
"${bin_dir}/godot" --version | grep -F "${version}.stable"
if [[ -f "ambush_loop/project.godot" ]]; then
  "${bin_dir}/godot" --headless --editor --path ambush_loop --import
fi
printf 'Ambush Loop cloud toolchain ready: %s\n' "${bin_dir}/godot"
bash "$(dirname "${BASH_SOURCE[0]}")/install-look.sh"
