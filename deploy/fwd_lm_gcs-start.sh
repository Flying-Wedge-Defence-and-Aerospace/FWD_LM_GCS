#!/bin/sh
#
# AppRun / launcher for the FWD_LM_GCS AppImage and staged deployment.
#
# Keeps the bundle self-contained: Qt lives in ./Qt, bundled third-party
# libraries (GStreamer/SDL2/...) in ./lib and GStreamer plugins in
# ./gstreamer-1.0.
#
HERE="$(dirname "$(readlink -f "${0}")")"

# Qt + bundled third-party shared libraries
LD_LIBRARY_PATH="${HERE}/Qt/libs:${HERE}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export LD_LIBRARY_PATH

# Bundled GStreamer plugins. Point both paths at the bundle so we do not pick
# up incompatible plugins from the host.
if [ -d "${HERE}/gstreamer-1.0" ]; then
    GST_PLUGIN_PATH="${HERE}/gstreamer-1.0"
    GST_PLUGIN_SYSTEM_PATH="${HERE}/gstreamer-1.0"
    export GST_PLUGIN_PATH GST_PLUGIN_SYSTEM_PATH
fi

# GStreamer needs a writable registry cache (AppImage mount is read-only).
GST_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/fwd_lm_gcs"
mkdir -p "${GST_CACHE_DIR}" 2>/dev/null || true
export GST_REGISTRY="${GST_CACHE_DIR}/gstreamer-registry.bin"

# Icon workaround for desktops that do not pick up the AppImage icon.
if [ -f "${HERE}/fwd_lm_gcs.png" ]; then
    mkdir -p "$HOME/.icons" 2>/dev/null && \
        cp -f "${HERE}/fwd_lm_gcs.png" "$HOME/.icons/" 2>/dev/null || true
fi

exec "${HERE}/FWD_LM_GCS" "$@"
