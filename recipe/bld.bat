setlocal EnableDelayedExpansion
@echo on

:: https://github.com/harfbuzz/harfbuzz/blob/4.3.0/meson_options.txt
meson setup builddir ^
	--wrap-mode=nofallback ^
	--buildtype=release ^
	--prefix=%LIBRARY_PREFIX% ^
	--backend=ninja ^
    -Dglib=enabled ^
    -Dgobject=enabled ^
    -Dcairo=enabled ^
    -Dchafa=disabled ^
    -Dicu=enabled ^
    -Dgraphite=disabled ^
    -Dgraphite2=enabled ^
    -Dfreetype=enabled ^
    -Dgdi=enabled ^
    -Ddirectwrite=disabled ^
    -Dcoretext=disabled ^
    -Ddocs=disabled ^
    -Dtests=enabled ^
	-Dbenchmark=disabled ^
	-Dintrospection=disabled ^
if errorlevel 1 exit 1

:: print results of build configuration
meson configure builddir
if errorlevel 1 exit 1

ninja -v -C builddir -j %CPU_COUNT%
if errorlevel 1 exit 1

ninja -v -C builddir test
if errorlevel 1 exit 1

ninja -C builddir install -j %CPU_COUNT%
if errorlevel 1 exit 1

del %LIBRARY_PREFIX%\bin\*.pdb