include(${HPCC_DEPS_DIR}/hpcc/cmake/cuda-common.cmake)

if(PPLCV_USE_MSVC_STATIC_RUNTIME)
    hpcc_cuda_use_msvc_static_runtime()
endif()

# One gencode per GPU architecture the image is deployed on. A cubin only
# loads on the architecture it was built for and later minor revisions of the
# same major, so Ampere cubins do not run on Turing: without an explicit
# sm_75 entry every CUDA call on a T4 fails with "no kernel image is
# available for execution". Kept in step with TORCH_CUDA_ARCH_LIST in the
# gpu-compute Dockerfiles so the image has a single supported-architecture
# list. The trailing PTX entry lets a GPU newer than sm_89 JIT-compile
# instead of hitting the same failure.
set(_NVCC_FLAGS )
if (CUDA_VERSION_MAJOR VERSION_GREATER_EQUAL "11")
    set(_NVCC_FLAGS "${_NVCC_FLAGS} -gencode arch=compute_61,code=sm_61")
    set(_NVCC_FLAGS "${_NVCC_FLAGS} -gencode arch=compute_70,code=sm_70")
    set(_NVCC_FLAGS "${_NVCC_FLAGS} -gencode arch=compute_75,code=sm_75")
    set(_NVCC_FLAGS "${_NVCC_FLAGS} -gencode arch=compute_80,code=sm_80")
    set(_NVCC_FLAGS "${_NVCC_FLAGS} -gencode arch=compute_86,code=sm_86")
endif ()
# sm_89 (L4 / L40S) requires CUDA 11.8; this fork targets the CUDA 12 toolchain.
if (CUDA_VERSION_MAJOR VERSION_GREATER_EQUAL "12")
    set(_NVCC_FLAGS "${_NVCC_FLAGS} -gencode arch=compute_89,code=sm_89")
    set(_NVCC_FLAGS "${_NVCC_FLAGS} -gencode arch=compute_89,code=compute_89")
endif ()
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} ${_NVCC_FLAGS}")

# --------------------------------------------------------------------------- #

file(GLOB PPLCV_CUDA_PUBLIC_HEADERS src/ppl/cv/cuda/*.h)
install(FILES ${PPLCV_CUDA_PUBLIC_HEADERS}
    DESTINATION include/ppl/cv/cuda)

list(APPEND PPLCV_COMPILE_DEFINITIONS PPLCV_USE_CUDA)

file(GLOB PPLCV_CUDA_SRC src/ppl/cv/cuda/*.cpp src/ppl/cv/cuda/utility/*.cpp)
file(GLOB PPLCV_CUDA_CU  src/ppl/cv/cuda/*.cu)
list(APPEND PPLCV_SRC ${PPLCV_CUDA_SRC} ${PPLCV_CUDA_CU})
list(APPEND PPLCV_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${CUDA_INCLUDE_DIRS}>)
list(APPEND PPLCV_LINK_LIBRARIES $<BUILD_INTERFACE:${CUDA_LIBRARIES}>)

# glog benchmark and unittest sources
file(GLOB PPLCV_CUDA_BENCHMARK_SRC src/ppl/cv/cuda/*_benchmark.cpp)
file(GLOB PPLCV_CUDA_UNITTEST_SRC src/ppl/cv/cuda/*_unittest.cpp)
list(APPEND PPLCV_BENCHMARK_SRC ${PPLCV_CUDA_BENCHMARK_SRC})
list(APPEND PPLCV_UNITTEST_SRC ${PPLCV_CUDA_UNITTEST_SRC})
