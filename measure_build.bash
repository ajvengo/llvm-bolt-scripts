#!/bin/bash

TOPLEV=~/toolchain/llvm

# Change your compiler PATH here to compare them

CPATH=${TOPLEV}/stage2-prof-use-lto/install/bin

cd ${TOPLEV} || (echo "Could not enter ${TOPLEV} directory"; exit 1)

echo "== Clean old build-artifacts"
rm -rf measure-build-time
mkdir -p measure-build-time || (echo "Could not create build-directory!"; exit 1)
cd measure-build-time || exit 1

echo "== Configure reference Clang-build with tools from ${CPATH}"

cmake -G Ninja ${TOPLEV}/llvm-project/llvm \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=${CPATH}/clang \
    -DCMAKE_CXX_COMPILER=${CPATH}/clang++ \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)"\
    -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
    || (echo "Could not configure project!"; exit 1)

echo
echo "== Start Build"
time ninja clang || (echo "Could not build project!"; exit 1)
