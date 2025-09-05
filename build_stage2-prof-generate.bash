#!/bin/bash

TOPLEV=~/toolchain/llvm
cd ${TOPLEV} || exit 1

mkdir ${TOPLEV}/stage2-prof-gen || (echo "Could not create stage2-prof-generate directory"; exit 1)
cd ${TOPLEV}/stage2-prof-gen || exit 1
CPATH=${TOPLEV}/llvm-bolt/bin

echo "== Configure Build"
echo "== Build with stage1-tools -- $CPATH"

cmake -G Ninja ${TOPLEV}/llvm-project/llvm \
    -DCLANG_ENABLE_ARCMT=OFF \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
    -DCLANG_PLUGIN_SUPPORT=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=${CPATH}/clang \
    -DCMAKE_CXX_COMPILER=${CPATH}/clang++ \
    -DLLVM_BINUTILS_INCDIR=/usr/include \
    -DLLVM_BUILD_INSTRUMENTED=IR \
    -DLLVM_BUILD_RUNTIME=OFF \
    -DLLVM_ENABLE_BINDINGS=OFF \
    -DLLVM_ENABLE_OCAMLDOC=OFF \
    -DLLVM_ENABLE_PLUGINS=ON \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_WARNINGS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_VP_COUNTERS_PER_SITE=6 \
    -DCMAKE_INSTALL_PREFIX=${TOPLEV}/stage2-prof-gen/install \
    || (echo "Could not configure project!"; exit 1)

echo "== Start Build"
time ninja || (echo "Could not build project!"; exit 1)
echo "== Stop Build $(pwd)"
