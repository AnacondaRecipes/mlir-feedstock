#!/bin/bash
set -euxo pipefail

PARALLEL=""
if [[ "${target_platform}" == "linux-ppc64le" ]]; then
  export CFLAGS="${CFLAGS//-fno-plt/}"
  export CXXFLAGS="${CXXFLAGS//-fno-plt/}"
elif [[ "${target_platform}" == "linux-aarch64" ]]; then
  # reduce parallelism on aarch to avoid OOM
  PARALLEL="-j2"
elif [[ "${target_platform}" == osx-* ]]; then
  CMAKE_ARGS="$CMAKE_ARGS -DLLVM_ENABLE_LIBCXX=ON"
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_TABLEGEN_EXE=$BUILD_PREFIX/bin/llvm-tblgen -DNATIVE_LLVM_DIR=$BUILD_PREFIX/lib/cmake/llvm"
  NATIVE_FLAGS="-DCMAKE_C_COMPILER=$CC_FOR_BUILD;-DCMAKE_CXX_COMPILER=$CXX_FOR_BUILD"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCMAKE_C_FLAGS=-O2;-DCMAKE_CXX_FLAGS=-O2"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,${BUILD_PREFIX}/lib"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCMAKE_MODULE_LINKER_FLAGS=;-DCMAKE_SHARED_LINKER_FLAGS="
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCMAKE_STATIC_LINKER_FLAGS=;-DCMAKE_PREFIX_PATH=${BUILD_PREFIX}"
  CMAKE_ARGS="${CMAKE_ARGS} -DCROSS_TOOLCHAIN_FLAGS_NATIVE=${NATIVE_FLAGS}"
else
  rm -rf $BUILD_PREFIX/bin/llvm-tblgen
fi

mkdir -p build
cd build
# -DLLVM_SHLIB_OUTPUT_INTDIR="${SRC_DIR}/build/lib"
# is required to find the utility dylibs required to run the tests.
cmake ${CMAKE_ARGS} \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_LIBRARY_PATH="${PREFIX}" \
  -DLLVM_ENABLE_RTTI=ON \
  -DLLVM_EXTERNAL_LIT="${BUILD_PREFIX}/bin/llvm-lit" \
  -DMLIR_INCLUDE_DOCS=OFF \
  -DMLIR_INCLUDE_TESTS=ON \
  -DLLVM_BUILD_LLVM_DYLIB=ON \
  -DMLIR_INCLUDE_INTEGRATION_TESTS=ON \
  -DLLVM_SHLIB_OUTPUT_INTDIR="${SRC_DIR}/build/lib" \
  -DLLVM_LINK_LLVM_DYLIB=ON \
  -DLLVM_BUILD_TOOLS=ON \
  -DLLVM_BUILD_UTILS=ON \
  -GNinja \
  ../mlir

ninja ${PARALLEL}

# the helper tools used by lit are expected to be in ${PREFIX}/bin. Perhaps they should be put here while building llvm,
# or maybe we can use LIT_OPTS or a CMake argument to do this better, see https://llvm.org/docs/CommandGuide/lit.html
tools=(count FileCheck lli-child-target llvm-jitlink-executor llvm-PerfectShuffle not obj2yaml split-file UnicodeNameMappingGenerator yaml2obj yaml-bench)
for tool in "${tools[@]}"; do
    cp "${PREFIX}/libexec/llvm/${tool}" "${PREFIX}/bin/"
done

# We're currently passing despite failing tests; TODO is to come back and look at these failures
# in more detail, and either fix or skip explicitly.
#cmake --build . --target check-mlir -- -j${CPU_COUNT} || true


cd ../mlir/test
cp ${SRC_DIR}/build/test/lit.site.cfg.py ./
#${PYTHON} ${BUILD_PREFIX}/bin/llvm-lit -vv Transforms Analysis IR || true

# Temporarily, let's skip executing the tests, because we just want to validate the triton chain for now.
# getting the following test-run failures:

## known failure: https://github.com/llvm/llvm-project/issues/115108
# CommandLine Error: Option 'enable-branch-hint' registered more than once!
# ...
#  MLIR-Unit :: Target/LLVM/./MLIRTargetLLVMTests/failed_to_discover_tests_from_gtest
## Can't immediately find an issue for this one:
# None INFO $PREFIX/bin/mlir-capi-execution-engine-test 2>&1 | $PREFIX/bin/FileCheck $SRC_DIR/mlir/test/CAPI/execution_engine.c
# None INFO # executed command: $PREFIX/bin/mlir-capi-execution-engine-test
# None INFO # .---command stderr------------
# None INFO # | '$PREFIX/bin/mlir-capi-execution-engine-test': command not found
# None INFO # `-----------------------------
# None INFO # error: command failed with exit status: 127
# I also disabled the tests for libmlir_async_runtime.dylib/so presence, which may be related. See the following:
# https://github.com/llvm/llvm-project/pull/87067
# https://github.com/llvm/llvm-project/issues/53989
# https://reviews.llvm.org/D117287
# Again, can have a closer look when the triton chain is validated.


# Clean up copied tools
for tool in "${tools[@]}"; do
    if [ -f "${PREFIX}/bin/${tool}" ]; then
        rm -f "${PREFIX}/bin/${tool}"
    fi
done