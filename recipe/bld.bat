@echo on
mkdir build
cd build

cmake -GNinja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
  -DLLVM_USE_INTEL_JITEVENTS=ON ^
  -DLLVM_ENABLE_RTTI=ON ^
  -DMLIR_INCLUDE_DOCS=OFF ^
  -DMLIR_INCLUDE_TESTS=ON ^
  -DLLVM_BUILD_TOOLS=ON ^
  -DLLVM_BUILD_UTILS=ON ^
  -DCMAKE_POLICY_DEFAULT_CMP0111=NEW ^
  ..\mlir
if %ERRORLEVEL% neq 0 exit 1

cmake --build .
if %ERRORLEVEL% neq 0 exit 1

cmake --build . --target check-mlir

cd ..\mlir\test
%BUILD_PREFIX%\python.exe ..\..\build\bin\llvm-lit.py -vv Transforms Analysis IR
