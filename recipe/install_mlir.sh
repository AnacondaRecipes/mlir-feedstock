#!/bin/bash

cd build
ninja install

# Run tests manually and skip known failures
cd ${SRC_DIR}/build

# # the helper tools used by lit are expected to be in ${PREFIX}/bin. Perhaps they should be put here while building llvm,
# # or maybe we can use LIT_OPTS or a CMake argument to do this better, see https://llvm.org/docs/CommandGuide/lit.html
tools=(count FileCheck lli-child-target llvm-jitlink-executor llvm-PerfectShuffle not obj2yaml split-file UnicodeNameMappingGenerator yaml2obj yaml-bench)
for tool in "${tools[@]}"; do
    cp "${PREFIX}/libexec/llvm/${tool}" "${PREFIX}/bin/"
done

# See: https://github.com/llvm/llvm-project/issues/115108
#  Unfortunaty disabling LLVM_LINK_LLVM_DYLIB had no effect. 
export LIT_FILTER_OUT='MLIRTargetLLVMTests'

# This target doesn't get built, but does get ran. Build it manually.
ninja mlir-capi-execution-engine-test

ninja check-mlir

# Clean up copied tools
for tool in "${tools[@]}"; do
    if [ -f "${PREFIX}/bin/${tool}" ]; then
        rm -f "${PREFIX}/bin/${tool}"
    fi
done