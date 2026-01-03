#!/bin/bash
set -e

# Configuration
PKG_NAME="sd-cli-cuda"
PKG_VERSION="1.0.1"
PKG_ARCH="amd64"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/src"
BUILD_DIR="${SRC_DIR}/build"
DEB_BUILD_DIR="/tmp/sd-cpp-deb"
DEB_DIR="${DEB_BUILD_DIR}/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}"
OUTPUT_DIR="${SCRIPT_DIR}"

echo "=== Building stable-diffusion.cpp with CUDA support ==="

# Clean previous deb build
rm -rf "$DEB_BUILD_DIR"
mkdir -p "$DEB_BUILD_DIR"

# Clone repository fresh each time
echo "Cloning stable-diffusion.cpp (shallow)..."
rm -rf "$SRC_DIR"
git clone --depth 1 --recursive --shallow-submodules https://github.com/leejet/stable-diffusion.cpp "$SRC_DIR"

# Apply CUDA memory check modification
cd "$SRC_DIR"
"${SCRIPT_DIR}/apply-cuda-memory-check.sh"

# Build with CUDA
echo "Building with CUDA support..."
cd "$SRC_DIR"
rm -rf build && mkdir -p build && cd build
cmake .. -DSD_CUDA=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j$(nproc)

# Check what binaries were built
echo "Built binaries:"
ls -la bin/

# Create debian package structure
echo "Creating debian package structure..."
mkdir -p "${DEB_DIR}/DEBIAN"
mkdir -p "${DEB_DIR}/usr/bin"
mkdir -p "${DEB_DIR}/usr/lib/${PKG_NAME}"
mkdir -p "${DEB_DIR}/usr/share/doc/${PKG_NAME}"

# Copy binaries
cp bin/sd-cli "${DEB_DIR}/usr/bin/sd-cli"

# Make binaries executable
chmod 755 "${DEB_DIR}/usr/bin/"*

# Get CUDA library dependencies info
CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]*\.[0-9]*\).*/\1/')

# Create control file
cat > "${DEB_DIR}/DEBIAN/control" << EOF
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Section: graphics
Priority: optional
Architecture: ${PKG_ARCH}
Depends: libc6, libstdc++6, libgomp1, libcudart12, libcublas12, libcublaslt12
Suggests: nvidia-cuda-toolkit
Maintainer: Thomas Chung <tchung1970@gmail.com>
Description: Stable Diffusion inference with CUDA support
 stable-diffusion.cpp compiled with CUDA ${CUDA_VERSION} support.
 Includes sd-cli for command-line image generation.
 .
 Built from https://github.com/leejet/stable-diffusion.cpp
EOF

# Create copyright file
cat > "${DEB_DIR}/usr/share/doc/${PKG_NAME}/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: stable-diffusion.cpp
Source: https://github.com/leejet/stable-diffusion.cpp

Files: *
Copyright: 2023-2024 leejet and contributors
License: MIT
EOF

# Create postinst script
cat > "${DEB_DIR}/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Create symlink so wavespeed-desktop can find the binary
# wavespeed-desktop checks ~/.config/wavespeed-desktop/sd-bin/sd

# For each user with a home directory, create the symlink if wavespeed config exists
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        sd_bin_dir="$user_home/.config/wavespeed-desktop/sd-bin"

        # Only create if wavespeed-desktop config directory exists (app was used)
        # OR create the directory structure proactively
        mkdir -p "$sd_bin_dir"
        chown "$username:$username" "$user_home/.config/wavespeed-desktop" 2>/dev/null || true
        chown "$username:$username" "$sd_bin_dir" 2>/dev/null || true

        # Create/update symlink
        ln -sf /usr/bin/sd-cli "$sd_bin_dir/sd"
        chown -h "$username:$username" "$sd_bin_dir/sd" 2>/dev/null || true

        echo "Created symlink for user: $username"
    fi
done

# Also handle root user
mkdir -p /root/.config/wavespeed-desktop/sd-bin
ln -sf /usr/bin/sd-cli /root/.config/wavespeed-desktop/sd-bin/sd

echo ""
echo "sd-cli-cuda installed successfully!"
echo "Binary: /usr/bin/sd-cli"
echo "Symlinks created in ~/.config/wavespeed-desktop/sd-bin/sd"
echo ""

exit 0
EOF
chmod 755 "${DEB_DIR}/DEBIAN/postinst"

# Create prerm script (cleanup on removal)
cat > "${DEB_DIR}/DEBIAN/prerm" << 'EOF'
#!/bin/bash
set -e

# Remove symlinks created during install
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        sd_link="$user_home/.config/wavespeed-desktop/sd-bin/sd"
        if [ -L "$sd_link" ]; then
            rm -f "$sd_link"
        fi
    fi
done

# Remove root symlink
rm -f /root/.config/wavespeed-desktop/sd-bin/sd

exit 0
EOF
chmod 755 "${DEB_DIR}/DEBIAN/prerm"

# Create changelog
cat > "${DEB_DIR}/usr/share/doc/${PKG_NAME}/changelog.Debian" << EOF
${PKG_NAME} (${PKG_VERSION}) stable; urgency=medium

  * Initial release with CUDA ${CUDA_VERSION} support

 -- Thomas Chung <tchung1970@gmail.com>  $(date -R)
EOF
gzip -9 "${DEB_DIR}/usr/share/doc/${PKG_NAME}/changelog.Debian"

# Build the package
# Use xz compression (-Zxz) instead of default zstd for better compatibility
# zstd causes "not a Debian format archive" errors on older systems
echo "Building .deb package..."
cd "$DEB_BUILD_DIR"
dpkg-deb --build --root-owner-group -Zxz "${DEB_DIR}"

# Move to git repo directory
DEB_FILE="${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"
mv "${DEB_BUILD_DIR}/${DEB_FILE}" "${OUTPUT_DIR}/"

echo ""
echo "=== Build complete ==="
echo "Package: ${OUTPUT_DIR}/${DEB_FILE}"
echo ""
echo "Install with: sudo dpkg -i ${DEB_FILE}"
echo "Binaries will be installed to /usr/bin/sd-cli"

# Show package info
dpkg-deb --info "${OUTPUT_DIR}/${DEB_FILE}"
