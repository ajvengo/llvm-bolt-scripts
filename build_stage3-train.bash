#!/bin/bash
export TOPLEV=~/toolchain/llvm
cd ${TOPLEV} || exit 1

mkdir ${TOPLEV}/stage3-train
cd ${TOPLEV}/stage3-train || exit 1
CPATH=${TOPLEV}/stage2-prof-gen/bin

echo "Generating Profile for PGO"

cmake -G Ninja ${TOPLEV}/llvm-project/llvm \
    -DCLANG_ENABLE_ARCMT=OFF \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
    -DCLANG_PLUGIN_SUPPORT=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=${CPATH}/clang \
    -DCMAKE_CXX_COMPILER=${CPATH}/clang++ \
    -DLLVM_BINUTILS_INCDIR=/usr/include \
    -DLLVM_ENABLE_BINDINGS=OFF \
    -DLLVM_ENABLE_OCAMLDOC=OFF \
    -DLLVM_ENABLE_PLUGINS=ON \
    -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt" \
    -DLLVM_ENABLE_WARNINGS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_USE_LINKER=lld \
    -DCMAKE_INSTALL_PREFIX=${TOPLEV}/stage3-train/install \
    || (echo "Could not configure project!"; exit 1)

echo "== Start Build"
ninja || (echo "Could not build project!"; exit 1)

echo "Merging PGO-Profiles"

cd ${TOPLEV}/stage2-prof-gen/profiles || exit 1
${TOPLEV}/llvm-bolt/bin/llvm-profdata merge -output=clang.profdata ./*
