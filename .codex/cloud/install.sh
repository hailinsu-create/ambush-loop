#!/usr/bin/env bash
set -euo pipefail

version="4.7.2"
root="${HOME}/.local/opt/godot-${version}"
bin_dir="${HOME}/.local/bin"
archive="${TMPDIR:-/tmp}/godot-${version}.zip"
url="https://github.com/godotengine/godot/releases/download/${version}-stable/Godot_v${version}-stable_linux.x86_64.zip"
# Published in https://github.com/godotengine/godot/releases/download/4.7.2-stable/SHA512-SUMS.txt.
archive_sha512="9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65"

mkdir -p "${root}" "${bin_dir}"
if [[ ! -x "${root}/godot" ]]; then
  curl --fail --location --retry 3 --output "${archive}" "${url}"
  if ! printf '%s  %s\n' "${archive_sha512}" "${archive}" | sha512sum --check --status; then
    printf 'Godot archive SHA-512 verification failed: %s\n' "${archive}" >&2
    rm -f -- "${archive}"
    exit 1
  fi
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
