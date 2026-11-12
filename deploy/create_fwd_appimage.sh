#!/usr/bin/env bash
#
# create_fwd_appimage.sh <SRC_DIR> <RELEASE_DIR> [OUTPUT_DIR]
#
# Builds a single-file AppImage (plus a FUSE-free .tar.gz fallback) for
# FWD_LM_GCS, bundling Qt, GStreamer and the other non-guaranteed libraries.
#
#   SRC_DIR      : repository root (contains qgroundcontrol.pro)
#   RELEASE_DIR  : staged release tree (the build's `staging` directory)
#   OUTPUT_DIR   : where the artifacts are written (default: $PWD)
#
# Environment overrides:
#   FWD_VERSION  : version string used in the artifact names
#   KEEP_APPDIR=1: keep the intermediate AppDir for inspection
#
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <SRC_DIR> <RELEASE_DIR> [OUTPUT_DIR]" >&2
    exit 1
fi

SRC="$(readlink -f "$1")"
RELEASE="$(readlink -f "$2")"
OUTPUT="${3:-$PWD}"
OUTPUT="$(readlink -f "$OUTPUT")"

APPNAME="FWD_LM_GCS"
APPBIN="$RELEASE/$APPNAME"

if [ ! -f "$SRC/qgroundcontrol.pro" ]; then
    echo "ERROR: no qgroundcontrol.pro in $SRC" >&2
    exit 1
fi
if [ ! -f "$APPBIN" ]; then
    echo "ERROR: no $APPNAME binary in $RELEASE" >&2
    exit 1
fi

mkdir -p "$OUTPUT"

# ---------------------------------------------------------------- version ---
VERSION="${FWD_VERSION:-}"
if [ -z "$VERSION" ]; then
    VERSION="$(strings "$APPBIN" 2>/dev/null | grep -m1 -oE 'V?[0-9]+\.[0-9]+\.[0-9]+' | tr -d 'vV' || true)"
fi
[ -n "$VERSION" ] || VERSION="4.4.4"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/fwd-appimage.XXXXXX")"
APPDIR="$WORK/$APPNAME.AppDir"
mkdir -p "$APPDIR"
cleanup() {
    if [ "${KEEP_APPDIR:-0}" = "1" ]; then
        echo "AppDir kept at: $APPDIR"
    else
        rm -rf "$WORK"
    fi
}
trap cleanup EXIT

echo "==> Building AppDir from $RELEASE"
rsync -a --exclude 'package/' --exclude '*.o' --exclude '*.cpp' --exclude '*.h' "$RELEASE"/ "$APPDIR"/

# Drop the upstream QGroundControl launcher/desktop/icon if present.
rm -f "$APPDIR/qgroundcontrol-start.sh" \
      "$APPDIR/qgroundcontrol.desktop" \
      "$APPDIR/qgroundcontrol.png"

# AppRun / desktop / icon
cp "$SRC/deploy/fwd_lm_gcs-start.sh" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"
cp "$SRC/deploy/fwd_lm_gcs.desktop" "$APPDIR/$APPNAME.desktop"
cp "$SRC/resources/icons/fwd_lm_gcs.png" "$APPDIR/fwd_lm_gcs.png"
cp "$SRC/resources/icons/fwd_lm_gcs.png" "$APPDIR/.DirIcon"

# --------------------------------------------------------------- bundling ---
echo "==> Bundling GStreamer + third-party libraries"
"$SRC/deploy/bundle_fwd_deps.sh" "$APPDIR"

# --------------------------------------------------------------- stripping --
echo "==> Stripping debug symbols"
strip --strip-unneeded "$APPDIR/$APPNAME" 2>/dev/null || true
find "$APPDIR/lib" -maxdepth 1 -type f -name '*.so*' -print0 2>/dev/null |
    xargs -0 -r strip --strip-unneeded 2>/dev/null || true
find "$APPDIR/gstreamer-1.0" -maxdepth 1 -type f -name '*.so' -print0 2>/dev/null |
    xargs -0 -r strip --strip-unneeded 2>/dev/null || true

# ------------------------------------------------------------- appimagetool --
TOOL="${APPIMAGETOOL:-$HOME/.cache/fwd-appimage/appimagetool-x86_64.AppImage}"
if [ ! -x "$TOOL" ]; then
    echo "==> Downloading appimagetool"
    mkdir -p "$(dirname "$TOOL")"
    curl -fL --retry 3 -o "$TOOL" \
        "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$TOOL"
fi

APPIMAGE="$OUTPUT/$APPNAME-$VERSION-x86_64.AppImage"
echo "==> Generating AppImage: $APPIMAGE"
# appimagetool is itself an AppImage; force extraction so this works even on
# systems/CI without FUSE available to us.
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$TOOL" "$APPDIR" "$APPIMAGE"
chmod +x "$APPIMAGE"

# ------------------------------------------------------------- tar.gz ---------
TARGZ="$OUTPUT/$APPNAME-$VERSION-x86_64.tar.gz"
echo "==> Generating portable tarball: $TARGZ"
tar -C "$WORK" -czf "$TARGZ" "$APPNAME.AppDir"

# ------------------------------------------------------------- checksums -----
( cd "$OUTPUT" && sha256sum "$(basename "$APPIMAGE")" "$(basename "$TARGZ")" > "$APPNAME-$VERSION.sha256" )

echo
echo "==> Done"
ls -lh "$APPIMAGE" "$TARGZ" "$OUTPUT/$APPNAME-$VERSION.sha256"
