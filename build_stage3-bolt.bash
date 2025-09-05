#!/bin/bash

export TOPLEV=~/toolchain/llvm
cd ${TOPLEV} || exit 1

mkdir ${TOPLEV}/stage3-bolt  || (echo "Could not create stage3-bolt directory"; exit 1)
cd ${TOPLEV}/stage3-bolt || exit 1
CPATH=${TOPLEV}/stage2-prof-use-lto/install/bin
BOLTPATH=${TOPLEV}/llvm-bolt/bin



echo "== Configure Build"
echo "== Build with stage2-prof-use-tools -- $CPATH"

cmake -G Ninja ${TOPLEV}/llvm-project/llvm \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=${CPATH}/clang \
    -DCMAKE_CXX_COMPILER=${CPATH}/clang++ \
    -DLLVM_BINUTILS_INCDIR=/usr/include \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_USE_LINKER=lld \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
    || (echo "Could not configure project!"; exit 1)

echo "== Start Training Build"
perf record -o ${TOPLEV}/perf.data --max-size=4G -F 1900 -e cycles:u -j any,u -- ninja clang || (echo "Could not build project for training!"; exit 1)

cd ${TOPLEV} || exit 1

echo "Converting profile to a more aggregated form suitable to be consumed by BOLT"

LD_PRELOAD=/usr/lib/libjemalloc.so ${BOLTPATH}/perf2bolt ${CPATH}/clang-18 \
    -p ${TOPLEV}/perf.data \
    -o ${TOPLEV}/clang-18.fdata || (echo "Could not convert perf-data to bolt for clang-18"; exit 1)

echo "Optimizing Clang with the generated profile"

LD_PRELOAD=/usr/lib/libjemalloc.so ${BOLTPATH}/llvm-bolt ${CPATH}/clang-18 \
    -o ${CPATH}/clang-18.bolt \
    --data ${TOPLEV}/clang-18.fdata \
    -reorder-blocks=ext-tsp \
    -reorder-functions=cdsort \
    -split-functions \
    -split-all-cold \
    -split-eh \
    -dyno-stats \
    -icf=1 \
    -use-gnu-stack \
    -plt=hot || (echo "Could not optimize binary for clang"; exit 1)

echo "Optimizing LLD with the generated profile"

LD_PRELOAD=/usr/lib/libjemalloc.so ${BOLTPATH}/llvm-bolt ${CPATH}/lld \
    -o ${CPATH}/lld.bolt \
    --data ${TOPLEV}/clang-18.fdata \
    -reorder-blocks=ext-tsp \
    -reorder-functions=cdsort \
    -split-functions \
    -split-all-cold \
    -split-eh \
    -dyno-stats \
    -icf=1 \
    -use-gnu-stack \
    -plt=hot || (echo "Could not optimize binary for lld"; exit 1)


echo "move bolted binary to clang-18"
mv ${CPATH}/clang-18 ${CPATH}/clang-18.org
mv ${CPATH}/clang-18.bolt ${CPATH}/clang-18
mv ${CPATH}/lld ${CPATH}/lld.org
mv ${CPATH}/lld.bolt ${CPATH}/lld

echo "You can now use the compiler with export PATH=${CPATH}"
