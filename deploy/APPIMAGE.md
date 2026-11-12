# FWD_LM_GCS Linux AppImage

Single-file Linux build of the FWD Ground Control Station. Bundles Qt,
QML, GStreamer (+ plugins), SDL2, OpenSSL and the other third-party
libraries, so nothing has to be installed on the target machine.

## Requirements on the target machine

- Linux x86_64
- glibc 2.31 or newer (Ubuntu 20.04 / Debian 11 / Fedora 32 or newer)
- A working GPU/OpenGL driver (provided by the OS)
- `libfuse2` for direct execution. If the distribution only ships FUSE 3,
  use `--appimage-extract-and-run` or the `.tar.gz` fallback.

## Run

```bash
chmod +x FWD_LM_GCS-<version>-x86_64.AppImage
./FWD_LM_GCS-<version>-x86_64.AppImage
```

If FUSE is unavailable:

```bash
./FWD_LM_GCS-<version>-x86_64.AppImage --appimage-extract-and-run
```

Or use the portable tarball:

```bash
tar xzf FWD_LM_GCS-<version>-x86_64.tar.gz
./FWD_LM_GCS.AppDir/AppRun
```

## Build

A Release build is required (the Debug build is huge and only meant for
development):

```bash
mkdir -p build-release && cd build-release
/home/fwd/Qt/5.15.2/gcc_64/bin/qmake ../qgroundcontrol.pro \
    -spec linux-g++ CONFIG+=release CONFIG-=debug CONFIG-=qml_debug
make -j"$(nproc)"
cd ..

./deploy/create_fwd_appimage.sh . build-release/staging dist
```

Artifacts are written to `dist/`:

- `FWD_LM_GCS-<version>-x86_64.AppImage`
- `FWD_LM_GCS-<version>-x86_64.tar.gz`
- `FWD_LM_GCS-<version>.sha256`

## Validate

```bash
./deploy/validate_fwd_appimage.sh dist/FWD_LM_GCS-<version>-x86_64.AppImage
# also test in clean Ubuntu 20.04 / 22.04 containers:
./deploy/validate_fwd_appimage.sh dist/FWD_LM_GCS-<version>-x86_64.AppImage --docker
```

## Notes

- The bundle intentionally does **not** ship glibc, the GPU driver, X11,
  Wayland or D-Bus. Shipping those is what makes AppImages break on other
  machines.
- GStreamer plugins are loaded only from the bundle (deterministic video
  behaviour); a writable registry cache is created under
  `~/.cache/fwd_lm_gcs`.
- Old upstream `deploy/create_linux_appimage.sh` is left untouched; the
  FWD-specific packaging lives in `deploy/create_fwd_appimage.sh` and
  `deploy/bundle_fwd_deps.sh`.
