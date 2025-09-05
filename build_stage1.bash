#!/bin/bash

TOPLEV=~/toolchain/llvm
mkdir -p ${TOPLEV}
cd ${TOPLEV} || (echo "Could not enter ${TOPLEV} directory"; exit 1)
[ -d llvm-project ] || git clone --branch=release/18.x --depth=1 https://github.com/llvm/llvm-project.git

mkdir -p stage1 || (echo "Could not create stage1 directory"; exit 1)
cd stage1 || (echo "Could not enter stage 1 directory"; exit 1)

echo "== Configure Build"
echo "== Build with system clang"

cmake -G Ninja ${TOPLEV}/llvm-project/llvm \
    -DCLANG_ENABLE_ARCMT=OFF \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
    -DCLANG_PLUGIN_SUPPORT=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_EXE_LINKER_FLAGS="-lpthread -lstdc++ -lm -ldl" \
    -DLLVM_BINUTILS_INCDIR=/usr/include \
    -DLLVM_BUILD_UTILS=OFF \
    -DLLVM_ENABLE_BACKTRACES=OFF \
    -DLLVM_ENABLE_BINDINGS=OFF \
    -DLLVM_ENABLE_OCAMLDOC=OFF \
    -DLLVM_ENABLE_PROJECTS="clang;lld;bolt;compiler-rt;llvm" \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_WARNINGS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_USE_LINKER=lld \
    -DCMAKE_INSTALL_PREFIX=${TOPLEV}/llvm-bolt \
    || (echo "Could not configure project!"; exit 1)

echo "== Start Build stage1"
time ninja install || (echo "Could not build project!"; exit 1)
echo "== Stop Build $(pwd)"
