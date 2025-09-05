#!/bin/bash

TOPLEV=~/toolchain/llvm
cd ${TOPLEV} || exit 1

mkdir -p ${TOPLEV}/stage3-without-sampling/intrumentdata || (echo "Could not create stage3-bolt directory"; exit 1)
cd ${TOPLEV}/stage3-without-sampling || exit 1
CPATH=${TOPLEV}/stage2-prof-use-lto/install/bin
BOLTPATH=${TOPLEV}/llvm-bolt/bin


echo "Instrument clang with llvm-bolt"

${BOLTPATH}/llvm-bolt \
    --instrument \
    --instrumentation-file-append-pid \
    --instrumentation-file=${TOPLEV}/stage3-without-sampling/intrumentdata/clang-18.fdata \
    ${CPATH}/clang-18 \
    -o ${CPATH}/clang-18.inst

echo "moving instrumented binary"
mv ${CPATH}/clang-18 ${CPATH}/clang-18.org
mv ${CPATH}/clang-18.inst ${CPATH}/clang-18

echo "== Configure Build"
echo "== Build with stage2-prof-use-lto instrumented clang -- $CPATH"

cmake -G Ninja ${TOPLEV}/llvm-project/llvm \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DCMAKE_AR=${CPATH}/llvm-ar \
    -DCMAKE_C_COMPILER=${CPATH}/clang-18 \
    -DCMAKE_CXX_COMPILER=${CPATH}/clang++ \
    -DLLVM_USE_LINKER=lld \
    -DCMAKE_RANLIB=${CPATH}/llvm-ranlib \
    -DCMAKE_INSTALL_PREFIX=${TOPLEV}/stage3-without-sampling/install

echo "== Start Training Build"
ninja & read -rt 100 || kill $!

echo "Merging generated profiles"
cd ${TOPLEV}/stage3-without-sampling/intrumentdata || exit 1
LD_PRELOAD=/usr/lib/libjemalloc.so ${BOLTPATH}/merge-fdata ./*.fdata > combined.fdata
echo "Optimizing Clang with the generated profile"

LD_PRELOAD=/usr/lib/libjemalloc.so ${BOLTPATH}/llvm-bolt ${CPATH}/clang-18.org \
    --data combined.fdata \
    -o ${CPATH}/clang-18 \
    -reorder-blocks=ext-tsp \
    -reorder-functions=cdsort \
    -split-functions \
    -split-all-cold \
    -split-eh \
    -dyno-stats \
    -icf=1 \
    -use-gnu-stack \
    -plt=hot|| (echo "Could not optimize binary for clang"; exit 1)

echo "You can now use the compiler with export PATH=${CPATH}:${PATH}"
