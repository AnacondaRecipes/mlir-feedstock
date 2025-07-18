#!/bin/bash
set -euxo pipefail

PARALLEL="-j${CPU_COUNT}"
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
# LLVM_LINK_LLVM_DYLIB refers to how the tools link. They aren't packaged, and turning it off solves
# https://github.com/llvm/llvm-project/issues/115108 which we encountered
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
  -DLLVM_LINK_LLVM_DYLIB=OFF \
  -DLLVM_BUILD_TOOLS=ON \
  -DLLVM_BUILD_UTILS=ON \
  -GNinja \
  ../mlir

ninja ${PARALLEL}