#!/bin/bash

set -ex


# Cf. https://github.com/conda-forge/staged-recipes/issues/673, we're in the
# process of excising Libtool files from our packages. Existing ones can break
# the build while this happens.
find $PREFIX -name '*.la' -delete

# necessary to ensure the gobject-introspection-1.0 pkg-config file gets found
# meson needs this to determine where the g-ir-scanner script is located
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}:${PREFIX}/lib/pkgconfig:$BUILD_PREFIX/$BUILD/sysroot/usr/lib64/pkgconfig:$BUILD_PREFIX/$BUILD/sysroot/usr/share/pkgconfig
declare -a meson_extra_opts

case "${target_platform}" in
    linux-*)
        # Needed for libxcb when using CDT X11 packages
        #export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${PREFIX}/lib"
        ;;
    osx-*)
        # The -dead_strip_dylibs option breaks g-ir-scanner here
        export LDFLAGS="$(echo $LDFLAGS |sed -e "s/-Wl,-dead_strip_dylibs//g")"
        export LDFLAGS_LD="$(echo $LDFLAGS_LD |sed -e "s/-dead_strip_dylibs//g")"

        meson_extra_opts+=(-Dcoretext=auto)
        ;;
esac

# see https://github.com/harfbuzz/harfbuzz/blob/4.3.0/meson_options.txt
meson setup builddir \
    ${MESON_ARGS} \
    "${meson_config_args[@]}" \
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
    -Dcoretext=auto \
    -Ddirectwrite=disabled \
    -Ddocs=disabled \
    -Dfreetype=enabled \
    -Dgdi=auto \
    -Dglib=enabled \
    -Dgobject=enabled \
    -Dgraphite=enabled \
    -Dgraphite2=enabled \
    -Dicu=enabled \
    -Dintrospection=enabled \
    -Dtests=enabled

ninja -v -C builddir -j ${CPU_COUNT}
ninja -v -C builddir test
ninja -C builddir install -j ${CPU_COUNT}

pushd "${PREFIX}"
  rm -rf share/gtk-doc
popd
