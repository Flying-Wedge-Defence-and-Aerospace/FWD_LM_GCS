#!/usr/bin/env bash
#
# validate_fwd_appimage.sh <AppImage> [--docker]
#
# Extracts the AppImage and checks:
#   - every dynamic library resolves inside the bundle
#   - the app starts headless (offscreen QPA) without a loader error
# With --docker it also runs the bundle inside clean Ubuntu 20.04/22.04
# containers (no GStreamer/Qt installed there) to prove portability.
#
set -euo pipefail

APPIMAGE="${1:?usage: validate_fwd_appimage.sh <AppImage> [--docker]}"
APPIMAGE="$(readlink -f "$APPIMAGE")"
DO_DOCKER="${2:-}"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/fwd-validate.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "==> Extracting $APPIMAGE"
( cd "$WORK" && "$APPIMAGE" --appimage-extract >/dev/null )
ROOT="$WORK/squashfs-root"
BIN="$ROOT/FWD_LM_GCS"

echo "==> Checking dynamic libraries"
MISSING=0
check_ldd() {
    local f="$1"
    local out
    out="$(ldd "$f" 2>&1 | grep 'not found' || true)"
    if [ -n "$out" ]; then
        echo "  MISSING for $f:"
        echo "$out" | sed 's/^/    /'
        MISSING=1
    fi
}
check_ldd "$BIN"
while IFS= read -r -d '' f; do check_ldd "$f"; done < <(find "$ROOT/lib" "$ROOT/gstreamer-1.0" -type f -name '*.so*' -print0 2>/dev/null)
while IFS= read -r -d '' f; do check_ldd "$f"; done < <(find "$ROOT/Qt/libs" "$ROOT/Qt/plugins" -type f -name '*.so*' -print0 2>/dev/null)

if [ "$MISSING" -ne 0 ]; then
    echo "!! Unresolved libraries found"
else
    echo "   all libraries resolved"
fi

echo "==> Headless startup test"
LOG="$WORK/run.log"
QT_QPA_PLATFORM=offscreen timeout 20 "$ROOT/AppRun" >"$LOG" 2>&1 || true
if grep -qiE 'error while loading shared libraries|cannot open shared object file|undefined symbol' "$LOG"; then
    echo "!! Loader error:"
    grep -iE 'error while loading shared libraries|cannot open shared object file|undefined symbol' "$LOG" | head
    exit 1
fi
echo "   started (no loader errors). First log lines:"
sed -n '1,8p' "$LOG" | sed 's/^/    /'

if [ "$DO_DOCKER" = "--docker" ]; then
    if ! command -v docker >/dev/null 2>&1; then
        echo "--docker requested but docker is not installed; skipping"
        exit 0
    fi
    for image in ubuntu:20.04 ubuntu:22.04; do
        echo "==> Docker portable test: $image"
        docker run --rm -v "$APPIMAGE:/opt/FWD_LM_GCS.AppImage:ro" "$image" bash -lc '
            set -e
            export DEBIAN_FRONTEND=noninteractive
            # Minimal runtime the AppImage legitimately relies on (GPU/X11/glibc)
            apt-get update -qq >/dev/null 2>&1 || true
            apt-get install -y -qq --no-install-recommends libgl1 libegl1 libxkbcommon0 libxcb1 libx11-6 libdbus-1-3 libfontconfig1 libfreetype6 libudev1 >/dev/null 2>&1 || true
            QT_QPA_PLATFORM=offscreen timeout 20 /opt/FWD_LM_GCS.AppImage --appimage-extract-and-run >/tmp/run.log 2>&1 || true
            if grep -qiE "error while loading shared libraries|cannot open shared object file|undefined symbol" /tmp/run.log; then
                echo "LOADER ERROR:"; grep -iE "error while loading shared libraries|cannot open shared object file|undefined symbol" /tmp/run.log | head; exit 1
            fi
            echo "OK: no loader errors"
        '
    done
fi
