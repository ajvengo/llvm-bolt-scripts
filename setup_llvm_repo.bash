#!/bin/bash
export TOPLEV=~/toolchain/llvm
mkdir -p ${TOPLEV}
cd ${TOPLEV} || exit 1
[ -d llvm-project ] || git clone --branch=release/18.x --depth=1 https://github.com/llvm/llvm-project.git
