#!/bin/bash

set -ex

# necessary to ensure the gobject-introspection-1.0 pkg-config file gets found
# meson uses PKG_CONFIG_PATH to search when not cross-compiling and
# PKG_CONFIG_PATH_FOR_BUILD when cross-compiling,
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG_PATH_FOR_BUILD=$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

# Make sure .gir files in $PREFIX are found
export XDG_DATA_DIRS=${XDG_DATA_DIRS}:$PREFIX/share:$BUILD_PREFIX/share

meson_config_args=(
    -Dbenchmark=disabled
    -Dcairo=enabled
    -Dcoretext=auto
    -Ddocs=disabled
    -Dfreetype=enabled
    -Dgdi=auto
    -Dglib=enabled
    -Dgobject=enabled
    -Dgraphite2=enabled
    -Dicu=enabled
    -Dintrospection=enabled
    -Dtests=disabled
)

if [ -n "$OSX_ARCH" ] ; then
    # The -dead_strip_dylibs option breaks g-ir-scanner here
    export LDFLAGS="$(echo $LDFLAGS |sed -e "s/-Wl,-dead_strip_dylibs//g")"
    export LDFLAGS_LD="$(echo $LDFLAGS_LD |sed -e "s/-dead_strip_dylibs//g")"
fi

# NB: $MESON_ARGS sets buildtype, prefix, and libdir.
meson setup builddir \
    ${MESON_ARGS} \
    "${meson_config_args[@]}" \
    --default-library=both \
    --wrap-mode=nofallback
ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}

pushd $PREFIX
rm -rf share/gtk-doc
popd
