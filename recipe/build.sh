#!/bin/bash

set -euxo pipefail

if [[ "${target_platform}" == osx-* ]]; then
    CMAKE_ARGS="$CMAKE_ARGS -DLLVM_ENABLE_LIBCXX=ON"
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_TABLEGEN_EXE=$BUILD_PREFIX/bin/llvm-tblgen -DNATIVE_LLVM_DIR=$BUILD_PREFIX/lib/cmake/llvm"
  CMAKE_ARGS="${CMAKE_ARGS} -DCROSS_TOOLCHAIN_FLAGS_NATIVE=-DCMAKE_C_COMPILER=$CC_FOR_BUILD;-DCMAKE_CXX_COMPILER=$CXX_FOR_BUILD;-DCMAKE_C_FLAGS=-O2;-DCMAKE_CXX_FLAGS=-O2;-DCMAKE_EXE_LINKER_FLAGS=\"-L$BUILD_PREFIX/lib\";-DCMAKE_MODULE_LINKER_FLAGS=;-DCMAKE_SHARED_LINKER_FLAGS=;-DCMAKE_STATIC_LINKER_FLAGS=;-DCMAKE_AR=$(which ${AR});-DCMAKE_RANLIB=$(which ${RANLIB});-DCMAKE_PREFIX_PATH=${BUILD_PREFIX}"
else
  rm -rf $BUILD_PREFIX/bin/llvm-tblgen
fi

mkdir -p build
cd build

cmake ${CMAKE_ARGS} \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_LIBRARY_PATH="${PREFIX}" \
  -DLLVM_ENABLE_RTTI=ON \
  -DLLVM_EXTERNAL_LIT="${BUILD_PREFIX}/bin/llvm-lit" \
  -DMLIR_INCLUDE_DOCS=OFF \
  -DMLIR_INCLUDE_TESTS=ON \
  -DLLVM_BUILD_LLVM_DYLIB=ON \
  -DLLVM_CCACHE_BUILD=ON \
  -DMLIR_INCLUDE_INTEGRATION_TESTS=ON \
  -DLLVM_SHLIB_OUTPUT_INTDIR="${SRC_DIR}/build/lib" \
  -DLLVM_LINK_LLVM_DYLIB=ON \
  -DLLVM_BUILD_TOOLS=ON \
  -DLLVM_BUILD_UTILS=ON \
  -DCMAKE_POLICY_DEFAULT_CMP0111=NEW \
  -GNinja \
  ../mlir

cmake --build . -- -j${CPU_COUNT}
#echo ${BUILD_PREFIX}
#ls -la "${BUILD_PREFIX}/bin"
# is PREFIX the env or host directory?
#echo ${PREFIX}

# this is where lit expects to find helper tools. Perhaps they should be put here while building llvm.
cp ${PREFIX}/libexec/llvm/* ${PREFIX}/bin
cmake --build . --target check-mlir -- -j${CPU_COUNT}

cd ../mlir/test
cp ${SRC_DIR}/build/test/lit.site.cfg.py ./
${PYTHON} ${BUILD_PREFIX}/bin/llvm-lit -vv Transforms Analysis IR
