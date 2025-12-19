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

capitalize() {
  if [ -z "$1" ]; then
    return 1
  fi

  local first_char rest
  first_char=$(echo "${1:0:1}" | tr '[:lower:]' '[:upper:]')
  rest="${1:1}"
  echo "${first_char}${rest}"
}

# Apply the patch before building
if [ -f "/build_dir/173075.patch" ]; then
    echo "Applying patch 173075.patch..."
    patch -p1 < /build_dir/173075.patch
    if [ $? -ne 0 ]; then
        echo "Error: Failed to apply patch."
        exit 1
    fi
else
    echo "Error: Patch file 173075.patch not found."
    exit 1
fi

CXX_FLAGS=""
LDFLAGS=""
ADDITIONAL_FLAGS=""
if [ "$STDLIB" == "libcxx" ]; then
    CXXFLAGS="-stdlib=libc++ -std=c++23"
    LDFLAGS="-lc++"
elif [ "$STDLIB" == "libstdcxx" ]; then
    CXXFLAGS="-std=c++23"
    LDFLAGS=""
else
    echo "Error: STDLIB env not set to either libc++ or stdlibc++."
    exit 1
fi

if [ ! "${ENABLE_SANITIZER}" = "none" ]; then
    ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS} -DLLVM_USE_SANITIZER=$(capitalize ${ENABLE_SANITIZER})"
fi

if [ "${ENABLE_SANITIZER}" = "undefined" ]; then
    ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS} -DLLVM_ENABLE_RTTI=ON"
fi

if [ "${ENABLE_SANITIZER}" = "thread" ]; then
    export TSAN_OPTIONS="report_bugs=0"
fi

if [ ! -z "${CXXFLAGS}" ]; then
    export CXXFLAGS
fi

if [ ! -z "${LDFLAGS}" ]; then
    export LDFLAGS
fi

cmake -G Ninja -S llvm -B build -DCMAKE_BUILD_TYPE=Release \
    			        -DLLVM_ENABLE_PROJECTS="mlir"   \
				-DLLVM_TARGETS_TO_BUILD=Native \
				-DLLVM_BUILD_TOOLS=OFF \
				-DCMAKE_INSTALL_PREFIX="/build_dir/clang" \
				${ADDITIONAL_FLAGS}

cmake --build build --target install -j$(nproc)

