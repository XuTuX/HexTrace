#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
AAB_PATH="${REPO_ROOT}/build/app/outputs/bundle/release/app-release.aab"

if [[ "${1:-}" != "--internal-run" ]] && command -v caffeinate >/dev/null 2>&1; then
  exec caffeinate -dimsu "$0" --internal-run "$@"
fi

if [[ "${1:-}" == "--internal-run" ]]; then
  shift
fi

cd "${REPO_ROOT}"

if [[ ! -f ".env" ]]; then
  echo "Missing .env file in ${REPO_ROOT}" >&2
  exit 1
fi

if [[ ! -f "android/key.properties" ]]; then
  echo "Missing android/key.properties" >&2
  exit 1
fi

set -a
source ".env"
set +a

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env" >&2
  exit 1
fi

echo "Stopping Gradle daemons..."
./android/gradlew --stop >/dev/null 2>&1 || true

echo "Removing stale release bundle..."
rm -f "${AAB_PATH}"

echo "Building signed Android App Bundle..."
flutter clean
flutter build appbundle --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

if [[ ! -f "${AAB_PATH}" ]]; then
  echo "Build completed but ${AAB_PATH} was not created." >&2
  exit 1
fi

echo "Verifying bundle signature..."
jarsigner -verify -verbose -certs "${AAB_PATH}" >/dev/null

echo
echo "Build succeeded."
echo "AAB: ${AAB_PATH}"
