#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if [ "$#" -lt  "2" ]
  then
      echo "ERROR! build_lovejs.sh expects two arguments."
      echo "usage: ./build_lovejs.sh [PATH/TO/MEGASOURCE] [PATH/TO/EMSDK]"
      echo "ex: "
      echo "./build_lovejs.sh /home/alexjgriffith/Github/love.js/megasource ~/Github/emsdk"
      exit 1
fi


MEGASOURCE=$1
EMSDK=$2

mkdir -p build/release build/compat

source ${EMSDK}/emsdk_env.sh

(
  cd build/release
  emcmake cmake ${MEGASOURCE} -DLOVE_JIT=0 -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  emmake make -j 6
  cp love/love.js* ../../src/release
  cp love/love.wasm ../../src/release
  cp love/love.worker.js ../../src/release
)

(
  cd build/compat
  emcmake cmake ${MEGASOURCE} -DLOVE_JIT=0 -DCMAKE_BUILD_TYPE=Release -DLOVEJS_COMPAT=1 -DSEXPORT_ALL=1 -DSMAIN_MODULE=1 -DSERROR_ON_UNDEFINED_SYMBOLS=0 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  emmake make -j 6
  cp love/love.js* ../../src/compat
  cp love/love.wasm ../../src/compat
)
