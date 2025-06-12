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
set -e
cd build_dir/llvm-project

apt install -y libclang-19-dev

CXX_FLAGS=""
LDFLAGS=""
ADDITIONAL_FLAGS=""
if [ "$STDLIB" == "libcxx" ]; then
    if [ "$ENABLE_SANITIZER" = "none" ]; then 
      cmake -G Ninja -S runtimes -B build-libcxx -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DCMAKE_INSTALL_PREFIX="/build_dir/libcxx"
	CXXFLAGS="-std=c++23 -nostdinc++ -isystem /build_dir/libcxx/include/c++/v1"
	LDFLAGS="-L/build_dir/libcxx/lib -lc++ -rpath /build_dir/libcxx/lib"
    elif [ "$ENABLE_SANITIZER" = "asan" ]; then 
      cmake -G Ninja -S runtimes -B build-libcxx -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DCMAKE_INSTALL_PREFIX="/build_dir/libcxx" -DLLVM_USE_SANITIZER="Address"
	CXXFLAGS="-std=c++23 -nostdinc++ -isystem /build_dir/libcxx/include/c++/v1 -fsanitize=address"
	LDFLAGS="-L/build_dir/libcxx/lib -lc++ -rpath /build_dir/libcxx/lib -fsanitize=address"
    elif [ "$ENABLE_SANITIZER" = "tsan" ]; then 
      cmake -G Ninja -S runtimes -B build-libcxx -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DCMAKE_INSTALL_PREFIX="/build_dir/libcxx" -DLLVM_USE_SANITIZER="Thread"
	CXXFLAGS="-std=c++23 -nostdinc++ -isystem /build_dir/libcxx/include/c++/v1 -fsanitize=thread"
	LDFLAGS="-L/build_dir/libcxx/lib -lc++ -rpath /build_dir/libcxx/lib -fsanitize=thread"
    elif [ "$ENABLE_SANITIZER" = "ubsan" ]; then 
      cmake -G Ninja -S runtimes -B build-libcxx -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DCMAKE_INSTALL_PREFIX="/build_dir/libcxx" -DLLVM_USE_SANITIZER="Undefined"
	CXXFLAGS="-std=c++23 -nostdinc++ -isystem /build_dir/libcxx/include/c++/v1 -fsanitize=undefined"
	LDFLAGS="-L/build_dir/libcxx/lib -lc++ -rpath /build_dir/libcxx/lib -fsanitize=undefined"
    else 
      echo unexpected sanitizer: $SANITIZER; 
      exit 1
    fi
    ninja -C build-libcxx install-cxx install-cxxabi install-unwind
elif [ "$STDLIB" == "libstdcxx" ]; then
    CXXFLAGS="-std=c++23"
    LDFLAGS=""
else
    echo "Error: STDLIB env not set to either libc++ or stdlibc++."
    exit 1
fi

if [ "$ENABLE_SANITIZER" = "none" ]; then 
    echo "Not using a sanitizer"
elif [ "$ENABLE_SANITIZER" = "asan" ]; then 
    ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS} -DLLVM_USE_SANITIZER=Address"
elif [ "$ENABLE_SANITIZER" = "tsan" ]; then 
    ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS} -DLLVM_USE_SANITIZER=Thread"
    export TSAN_OPTIONS="report_bugs=0"
elif [ "$ENABLE_SANITIZER" = "ubsan" ]; then 
    ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS} -DLLVM_ENABLE_RTTI=ON"
    ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS} -DLLVM_USE_SANITIZER=Undefined"
else 
  echo unexpected sanitizer: $SANITIZER; 
  exit 1
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

