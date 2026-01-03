#!/bin/bash
# Apply CUDA memory check modifications to examples/cli/main.cpp
# and improve OOM error messages in ggml-cuda.cu
# Run this from the src directory after cloning

set -e

# First, fix ggml-cuda.cu to show "CUDA Out of Memory!" on OOM
CUDA_FILE="ggml/src/ggml-cuda/ggml-cuda.cu"
if [ -f "$CUDA_FILE" ]; then
    echo "Patching CUDA OOM error messages in $CUDA_FILE..."

    # 1. Change device info log from INFO to DEBUG (suppress by default)
    sed -i 's/GGML_LOG_INFO("  Device %d: %s, compute capability/GGML_LOG_DEBUG("  Device %d: %s, compute capability/g' "$CUDA_FILE"

    # 2. Replace the OOM error message to show "CUDA Out of Memory!" (using fprintf for direct stderr output)
    sed -i 's/GGML_LOG_ERROR("%s: allocating %.2f MiB on device %d: cudaMalloc failed: %s\\n", __func__, size \/ 1024.0 \/ 1024.0, buft_ctx->device, cudaGetErrorString(err));/fprintf(stderr, "CUDA Out of Memory!\\n"); fflush(stderr);/g' "$CUDA_FILE"

    # 3. Patch ggml_cuda_error to show "CUDA Out of Memory!" for memory errors
    sed -i 's/GGML_LOG_ERROR(GGML_CUDA_NAME " error: %s\\n", msg);/if (strstr(msg, "out of memory") != NULL || strstr(msg, "memory") != NULL) { fprintf(stderr, "CUDA Out of Memory!\\n"); } else { fprintf(stderr, "CUDA error: %s\\n", msg); } fflush(stderr);/g' "$CUDA_FILE"

    echo "CUDA OOM messages patched."
fi

FILE="examples/cli/main.cpp"

if [ ! -f "$FILE" ]; then
    echo "Error: $FILE not found"
    exit 1
fi

echo "Adding CUDA memory check feature to $FILE..."

# Create a temporary file with the modifications
TMP_FILE=$(mktemp)

# Process the file
awk '
# Add include after stable-diffusion.h
/#include "stable-diffusion.h"/ {
    print
    print ""
    print "// CUDA memory check uses cuda_runtime.h directly (included in function below)"
    next
}

# Add function after sd_log_cb closing brace
/^void sd_log_cb.*\{/ {
    in_log_cb = 1
}
in_log_cb && /^\}/ {
    print
    in_log_cb = 0
    print ""
    print "#ifdef SD_USE_CUDA"
    print "#include <cuda_runtime.h>"
    print "// Check if CUDA has enough memory using CUDA runtime directly"
    print "// This avoids triggering ggml_cuda_init which prints unwanted output"
    print "bool check_cuda_memory(size_t min_required_mb = 8192) {"
    print "    int device_count = 0;"
    print "    cudaError_t err = cudaGetDeviceCount(&device_count);"
    print "    if (err != cudaSuccess || device_count == 0) {"
    print "        return true;"
    print "    }"
    print "    for (int i = 0; i < device_count; i++) {"
    print "        cudaSetDevice(i);"
    print "        size_t free_mem = 0;"
    print "        size_t total_mem = 0;"
    print "        cudaMemGetInfo(&free_mem, &total_mem);"
    print "        size_t free_mb = free_mem / (1024 * 1024);"
    print "        size_t total_mb = total_mem / (1024 * 1024);"
    print "        if (free_mb < min_required_mb) {"
    print "            fprintf(stderr, \"CUDA Out of Memory!\\n\");"
    print "            fflush(stderr);"
    print "            exit(1);"
    print "        }"
    print "    }"
    print "    cudaDeviceReset();"
    print "    return true;"
    print "}"
    print "#endif"
    next
}

# Add function call after gen_params debug log
/LOG_DEBUG.*gen_params\.to_string/ {
    print
    print ""
    print "#ifdef SD_USE_CUDA"
    print "    check_cuda_memory();"
    print "#endif"
    next
}

{ print }
' "$FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$FILE"
echo "CUDA memory check feature added successfully."
