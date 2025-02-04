#!/bin/bash

set -ex

# ppc64le cdt need to be rebuilt with files in powerpc64le-conda-linux-gnu instead of powerpc64le-conda_cos7-linux-gnu. In the meantime:
if [ "$(uname -m)" = "ppc64le" ]; then
  cp --force --archive --update --link $BUILD_PREFIX/powerpc64le-conda_cos7-linux-gnu/. $BUILD_PREFIX/powerpc64le-conda-linux-gnu
fi

# Cf. https://github.com/conda-forge/staged-recipes/issues/673, we're in the
# process of excising Libtool files from our packages. Existing ones can break
# the build while this happens.
find $PREFIX -name '*.la' -delete

# necessary to ensure the gobject-introspection-1.0 pkg-config file gets found
# meson needs this to determine where the g-ir-scanner script is located
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}:${PREFIX}/lib/pkgconfig:$BUILD_PREFIX/$BUILD/sysroot/usr/lib64/pkgconfig:$BUILD_PREFIX/$BUILD/sysroot/usr/share/pkgconfig

# Make sure .gir files in $PREFIX are found
export XDG_DATA_DIRS=${XDG_DATA_DIRS}:$PREFIX/share:$BUILD_PREFIX/share

if [ -n "$OSX_ARCH" ] ; then
    # The -dead_strip_dylibs option breaks g-ir-scanner here
    export LDFLAGS="$(echo $LDFLAGS |sed -e "s/-Wl,-dead_strip_dylibs//g")"
    export LDFLAGS_LD="$(echo $LDFLAGS_LD |sed -e "s/-dead_strip_dylibs//g")"
fi

declare -a meson_extra_opts

# conda-forge disables introspection when cross-compiling, but that isn't a
# concern for defaults.
meson_extra_opts=(-Dintrospection=enabled)

case "${target_platform}" in
    linux-*)
        # Needed for libxcb when using CDT X11 packages
        #export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${PREFIX}/lib"
        ;;
    osx-*)
        meson_extra_opts+=(-Dcoretext=auto)
        ;;
esac

# see https://github.com/harfbuzz/harfbuzz/blob/4.3.0/meson_options.txt
meson setup builddir \
    --buildtype=release \
    --default-library=both \
    --prefix="${PREFIX}" \
    --wrap-mode=nofallback \
    --libdir="${PREFIX}/lib" \
    --includedir=${PREFIX}/include \
    --pkg-config-path="${PKG_CONFIG_PATH}" \
    -Dbenchmark=disabled \
    -Dcairo=enabled \
    -Dchafa=disabled \
    -Ddirectwrite=disabled \
    -Ddocs=disabled \
    -Dfreetype=enabled \
    -Dgdi=disabled \
    -Dglib=enabled \
    -Dgobject=enabled \
    -Dgraphite=enabled \
    -Dgraphite2=enabled \
    -Dicu=enabled \
    -Dintrospection=enabled \
    -Dtests=enabled \
    "${meson_extra_opts[@]}"

ninja -v -C builddir -j ${CPU_COUNT}
# Debugging
# 2025-02-04T12:40:32.449927+00:00  | INFO     |     Tag        Type                         Name/Value
# 2025-02-04T12:40:32.451054+00:00  | INFO     |    0x0000000000000001 (NEEDED)             Shared library: [libharfbuzz.so.0]
# 2025-02-04T12:40:32.452195+00:00  | INFO     |    0x0000000000000001 (NEEDED)             Shared library: [libm.so.6]
# 2025-02-04T12:40:32.453341+00:00  | INFO     |    0x0000000000000001 (NEEDED)             Shared library: [libcairo.so.2]
# 2025-02-04T12:40:32.454479+00:00  | INFO     |    0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
# 2025-02-04T12:40:32.455615+00:00  | INFO     |    0x000000000000000e (SONAME)             Library soname: [libharfbuzz-cairo.so.0]
readelf -a $SRC_DIR/builddir/src/libharfbuzz.so
readelf -a $SRC_DIR/builddir/src/libcairo.so
readelf -a $SRC_DIR/builddir/src/libharfbuzz-cairo.so

ninja -v -C builddir test
ninja -C builddir install -j ${CPU_COUNT}

pushd "${PREFIX}"
  rm -rf share/gtk-doc
popd
