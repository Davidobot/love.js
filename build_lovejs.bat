@echo off
mkdir build
mkdir build\release
mkdir build\compat

call C:\Users\Grigor\git\emsdk\emsdk_env || exit /b 1
set "PATH=%EMSDK%\upstream\emscripten;%PATH%"
git -C "%EMSDK%" apply --reverse --check --directory=upstream/emscripten "%~dp0patches\emscripten-2.0.0-client-indices.patch"
if errorlevel 1 (
  echo Apply the Emscripten 2.0.0 client-index patch as described in readme.md.
  exit /b 1
)

(
echo Building release version...
cd build\release
call emcmake cmake C:\Users\Grigor\git\megasource -G "Unix Makefiles" -DLOVE_JIT=0 -DCMAKE_BUILD_TYPE=Release || exit /b 1
if exist love\love.js (del love\love.js || exit /b 1)
call emmake make -j 6 || exit /b 1
copy "love\love.js*" ..\..\src\release
copy "love\love.wasm" ..\..\src\release
copy "love\love.worker.js" ..\..\src\release

cd ..\..

echo Building compatibility version...
cd build\compat
call emcmake cmake C:\Users\Grigor\git\megasource -G "Unix Makefiles" -DLOVE_JIT=0 -DCMAKE_BUILD_TYPE=Release -DLOVEJS_COMPAT=1 || exit /b 1
if exist love\love.js (del love\love.js || exit /b 1)
call emmake make -j 6 || exit /b 1
copy "love\love.js*" ..\..\src\compat
copy "love\love.wasm" ..\..\src\compat
)