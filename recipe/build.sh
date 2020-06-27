#!/bin/bash

set -e

# Cf. https://github.com/conda-forge/staged-recipes/issues/673, we're in the
# process of excising Libtool files from our packages. Existing ones can break
# the build while this happens.
find $PREFIX -name '*.la' -delete

# CircleCI seems to have some weird issue with harfbuzz tarballs. The files
# come out with modification times such that the build scripts want to rerun
# automake, etc.; we need to run it ourselves since we don't have the precise
# version that the build scripts embed. And the 'configure' script comes out
# without its execute bit set. In a Docker container running locally, these
# problems don't occur.

# Anaconda recipe maintainers: Do *NOT* run `autoreconf` as that breaks
# configure's ability to properly configure gobject introspection.
#autoreconf -vfi
#chmod +x configure

declare -a configure_extra_opts
case "${target_platform}" in
    linux-*)
        # Needed for libxcb when using CDT X11 packages
        export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${PREFIX}/lib"
        ;;
    osx-64)
        configure_extra_opts+=(--with-coretext=yes)
        ;;
esac

./configure --prefix="${PREFIX}" \
            --host=${HOST} \
            --disable-gtk-doc \
            --enable-static \
            --with-graphite2=yes \
            --with-gobject=yes \
            ${configure_extra_opts[@]}

make -j${CPU_COUNT} ${VERBOSE_AT}
# FIXME
# OS X:
# FAIL: test-ot-tag
# Linux (all the tests pass when using the docker image :-/)
# FAIL: check-c-linkage-decls.sh
# FAIL: check-defs.sh
# FAIL: check-header-guards.sh
# FAIL: check-includes.sh
# FAIL: check-libstdc++.sh
# FAIL: check-static-inits.sh
# FAIL: check-symbols.sh
# PASS: test-ot-tag
# make check
make install

pushd "${PREFIX}"
  rm -rf share/gtk-doc
popd
