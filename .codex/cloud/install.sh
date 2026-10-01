#!/usr/bin/env bash
set -euo pipefail

version="4.7.2"
tools_dir="${AMBUSH_TOOLS_DIR:-${HOME}/.local}"
root="${tools_dir}/opt/godot-${version}"
bin_dir="${tools_dir}/bin"
cache_dir="${AMBUSH_DOWNLOAD_CACHE:-${tools_dir}/cache/downloads}"
archive="${cache_dir}/Godot_v${version}-stable_linux.x86_64.zip"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${tools_dir}/cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${tools_dir}/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${tools_dir}/config}"
url="https://github.com/godotengine/godot/releases/download/${version}-stable/Godot_v${version}-stable_linux.x86_64.zip"
# Published in https://github.com/godotengine/godot/releases/download/4.7.2-stable/SHA512-SUMS.txt.
archive_sha512="9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65"

mkdir -p "${root}" "${bin_dir}" "${cache_dir}" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
if [[ ! -x "${root}/godot" ]]; then
  if [[ ! -f "${archive}" ]]; then
    curl --fail --location --retry 3 --output "${archive}.part" "${url}"
    mv "${archive}.part" "${archive}"
  fi
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
bash "${script_dir}/install-look.sh"
