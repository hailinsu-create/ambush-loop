#!/usr/bin/env bash
set -euo pipefail
version="5.2.2"
tools_dir="${AMBUSH_TOOLS_DIR:-${HOME}/.local}"
bin_dir="${tools_dir}/bin"
root="${tools_dir}/opt/blender-${version}"
cache_dir="${AMBUSH_DOWNLOAD_CACHE:-${tools_dir}/cache/downloads}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
archive_name="blender-${version}-linux-x64.tar.xz"
base="https://download.blender.org/release/Blender5.2"
archive_sha256="84098912789dc450e95697c4184fb8a90acbe5111c2ba4aede3fecb57806a168"
# Official Blender5.2/blender-5.2.2.sha256; verify cached archives too.
mkdir -p "${bin_dir}" "$(dirname "${root}")" "${cache_dir}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${tools_dir}/cache}"
export npm_config_cache="${npm_config_cache:-${tools_dir}/cache/npm}"
command -v python3 >/dev/null
command -v Xvfb >/dev/null || { printf 'Xvfb required during environment setup.\n' >&2; exit 1; }
command -v xauth >/dev/null || { printf 'xauth required during environment setup.\n' >&2; exit 1; }
if [[ ! -x "${root}/blender" ]]; then
  archive="${cache_dir}/${archive_name}"
  if [[ ! -f "${archive}" ]]; then
    curl --fail --location --retry 3 --output "${archive}.part" "${base}/${archive_name}"
    mv "${archive}.part" "${archive}"
  fi
  printf '%s  %s\n' "${archive_sha256}" "${archive}" | sha256sum --check
  task_tmp="$(mktemp -d "${tools_dir}/opt/.blender-install.XXXXXX")"
  trap 'rm -rf -- "${task_tmp}"' EXIT
  tar -xJf "${archive}" --strip-components=1 -C "${task_tmp}"
  mv "${task_tmp}" "${root}"
  trap - EXIT
fi
ln -sfn "${root}/blender" "${bin_dir}/blender"
install -m 755 "${script_dir}/blender-headless.py" "${bin_dir}/blender-headless"
export PATH="${bin_dir}:${PATH}"
blender --version | head -n 1 | grep -F "Blender ${version}"
command -v npm >/dev/null || { printf 'Node/npm required for glTF checks.\n' >&2; exit 1; }
gltf_bin="${tools_dir}/opt/ambush-gltf/node_modules/.bin/gltf-transform"
if [[ ! -x "${gltf_bin}" ]] || [[ "$("${gltf_bin}" --version)" != '4.5.1' ]]; then
  npm install --prefix "${tools_dir}/opt/ambush-gltf" --no-audit --no-fund @gltf-transform/cli@4.5.1
fi
ln -sfn "${tools_dir}/opt/ambush-gltf/node_modules/.bin/gltf-transform" "${bin_dir}/gltf-transform"
gltf-transform --version
printf 'Look tools installed; run an ArtSource generator to verify rendering on this environment.\n'
