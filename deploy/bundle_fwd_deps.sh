#!/usr/bin/env bash
#
# bundle_fwd_deps.sh <AppDir>
#
# Makes the FWD_LM_GCS AppDir self-contained by copying GStreamer, SDL2 and
# the other third-party libraries that are not guaranteed to exist on every
# Linux desktop into <AppDir>/lib, plus a curated set of GStreamer plugins
# into <AppDir>/gstreamer-1.0.
#
# Core runtime / GPU-driver / X11 / Wayland / D-Bus libraries are deliberately
# left to the host (bundling those is what breaks AppImages).
#
set -euo pipefail

APPDIR="${1:?usage: bundle_fwd_deps.sh <AppDir>}"
APPDIR="$(readlink -f "$APPDIR")"
APPBIN="$APPDIR/FWD_LM_GCS"
LIBDIR="$APPDIR/lib"
GSTDIR="$APPDIR/gstreamer-1.0"
GST_PLUGIN_SRC="/usr/lib/x86_64-linux-gnu/gstreamer-1.0"

[ -f "$APPBIN" ] || { echo "ERROR: $APPBIN not found" >&2; exit 1; }

mkdir -p "$LIBDIR" "$GSTDIR"

# Libraries that must always come from the host system.
EXCLUDE_RE='^(ld-linux.*|libc\.so.*|libm\.so.*|libdl\.so.*|libpthread\.so.*|librt\.so.*|libresolv\.so.*|libnsl\.so.*|libutil\.so.*|libanl\.so.*|libthread_db\.so.*|libGL\.so.*|libGLX\.so.*|libGLdispatch\.so.*|libOpenGL\.so.*|libEGL\.so.*|libGLESv[0-9]*\.so.*|libglapi\.so.*|libdrm\.so.*|libgbm\.so.*|libX11.*\.so.*|libXau\.so.*|libXdmcp\.so.*|libXext\.so.*|libXrender\.so.*|libXfixes\.so.*|libXi\.so.*|libXrandr\.so.*|libXcursor\.so.*|libXinerama\.so.*|libXss\.so.*|libXxf86vm\.so.*|libXv\.so.*|libXvMC\.so.*|libxcb.*\.so.*|libwayland.*\.so.*|libxkbcommon.*\.so.*|libdbus-1\.so.*|libsystemd\.so.*|libudev\.so.*|libapparmor\.so.*|libselinux\.so.*|libmount\.so.*|libblkid\.so.*|libcap\.so.*|libfontconfig\.so.*|libfreetype\.so.*|libharfbuzz\.so.*|libpng.*\.so.*|libjpeg.*\.so.*|libtiff.*\.so.*|libwebp.*\.so.*|libpango.*\.so.*|libcairo.*\.so.*|libgdk.*\.so.*|libgtk.*\.so.*|libpixman.*\.so.*|libatk.*\.so.*|libXcomposite.*\.so.*|libXdamage.*\.so.*)$'

declare -A SEEN=()
QUEUE=()

resolve_soname() {
    local name="$1" path=""
    path="$(ldconfig -p 2>/dev/null | awk -v n="$name" '$1==n {print $NF; exit}')"
    if [ -z "$path" ]; then
        local d
        for d in /lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu /lib /usr/lib /usr/local/lib; do
            if [ -e "$d/$name" ]; then
                path="$d/$name"
                break
            fi
        done
    fi
    [ -n "$path" ] && printf '%s\n' "$path"
}

enqueue_path() {
    local p="${1:-}"
    if [ -n "$p" ] && [ -e "$p" ]; then
        QUEUE+=("$p")
    fi
    return 0
}

enqueue_soname() {
    local p
    p="$(resolve_soname "$1" || true)"
    if [ -n "$p" ]; then
        QUEUE+=("$p")
    fi
    return 0
}

enqueue_ldd_deps() {
    local file="$1" dep
    while IFS= read -r dep; do
        enqueue_path "$dep"
    done < <(ldd "$file" 2>/dev/null | awk '/not found/ {next} /=>/ {print $3} /^\// {print $1}')
}

# ---- seed: everything the application itself needs -------------------------
enqueue_ldd_deps "$APPBIN"

# OpenSSL is dlopen()ed by Qt Network, so it does not show up in ldd.
enqueue_soname libssl.so.1.1
enqueue_soname libcrypto.so.1.1
enqueue_soname libssl.so.3
enqueue_soname libcrypto.so.3

# GStreamer base libraries (used by the bundled plugins even when not NEEDED
# by the main binary).
for soname in \
    libgstreamer-1.0.so.0 \
    libgstbase-1.0.so.0 \
    libgstvideo-1.0.so.0 \
    libgstaudio-1.0.so.0 \
    libgstapp-1.0.so.0 \
    libgstpbutils-1.0.so.0 \
    libgsttag-1.0.so.0 \
    libgstriff-1.0.so.0 \
    libgstfft-1.0.so.0 \
    libgstnet-1.0.so.0 \
    libgstallocators-1.0.so.0 \
    libgstgl-1.0.so.0 \
    libgstrtp-1.0.so.0 \
    libgstrtsp-1.0.so.0 \
    libgstsdp-1.0.so.0 \
    libgstcheck-1.0.so.0 \
    liborc-0.4.so.0 \
    libglib-2.0.so.0 \
    libgobject-2.0.so.0 \
    libgmodule-2.0.so.0 \
    libgthread-2.0.so.0 \
    libgio-2.0.so.0 \
    libffi.so.7 \
    libpcre.so.3 \
    libSDL2-2.0.so.0 \
    libasound.so.2 \
    libpulse.so.0 \
    libpulse-mainloop-glib.so.0 ; do
    enqueue_soname "$soname"
done

# ---- GStreamer plugins (video/audio/network/decode) ------------------------
GST_PLUGINS=(
    libgstcoreelements.so
    libgstplayback.so
    libgsttypefindfunctions.so
    libgstapp.so
    libgstpbtypes.so
    libgstvideoconvert.so
    libgstvideoscale.so
    libgstvideoparsersbad.so
    libgstautodetect.so
    libgstautoconvert.so
    libgstdeinterlace.so
    libgstinterlace.so
    libgstlibav.so
    libgstisomp4.so
    libgstmatroska.so
    libgstavi.so
    libgstflv.so
    libgstmpegtsdemux.so
    libgstmpegpsdemux.so
    libgstrawparse.so
    libgstlegacyrawparse.so
    libgstjpeg.so
    libgstpng.so
    libgstopengl.so
    libgstvideotestsrc.so
    libgstspeed.so
    libgstsubparse.so
    libgstclosedcaption.so
    libgstaudioconvert.so
    libgstaudioresample.so
    libgstaudioparsers.so
    libgstaudiorate.so
    libgstaudiomixer.so
    libgstaudiofx.so
    libgstalsa.so
    libgstpulseaudio.so
    libgstossaudio.so
    libgstrtp.so
    libgstrtpmanager.so
    libgstrtsp.so
    libgstnrtp.so
    libgstudp.so
    libgsttcp.so
    libgstsoup.so
    libgstcurl.so
    libgstsdpelem.so
)

for plugin in "${GST_PLUGINS[@]}"; do
    src="$GST_PLUGIN_SRC/$plugin"
    [ -f "$src" ] || continue
    cp -f "$src" "$GSTDIR/$plugin"
    patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib:$ORIGIN/../Qt/libs' "$GSTDIR/$plugin" 2>/dev/null || true
    enqueue_ldd_deps "$src"
done

# ---- resolve the work list -------------------------------------------------
i=0
while [ "$i" -lt "${#QUEUE[@]}" ]; do
    src="${QUEUE[$i]}"
    i=$((i + 1))

    base="$(basename "$src")"
    [ -n "$base" ] || continue
    if [[ "$base" =~ $EXCLUDE_RE ]]; then
        continue
    fi
    [ -n "${SEEN[$base]:-}" ] && continue
    SEEN[$base]=1

    real="$(readlink -f "$src")"
    [ -f "$real" ] || continue

    # Libraries that already live inside the AppDir (Qt/..., or ones we just
    # copied) must not be copied again into lib/. Still follow their
    # dependencies so nothing they need is missed.
    if [[ "$real" == "$APPDIR"/* ]]; then
        enqueue_ldd_deps "$real"
        continue
    fi

    cp -fL "$real" "$LIBDIR/$base"
    patchelf --set-rpath '$ORIGIN' "$LIBDIR/$base" 2>/dev/null || true
    enqueue_ldd_deps "$real"
done

# ---- fix rpaths ------------------------------------------------------------
# Main binary: bundled Qt libs first, then bundled third-party libs.
patchelf --set-rpath '$ORIGIN/Qt/libs:$ORIGIN/lib' "$APPBIN" 2>/dev/null || true

# Qt libraries: they only ever need each other.
if [ -d "$APPDIR/Qt/libs" ]; then
    find "$APPDIR/Qt/libs" -maxdepth 1 -type f -name '*.so*' -print0 2>/dev/null |
        while IFS= read -r -d '' f; do
            patchelf --set-rpath '$ORIGIN' "$f" 2>/dev/null || true
        done
fi

# Qt plugins (platform/sqml/imageformats/...) need ../../libs.
if [ -d "$APPDIR/Qt/plugins" ]; then
    find "$APPDIR/Qt/plugins" -type f -name '*.so' -print0 2>/dev/null |
        while IFS= read -r -d '' f; do
            patchelf --set-rpath '$ORIGIN/../../libs' "$f" 2>/dev/null || true
        done
fi

# Report anything still unresolved.
echo "--- unresolved dynamic libraries (should only be host runtime/GPU libs) ---"
set +e
ldd "$APPBIN" 2>/dev/null | grep "not found"
for f in "$LIBDIR"/*.so* "$GSTDIR"/*.so; do
    [ -e "$f" ] || continue
    ldd "$f" 2>/dev/null | grep "not found" && echo "   (in $f)"
done
set -e

echo "Bundled $(find "$LIBDIR" -maxdepth 1 -type f | wc -l) libraries and $(find "$GSTDIR" -maxdepth 1 -type f | wc -l) GStreamer plugins."
