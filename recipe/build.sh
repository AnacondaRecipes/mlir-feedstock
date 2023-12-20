#!/bin/bash

set -euxo pipefail

if [[ "${target_platform}" == osx-* ]]; then
    CMAKE_ARGS="$CMAKE_ARGS -DLLVM_ENABLE_LIBCXX=ON"
fi

echo ${SRC_DIR}
mkdir -p build
cd build
export CMAKE_CXX_COMPILER_LAUNCHER="${BUILD_PREFIX}"/bin/ccache
# cmake ${CMAKE_ARGS} \
#   -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
#   -DCMAKE_BUILD_TYPE=Release \
#   -DCMAKE_LIBRARY_PATH="${PREFIX}" \
#   -DLLVM_ENABLE_RTTI=ON \
#   -DLLVM_EXTERNAL_LIT="${BUILD_PREFIX}/bin/llvm-lit" \
#   -DMLIR_INCLUDE_DOCS=OFF \
#   -DMLIR_INCLUDE_TESTS=ON \
#   -DMLIR_INCLUDE_INTEGRATION_TESTS=ON \
#   -DLLVM_BUILD_LLVM_DYLIB=ON \
#   -DLLVM_LINK_LLVM_DYLIB=ON \
#   -DLLVM_BUILD_TOOLS=ON \
#   -DLLVM_BUILD_UTILS=ON \
#   -DCMAKE_POLICY_DEFAULT_CMP0111=NEW \
#   -GNinja \
#   ../mlir
cmake ${CMAKE_ARGS} \
   -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
   -DCMAKE_BUILD_TYPE=Release \
   -DCMAKE_LIBRARY_PATH="${PREFIX}" \
   -DLLVM_DIR:PATH="${BUILD_PREFIX}"/lib/cmake/llvm \
   -DLLVM_EXTERNAL_LIT="${BUILD_PREFIX}"/bin/llvm-lit \
   -DMLIR_TOOLS_DIR="${SRC_DIR}"/build \
   -DMLIR_INCLUDE_TESTS=ON \
   -GNinja \
   ../mlir
ninja -j${CPU_COUNT}
#echo ${BUILD_PREFIX}
#ls -la "${BUILD_PREFIX}/bin"
# is PREFIX the env or host directory?
#echo ${PREFIX}
# without the -DMLIR_TOOLS_DIR above:
# config.mlir_tools_dir:$SRC_DIR/build/bin
# config.llvm_tools_dir:$BUILD_PREFIX/bin
# with it:
# config.mlir_tools_dir:$SRC_DIR/build/bin
# config.llvm_tools_dir:$BUILD_PREFIX/bin


# this is where lit expects to find helper tools. Not sure how to point it towards this directory properly. Could be -DLLVM_TOOLS_DIR, but
# the config doesn't seem to be picking this up.
cp ${BUILD_PREFIX}/libexec/llvm/* ${BUILD_PREFIX}/bin
# # export MLIR_C_RUNNER_UTILS=./lib/libmlir_c_runner_utils.dylib
# # export MLIR_RUNNER_UTILS=./lib/libmlir_runner_utils.dylib
# # export CMAKE_LIBRARY_OUTPUT_DIRECTORY=./lib/
# #export MLIR_TOOLS_DIR=./lib/
# #export LIT_OPTS="--path=./lib/"
# # try:
# # - copying the dylibs to the bin directory, like above
# cp ${PREFIX}/lib/*.dylib ${PREFIX}/bin
# cmake --build . --target check-mlir -- -j${CPU_COUNT}

# cd ../mlir/examples/standalone
# mkdir build && cd build
# cmake -G Ninja .. -DMLIR_DIR=../../../build/lib/cmake/mlir -DLLVM_EXTERNAL_LIT="${BUILD_PREFIX}"/bin/llvm-lit
# cmake --build . --target check-standalone
# search llvm-project issues: mlir, standalone, out-of-tree, conda, check-mlir, check-, ...
# contact h-vetinari

# from looking at standalone example:
#  set(MLIR_BINARY_DIR ${CMAKE_BINARY_DIR})
# set(STANDALONE_BINARY_DIR ${PROJECT_BINARY_DIR})
# seem to be used in the lit cfg files
# do we see message(STATUS "Configuring for standalone build.")?

ninja check-mlir
cd ../mlir/test
${PYTHON} ${BUILD_PREFIX}/bin/llvm-lit -vv Transforms Analysis IR
