// Automatically generated header file for caffe2 macros. These
// macros are used to build the Caffe2 binary, and if you are
// building a dependent library, they will need to be set as well
// for your program to link correctly.

#pragma once

/* #undef CAFFE2_BUILD_SHARED_LIBS */
/* #undef CAFFE2_FORCE_FALLBACK_CUDA_MPI */
/* #undef CAFFE2_HAS_MKL_DNN */
/* #undef CAFFE2_HAS_MKL_SGEMM_PACK */
/* #undef CAFFE2_PERF_WITH_AVX */
/* #undef CAFFE2_PERF_WITH_AVX2 */
/* #undef CAFFE2_THREADPOOL_MAIN_IMBALANCE */
/* #undef CAFFE2_THREADPOOL_STATS */
/* #undef CAFFE2_USE_ACCELERATE */
/* #undef CAFFE2_USE_CUDNN */
/* #undef CAFFE2_USE_EIGEN_FOR_BLAS */
/* #undef CAFFE2_USE_FBCODE */
/* #undef CAFFE2_USE_GOOGLE_GLOG */
/* #undef CAFFE2_USE_LITE_PROTO */
/* #undef CAFFE2_USE_MKL */
/* #undef USE_MKLDNN */
/* #undef CAFFE2_USE_NVTX */
/* #undef CAFFE2_USE_ITT */

#ifndef EIGEN_MPL2_ONLY
#define EIGEN_MPL2_ONLY
#endif

// Useful build settings that are recorded in the compiled binary
// torch.__build__.show()
#define CAFFE2_BUILD_STRINGS { \
  {"TORCH_VERSION", "2.8.0"}, \
  {"CXX_COMPILER", "/usr/bin/g++"}, \
  {"CXX_FLAGS", "-fobjc-arc -ffunction-sections -fdata-sections -fvisibility-inlines-hidden -DUSE_PTHREADPOOL -DUSE_PYTORCH_QNNPACK -DUSE_XNNPACK -DBUILD_LITE_INTERPRETER -DSYMBOLICATE_MOBILE_DEBUG_HANDLE -O2 -fPIC -DC10_NODEPRECATED -Wall -Wextra -Werror=return-type -Werror=non-virtual-dtor -Werror=braced-scalar-init -Werror=range-loop-construct -Werror=bool-operation -Wnarrowing -Wno-missing-field-initializers -Wno-unknown-pragmas -Wno-unused-parameter -Wno-strict-overflow -Wno-strict-aliasing -Wvla-extension -Wsuggest-override -Wnewline-eof -Winconsistent-missing-override -Winconsistent-missing-destructor-override -Wno-pass-failed -Wno-error=old-style-cast -Wconstant-conversion -Qunused-arguments -fcolor-diagnostics -faligned-new -fno-math-errno -fno-trapping-math -Werror=format -Wno-missing-braces"}, \
  {"BUILD_TYPE", "MinSizeRel"}, \
  {"BLAS_INFO", "veclib"}, \
  {"LAPACK_INFO", "accelerate"}, \
  {"USE_CUDA", "OFF"}, \
  {"USE_ROCM", "OFF"}, \
  {"CUDA_VERSION", ""}, \
  {"ROCM_VERSION", ""}, \
  {"USE_CUDNN", "OFF"}, \
  {"COMMIT_SHA", "3c87529d231ac4cef5f032af51f29d9238a7de64"}, \
  {"CUDNN_VERSION", ""}, \
  {"USE_NCCL", "OFF"}, \
  {"USE_MPI", "OFF"}, \
  {"USE_GFLAGS", "OFF"}, \
  {"USE_GLOG", "OFF"}, \
  {"USE_GLOO", "OFF"}, \
  {"USE_NNPACK", "OFF"}, \
  {"USE_OPENMP", "OFF"}, \
  {"FORCE_FALLBACK_CUDA_MPI", ""}, \
  {"HAS_MKL_DNN", ""}, \
  {"HAS_MKL_SGEMM_PACK", ""}, \
  {"PERF_WITH_AVX", ""}, \
  {"PERF_WITH_AVX2", ""}, \
  {"USE_ACCELERATE", ""}, \
  {"USE_EIGEN_FOR_BLAS", ""}, \
  {"USE_LITE_PROTO", ""}, \
  {"USE_MKL", ""}, \
  {"USE_MKLDNN", "OFF"}, \
  {"USE_NVTX", ""}, \
  {"USE_ITT", ""}, \
  {"USE_ROCM_KERNEL_ASSERT", "OFF"}, \
  {"USE_CUSPARSELT", "OFF"}, \
}
