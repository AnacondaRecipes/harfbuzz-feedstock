#!/bin/bash

set -e

# Cf. https://github.com/conda-forge/staged-recipes/issues/673, we're in the
# process of excising Libtool files from our packages. Existing ones can break
# the build while this happens.
find $PREFIX -name '*.la' -delete

# necessary to ensure the gobject-introspection-1.0 pkg-config file gets found
# meson needs this to determine where the g-ir-scanner script is located
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config


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
    -Dlibdir=lib \
    -Dglib=enabled \
    -Dgobject=enabled \
    -Dcairo=enabled \
    -Dchafa=disabled \
    -Dicu=enabled \
    -Dgraphite=disabled \
    -Dgraphite2=enabled \
    -Dfreetype=enabled \
    -Dgdi=disabled \
    -Ddirectwrite=disabled \
    -Ddocs=disabled \
    -Dtests=enabled \
    ${meson_extra_opts[@]}

ninja -v -C builddir -j ${CPU_COUNT}
ninja -v -C builddir test
ninja -C builddir install -j ${CPU_COUNT}

pushd "${PREFIX}"
  rm -rf share/gtk-doc
popd
