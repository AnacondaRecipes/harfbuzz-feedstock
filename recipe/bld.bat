setlocal EnableDelayedExpansion
@echo on

:: set pkg-config path so that host deps can be found
:: (set as env var so it's used by both meson and during build with g-ir-scanner)
set "PKG_CONFIG_PATH=%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig;%BUILD_PREFIX%\Library\lib\pkgconfig;%BUILD_PREFIX%\Library\share\pkgconfig"

:: get mixed path (forward slash) form of prefix so host prefix replacement works
set "LIBRARY_PREFIX_M=%LIBRARY_PREFIX:\=/%"

:: https://github.com/harfbuzz/harfbuzz/blob/4.3.0/meson_options.txt
:: cairo is used only by the HarfBuzz command-line hb-view, and not by the HarfBuzz library.
:: Our cairo windows version doesn't link to freetype, therefore hb-view is not built.
:: https://harfbuzz.github.io/building.html
:: https://github.com/harfbuzz/harfbuzz/blob/4.3.0/util/meson.build
meson setup builddir ^
	--wrap-mode=nofallback ^
	--buildtype=release ^
	--prefix=%LIBRARY_PREFIX_M% ^
	--backend=ninja ^
  -Dbenchmark=disabled ^
  -Dintrospection=enabled ^
  -Dcairo=enabled ^
  -Dchafa=disabled ^
  -Dcoretext=disabled ^
  -Ddirectwrite=disabled ^
  -Ddocs=disabled ^
  -Dfreetype=enabled ^
  -Dgdi=enabled ^
  -Dglib=enabled ^
  -Dgobject=enabled ^
  -Dgraphite=disabled ^
  -Dgraphite2=enabled ^
  -Dicu=enabled ^
  -Dtests=enabled
if errorlevel 1 (
  type src/HarfBuzz-0.0.gir
  exit 1
)

:: print results of build configuration
meson configure builddir
if errorlevel 1 (
  type src/HarfBuzz-0.0.gir
  exit 1
)

ninja -v -C builddir -j %CPU_COUNT%
if errorlevel 1 (
  type src/HarfBuzz-0.0.gir && exit 1
  exit 1
)

ninja -v -C builddir test
if errorlevel 1 exit 1

ninja -C builddir install -j %CPU_COUNT%
if errorlevel 1 exit 1

del %LIBRARY_PREFIX%\bin\*.pdb
