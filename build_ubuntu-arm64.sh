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
set -o xtrace
cd /build_dir/llvm-project
rm -rf ./build
mkdir build

local CXX_FLAGS=""
local LINKER_FLAGS=""
local ADDITIONAL_FLAGS=""
if [ "$STDLIB" == "libc++" ]; then
    CXX_FLAGS="-stdlib=libc++ -std=c++20"
    LINKER_FLAGS="-lc++"
elif [ "$STDLIB" == "stdlibc++" ]; then
    CXX_FLAGS="-std=c++20"
    LINKER_FLAGS=""
else
    echo "Error: STDLIB env not set to either libc++ or stdlibc++."
    exit 1
fi

if [ ! -z ${ENABLE_SANITIZER+x} ]; then
    ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS} -DLLVM_USE_SANITIZER=${ENABLE_SANITIZER}"
fi

if [ ! -z "${CXX_FLAGS}" ]; then
    ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS} -DCMAKE_CXX_FLAGS=\"${CXX_FLAGS}\""
fi

if [ ! -z "${LINKER_FLAGS}" ]; then
    ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS} -DCMAKE_EXE_LINKER_FLAGS=\"${LINKER_FLAGS}\""
fi

cmake -G Ninja -S llvm -B build -DCMAKE_BUILD_TYPE=Release \
    			        -DLLVM_ENABLE_PROJECTS="mlir"   \
				-DBOOTSTRAP_LLVM_ENABLE_LTO=ON \
				-DLLVM_INCLUDE_EXAMPLES=OFF    \
				-DLLVM_INCLUDE_TESTS=OFF \
				-DLLVM_INCLUDE_BENCHMARKS=OFF \
				-DLLVM_BUILD_EXAMPLES=OFF \
				-DLIBCXX_INCLUDE_BENCHMARKS=OFF \
				-DLLVM_OPTIMIZED_TABLEGEN=ON \
				-DCMAKE_INSTALL_PREFIX="/build_dir/clang" \
				-DLLVM_TARGETS_TO_BUILD="AArch64" \
				-DLLVM_BUILD_TOOLS=ON \
				-DLLVM_ENABLE_TERMINFO=OFF \
				-DLLVM_ENABLE_Z3_SOLVER=OFF \
				${ADDITIONAL_FLAGS}

cmake --build build --target install -j$(nproc)

