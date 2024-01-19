@echo on
mkdir build
cd build

cmake -GNinja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
  -DLLVM_USE_INTEL_JITEVENTS=ON ^
  -DLLVM_ENABLE_RTTI=ON ^
  -DLLVM_EXTERNAL_LIT=%BUILD_PREFIX%\bin\llvm-lit ^
  -DMLIR_INCLUDE_DOCS=OFF ^
  -DMLIR_INCLUDE_TESTS=ON ^
  -DMLIR_INCLUDE_INTEGRATION_TESTS=ON ^
  -DLLVM_BUILD_TOOLS=ON ^
  -DLLVM_BUILD_UTILS=ON ^
  -DCMAKE_POLICY_DEFAULT_CMP0111=NEW ^
  ..\mlir
if %ERRORLEVEL% neq 0 exit 1

cmake --build . -- -j%CPU_COUNT%
if %ERRORLEVEL% neq 0 exit 1

REM this is where lit expects to find helper tools. Perhaps they should be put here while building llvm.
cp %PREFIX%\libexec\llvm\* %PREFIX%\bin
REM This test isn't working at the moment. Should be fixed.
REM cmake --build . --target check-mlir -- -j%CPU_COUNT%

cd ..\mlir\test
%BUILD_PREFIX%\python.exe %BUILD_PREFIX%\bin\llvm-lit.py -vv Transforms Analysis IR
