@echo on
mkdir build
cd build

@REM LLVM_USE_INTEL_JITEVENTS requires Intel VTune (ittnotify), unsupported on
@REM Windows ARM64; main's llvmdev 20.1.8 builds it OFF, so mlir-runner must not link it.
@REM CMAKE_POLICY_VERSION_MINIMUM=3.5 for CMake 4 (main has cmake 4.x).
cmake -GNinja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
  -DLLVM_USE_INTEL_JITEVENTS=OFF ^
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 ^
  -DLLVM_ENABLE_RTTI=ON ^
  -DLLVM_EXTERNAL_LIT=%BUILD_PREFIX%\bin\llvm-lit ^
  -DMLIR_INCLUDE_DOCS=OFF ^
  -DMLIR_INCLUDE_TESTS=ON ^
  -DMLIR_INCLUDE_INTEGRATION_TESTS=ON ^
  -DLLVM_BUILD_TOOLS=ON ^
  -DLLVM_BUILD_UTILS=ON ^
  -DLLVM_UTILS_INSTALL_DIR=libexec\llvm ^
  ..\mlir
if %ERRORLEVEL% neq 0 exit 1

ninja -j%CPU_COUNT%
if %ERRORLEVEL% neq 0 exit 1

REM This test isn't working at the moment. Should be fixed.
REM It could be that the required tools need to be copied to the
REM directory where lit expects to find them, like on unix.
REM cmake --build . --target check-mlir -- -j%CPU_COUNT%

REM This one too.
REM cd ..\mlir\test
REM %BUILD_PREFIX%\python.exe %BUILD_PREFIX%\bin\llvm-lit.py -vv Transforms Analysis IR