#!/bin/bash
set -x -e

# cd ${SRC_DIR}/build
# ninja install

# cd $PREFIX
# rm -rf libexec share bin include
# mv lib lib2
# mkdir lib
# mv lib2/libLLVM* lib/
mkdir temp_prefix
cmake --install ./build --prefix=./temp_prefix
if [[ "$PKG_NAME" == "libmlir" ]]; then
    mv ./temp_prefix/libMLIR${SHLIB_EXT} $PREFIX/lib
    mv ./temp_prefix/libmlir_runner_utils${SHLIB_EXT} $PREFIX/lib
    mv ./temp_prefix/libmlir_c_runner_utils${SHLIB_EXT} $PREFIX/lib
    mv ./temp_prefix/libmlir_async_runtime${SHLIB_EXT} $PREFIX/lib
    mv ./temp_prefix/libmlir_float16_utils${SHLIB_EXT} $PREFIX/lib
else
    mv ./temp_prefix/libMLIR.*.* $PREFIX/lib
    mv ./temp_prefix/libmlir_runner_utils.*.* $PREFIX/lib
    mv ./temp_prefix/libmlir_c_runner_utils.*.* $PREFIX/lib
    mv ./temp_prefix/libmlir_async_runtime.*.* $PREFIX/lib
    mv ./temp_prefix/libmlir_float16_utils.*.* $PREFIX/lib
fi
rm -rf temp_prefix

