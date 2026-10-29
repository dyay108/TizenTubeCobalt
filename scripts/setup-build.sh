#!/usr/bin/env bash
#
# Set up and build the TizenTube Cobalt Android APK.
#
# This script creates a gclient workspace, fetches the Chromium/Cobalt
# dependencies, installs host build dependencies, and runs the Android build.
# See BUILDING.md for the manual instructions and troubleshooting.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

WORKSPACE="${WORKSPACE:-${HOME}/cobalt-build}"
if git -C "${REPO_ROOT}" rev-parse --git-dir >/dev/null 2>&1; then
  DEFAULT_REPO_URL="file://${REPO_ROOT}"
else
  DEFAULT_REPO_URL="https://github.com/dyay108/TizenTubeCobalt.git"
fi
REPO_URL="${REPO_URL:-${DEFAULT_REPO_URL}}"
PLATFORM="android-arm"
BUILD_TYPE="devel"
JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 8)"
REVISION=""
SKIP_SYNC=0
SKIP_BUILD=0

usage() {
  cat <<'EOF'
Usage: scripts/setup-build.sh [options]

Create a gclient workspace and build the TizenTube Cobalt Android APK.

Options:
  --workspace DIR     Workspace directory (default: $HOME/cobalt-build)
  --repo URL          Git URL to check out as src (default: this checkout)
  --revision REV      Git revision for the src solution, if syncing
  --platform PLATFORM Cobalt Android platform (default: android-arm)
  --build-type TYPE   debug, devel, qa, or gold (default: devel)
  --jobs N            Parallel build jobs (default: number of CPUs)
  --skip-sync         Reuse an existing workspace; do not run gclient sync
  --skip-build        Configure dependencies but do not run the native build
  -h, --help          Show this help

Examples:
  ./scripts/setup-build.sh
  ./scripts/setup-build.sh --workspace "$HOME/cobalt" --jobs 12
  ./scripts/setup-build.sh --repo "file://$PWD" --skip-build
  ./scripts/setup-build.sh --workspace "$HOME/cobalt" --skip-sync
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

log() {
  printf '\n==> %s\n' "$*"
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace)
      [[ $# -ge 2 ]] || die "--workspace requires a directory"
      WORKSPACE="$2"
      shift 2
      ;;
    --repo)
      [[ $# -ge 2 ]] || die "--repo requires a URL"
      REPO_URL="$2"
      shift 2
      ;;
    --revision)
      [[ $# -ge 2 ]] || die "--revision requires a value"
      REVISION="$2"
      shift 2
      ;;
    --platform)
      [[ $# -ge 2 ]] || die "--platform requires a value"
      PLATFORM="$2"
      shift 2
      ;;
    --build-type)
      [[ $# -ge 2 ]] || die "--build-type requires a value"
      BUILD_TYPE="$2"
      shift 2
      ;;
    --jobs)
      [[ $# -ge 2 ]] || die "--jobs requires a number"
      JOBS="$2"
      shift 2
      ;;
    --skip-sync)
      SKIP_SYNC=1
      shift
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1 (use --help)"
      ;;
  esac
done

case "${BUILD_TYPE}" in
  debug|devel|qa|gold) ;;
  *) die "invalid --build-type: ${BUILD_TYPE}" ;;
esac

[[ "${JOBS}" =~ ^[1-9][0-9]*$ ]] || die "--jobs must be a positive integer"
[[ "${PLATFORM}" =~ ^[a-z0-9-]+$ ]] || die "invalid --platform: ${PLATFORM}"

need_command git
need_command python3

mkdir -p "${WORKSPACE}"
WORKSPACE="$(cd -- "${WORKSPACE}" && pwd)"

DEPOT_TOOLS="${DEPOT_TOOLS:-${WORKSPACE}/tools/depot_tools}"
export DEPOT_TOOLS_UPDATE=0
export PATH="${DEPOT_TOOLS}:${PATH}"

if [[ ! -x "${DEPOT_TOOLS}/gclient" ]]; then
  log "Installing depot_tools in ${DEPOT_TOOLS}"
  mkdir -p "$(dirname -- "${DEPOT_TOOLS}")"
  git clone --depth 1 \
    https://chromium.googlesource.com/chromium/tools/depot_tools.git \
    "${DEPOT_TOOLS}"
fi

need_command gclient
need_command autoninja

cd "${WORKSPACE}"

if [[ ! -e src ]]; then
  :
elif [[ ! -d src/.git ]]; then
  die "${WORKSPACE}/src exists but is not a git checkout"
fi

if [[ ! -f .gclient ]]; then
  log "Creating .gclient for ${REPO_URL}"
  gclient config --name=src --managed "${REPO_URL}"
fi

if ! grep -qE '^[[:space:]]*target_os[[:space:]]*=' .gclient; then
  log "Adding Android target to .gclient"
  printf '\ntarget_os = ["linux", "android"]\n' >> .gclient
fi

if [[ "${SKIP_SYNC}" -eq 0 ]]; then
  log "Fetching dependencies with gclient sync"
  sync_args=(sync --no-history -j "${JOBS}")
  if [[ -n "${REVISION}" ]]; then
    sync_args+=(-r "src@${REVISION}")
  fi
  gclient "${sync_args[@]}"
else
  [[ -d src/.git ]] || die "--skip-sync requires ${WORKSPACE}/src"
fi

cd "${WORKSPACE}/src"

if [[ "${SKIP_SYNC}" -eq 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    if [[ "$(id -u)" -eq 0 ]]; then
      log "Installing sudo for install-build-deps.sh"
      apt-get update
      apt-get install -y sudo
    else
      die "sudo is required to install host build dependencies"
    fi
  fi

  if ! command -v lsb_release >/dev/null 2>&1; then
    log "Installing lsb-release"
    sudo apt-get update
    sudo apt-get install -y lsb-release
  fi

  log "Installing host build dependencies"
  ./build/install-build-deps.sh --no-prompt --no-arm --no-chromeos-fonts
  gclient runhooks
fi

KEYSTORE="${HOME}/.android/debug.keystore"
if [[ ! -f "${KEYSTORE}" ]]; then
  KEYTOOL="${WORKSPACE}/src/third_party/jdk/current/bin/keytool"
  [[ -x "${KEYTOOL}" ]] || die "keytool not found; run gclient sync first"
  log "Creating debug keystore at ${KEYSTORE}"
  mkdir -p "$(dirname -- "${KEYSTORE}")"
  "${KEYTOOL}" \
    -genkeypair -v \
    -keystore "${KEYSTORE}" \
    -storepass android \
    -alias androiddebugkey \
    -keypass android \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US"
fi

OUT_DIR="out/${PLATFORM}_${BUILD_TYPE}"
APK="${OUT_DIR}/apks/Cobalt.apk"

log "Configuring GN for ${PLATFORM} (${BUILD_TYPE})"
python3 cobalt/build/gn.py -p "${PLATFORM}" -c "${BUILD_TYPE}" --no-rbe

if [[ "${SKIP_BUILD}" -eq 1 ]]; then
  cat <<EOF

Setup complete. Build with:

  cd "${WORKSPACE}/src"
  export PATH="${DEPOT_TOOLS}:\$PATH"
  autoninja -C "${OUT_DIR}" -j"${JOBS}" cobalt_apk

APK will be at:

  ${WORKSPACE}/src/${APK}
EOF
  exit 0
fi

log "Building cobalt_apk"
autoninja -C "${OUT_DIR}" -j"${JOBS}" cobalt_apk

[[ -f "${APK}" ]] || die "build finished but ${APK} was not produced"

cat <<EOF

Build complete.

APK:

  ${WORKSPACE}/src/${APK}

Install on a connected Android device with:

  adb install -r "${WORKSPACE}/src/${APK}"

Set a fixed HTTP proxy (replace the host and port):

  adb shell settings put global http_proxy proxy.example.com:8080

Devel builds show the "Test HTTP proxy" button at the top-right of the app.
EOF
