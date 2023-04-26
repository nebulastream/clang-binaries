#!/bin/bash
# Copyright (C) 2020 by the NebulaStream project (https://nebula.stream)

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cd ./llvm-project
rm -rf ./build
mkdir build
cmake -G Ninja -S llvm -B build -DCMAKE_BUILD_TYPE=Release \
			    -DLLVM_ENABLE_PROJECTS="clang;lld;mlir"   \
				-DBOOTSTRAP_LLVM_ENABLE_LTO=ON \
				-DLLVM_INCLUDE_EXAMPLES=OFF    \
				-DLLVM_INCLUDE_TESTS=OFF \
				-DLLVM_INCLUDE_BENCHMARKS=OFF \
				-DLLVM_BUILD_EXAMPLES=OFF \
				-DLIBCXX_INCLUDE_BENCHMARKS=OFF \
				-DLLVM_OPTIMIZED_TABLEGEN=ON \
				-DCMAKE_INSTALL_PREFIX="../clang" \
				-DLLVM_TARGETS_TO_BUILD="AArch64" \
				-DLLVM_BUILD_TOOLS=ON \
				-DLLVM_ENABLE_TERMINFO=OFF \
				-DLLVM_ENABLE_Z3_SOLVER=OFF \
				-DCOMPILER_RT_ENABLE_IOS=OFF \
				-DCOMPILER_RT_ENABLE_WATCHOS=OFF \
				-DCOMPILER_RT_ENABLE_TVOS=OFF
ninja -C build 
ninja -C build clang-format
ninja -C build llvm-cov
#ninja -C build runtimes
ninja -C build install
ninja -C build install llvm-cov
#ninja -C build mlir-libraries mlir-cmake-exports mlir-headers

#ninja -C build check-runtimes


