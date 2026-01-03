#!/bin/bash
# Apply CUDA memory check modifications to examples/cli/main.cpp
# Run this from the src directory after cloning

set -e

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
    print "#ifdef SD_USE_CUDA"
    print "#include \"ggml-cuda.h\""
    print "#endif"
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
    print "// Check if CUDA has enough memory, warn user if not"
    print "bool check_cuda_memory(size_t min_required_mb = 4096) {"
    print "    int device_count = ggml_backend_cuda_get_device_count();"
    print "    if (device_count == 0) {"
    print "        return true;"
    print "    }"
    print "    for (int i = 0; i < device_count; i++) {"
    print "        size_t free_mem = 0;"
    print "        size_t total_mem = 0;"
    print "        ggml_backend_cuda_get_device_memory(i, &free_mem, &total_mem);"
    print "        char description[256];"
    print "        ggml_backend_cuda_get_device_description(i, description, sizeof(description));"
    print "        size_t free_mb = free_mem / (1024 * 1024);"
    print "        size_t total_mb = total_mem / (1024 * 1024);"
    print "        size_t used_mb = total_mb - free_mb;"
    print "        LOG_INFO(\"CUDA device %d: %s\", i, description);"
    print "        LOG_INFO(\"  Memory: %zu MB free / %zu MB total (%zu MB used)\", free_mb, total_mb, used_mb);"
    print "        if (free_mb < min_required_mb) {"
    print "            LOG_ERROR(\"CUDA device %d has only %zu MB free memory!\", i, free_mb);"
    print "            LOG_ERROR(\"Stable Diffusion requires at least %zu MB of GPU memory.\", min_required_mb);"
    print "            LOG_ERROR(\"Please close GPU-intensive applications to free up memory:\");"
    print "            LOG_ERROR(\"  - ComfyUI, Other AI/ML applications, Video editors\");"
    print "            LOG_ERROR(\"To kill ComfyUI: pkill -f comfyui || pkill -f ComfyUI\");"
    print "            exit(1);"
    print "        }"
    print "    }"
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
