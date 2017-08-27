#!/bin/bash

set -e

if [ $(uname) == Darwin ]; then
  export CC=clang
  export CXX=clang++
  export MACOSX_DEPLOYMENT_TARGET="10.9"
  export CXXFLAGS="-stdlib=libc++ $CXXFLAGS"
  export LDFLAGS="$LDFLAGS -Wl,-rpath,$PREFIX/lib"
fi

# CircleCI seems to have some weird issue with harfbuzz tarballs. The files
# come out with modification times such that the build scripts want to rerun
# automake, etc.; we need to run it ourselves since we don't have the precise
# version that the build scripts embed. And the 'configure' script comes out
# without its execute bit set. In a Docker container running locally, these
# problems don't occur.

autoreconf --force --install
chmod +x configure

./configure --prefix=${PREFIX} \
            --host=${HOST} \
            --disable-gtk-doc \
            --enable-static \
            --with-graphite2=yes \
            --with-gobject=yes

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

pushd $PREFIX
rm -rf share/gtk-doc
popd
