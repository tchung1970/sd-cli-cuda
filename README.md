# sd-cli-cuda

CUDA-accelerated Stable Diffusion backend for [wavespeed-desktop](https://github.com/WaveSpeedAI/wavespeed-desktop).

## Overview

This is a **modular plugin** designed to add CUDA GPU acceleration to wavespeed-desktop on any Linux system with an NVIDIA GPU such as RTX 4000 Ada Generation.

The package provides [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp) compiled with CUDA support, enabling high-performance local image generation through wavespeed-desktop with Z-Image for local image generation.

### How It Works

1. **Standalone binary**: Installs `sd-cli` to `/usr/bin/`
2. **Auto-integration**: Creates symlink at `~/.config/wavespeed-desktop/sd-bin/sd` for wavespeed-desktop to detect
3. **Modular design**: wavespeed-desktop automatically uses the CUDA backend when available

### Build Process

The build script:
1. Clones the latest stable-diffusion.cpp source
2. Compiles with CUDA GPU acceleration
3. Packages into a `.deb` file for easy installation on Debian/Ubuntu systems

## Prerequisites

### System Requirements
- Debian/Ubuntu-based Linux distribution such as Ubuntu 24.04 LTS
- NVIDIA GPU with CUDA support such as RTX 4000 Ada Generation

### Build Dependencies

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    nvidia-cuda-toolkit \
    dpkg-dev
```

### Runtime Dependencies
- `libc6`
- `libstdc++6`
- `libgomp1`
- NVIDIA drivers (with CUDA support)

## Building

```bash
./build.sh
```

The script will:
1. Clone stable-diffusion.cpp to `./src/` (shallow clone)
2. Build with CUDA enabled using all available CPU cores
3. Create `sd-cli-cuda_amd64.deb` in the repo root

Build time: ~3-5 minutes depending on hardware.

## Installation

```bash
sudo dpkg -i sd-cli-cuda_amd64.deb
```

### What Gets Installed

| Path | Description |
|------|-------------|
| `/usr/bin/sd-cli` | Command-line image generation tool |
| `~/.config/wavespeed-desktop/sd-bin/sd` | Symlink to sd-cli (for wavespeed-desktop integration) |

After installation, wavespeed-desktop will automatically detect and use the CUDA backend for GPU-accelerated image generation.

## Uninstallation

```bash
sudo dpkg -r sd-cli-cuda
```

## Usage

### With wavespeed-desktop (Recommended)

Simply install the package - wavespeed-desktop will automatically detect and use the CUDA backend. No additional configuration required.

### sd-cli (Standalone Command Line)

See [example.txt](example.txt) for a complete command-line example using wavespeed-desktop model paths.

Sample output (generated on NVIDIA RTX 4000 Ada Generation):

![output.png](output.png)

## Package Details

| Field | Value |
|-------|-------|
| Package Name | sd-cli-cuda |
| Version | 1.0.0 |
| Architecture | amd64 |
| Maintainer | WaveSpeed |
| License | MIT (upstream) |
| Source | https://github.com/leejet/stable-diffusion.cpp |

## Troubleshooting

### CUDA not found during build
Ensure CUDA toolkit is installed:
```bash
nvcc --version
```

### GPU not detected at runtime
Check NVIDIA driver:
```bash
nvidia-smi
```

### Out of VRAM
Try reducing image dimensions or use a quantized model (.gguf).

## Related Projects

- [wavespeed-desktop](https://github.com/WaveSpeedAI/wavespeed-desktop) - Desktop application for local AI image generation
- [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp) - Upstream C++ implementation

## License

sd-cli-cuda is licensed under MIT License.

stable-diffusion.cpp is licensed under MIT License.
