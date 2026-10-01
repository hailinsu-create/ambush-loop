#!/usr/bin/env bash
set -euo pipefail
version="5.2.2"
bin_dir="${HOME}/.local/bin"
root="${HOME}/.local/opt/blender-${version}"
archive_name="blender-${version}-linux-x64.tar.xz"
base="https://download.blender.org/release/Blender5.2"
mkdir -p "${bin_dir}" "$(dirname "${root}")"
if [[ ! -x "${root}/blender" ]]; then
  task_tmp="$(mktemp -d)"
  trap 'rm -f -- "${task_tmp}/${archive_name}" "${task_tmp}/checksums" "${task_tmp}/selected.sha256"; rmdir -- "${task_tmp}"' EXIT
  curl --fail --location --retry 3 --output "${task_tmp}/${archive_name}" "${base}/${archive_name}"
  curl --fail --location --retry 3 --output "${task_tmp}/checksums" "${base}/blender-${version}.sha256"
  awk -v name="${archive_name}" '$2 == name || $2 == "*" name { print }' "${task_tmp}/checksums" > "${task_tmp}/selected.sha256"
  [[ -s "${task_tmp}/selected.sha256" ]]
  (cd "${task_tmp}" && sha256sum --check selected.sha256)
  mkdir -p "${root}"
  tar -xJf "${task_tmp}/${archive_name}" --strip-components=1 -C "${root}"
fi
ln -sfn "${root}/blender" "${bin_dir}/blender"
cat > "${bin_dir}/blender-headless" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
# EEVEE still creates an OpenGL context in background mode. A private X11
# display avoids the cloud EGL fallback; xvfb-run owns and cleans up Xvfb.
command -v xvfb-run >/dev/null || { printf 'xvfb-run required; install xvfb and xauth in environment setup.\n' >&2; exit 1; }
command -v xauth >/dev/null || { printf 'xauth required for the private Xvfb display.\n' >&2; exit 1; }
exec xvfb-run -a -s '-screen 0 1280x720x24 -nolisten tcp' \
  "$(dirname "$0")/blender" --background --factory-startup --gpu-backend opengl \
  --threads "${AMBUSH_BLENDER_THREADS:-2}" --python-exit-code 1 "$@"
WRAPPER
chmod +x "${bin_dir}/blender-headless"
export PATH="${bin_dir}:${PATH}"
blender --version | head -n 1 | grep -F "Blender ${version}"
command -v npm >/dev/null || { printf 'Node/npm required for glTF checks.\n' >&2; exit 1; }
npm install --prefix "${HOME}/.local/opt/ambush-gltf" --no-audit --no-fund @gltf-transform/cli@4.5.1
ln -sfn "${HOME}/.local/opt/ambush-gltf/node_modules/.bin/gltf-transform" "${bin_dir}/gltf-transform"
gltf-transform --version
printf 'Look tools installed; run an ArtSource generator to verify rendering on this environment.\n'
