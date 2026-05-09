# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2026-05-09

### Fixed
- CUDA memory pre-check now actually compiles and runs
  - Removed broken `#ifdef SD_USE_CUDA` guards: newer GGML uses `GGML_BACKEND_DL` which prevents `GGML_USE_CUDA` from being defined, so the entire check compiled to nothing
  - Changed `exit(1)` to `_Exit(1)` to bypass C++ destructors and prevent SIGABRT crash on early exit

### Changed
- Enhanced VRAM error output
  - Shows free/total VRAM in GB and the 8GB minimum requirement
  - Lists all GPU processes with PID, name, and VRAM usage via `nvidia-smi`
  - Includes `sudo pkill -f main.py` tip to free VRAM from ComfyUI
- Added zenity popup for detailed VRAM error info
  - Detail popup appears centered on screen when generation is blocked by low VRAM
  - Popup is fully detached from the sd-cli process (stderr redirect) so wavespeed-desktop updates immediately with `CUDA Out of Memory!` on close
  - `xdotool` installed automatically via postinst if not present

## [1.0.1] - 2026-01-03

### Added
- CUDA memory check before image generation
  - Exits immediately with "CUDA Out of Memory!" when free GPU memory is below 8GB
  - Checks memory before any CUDA initialization to provide clean error messages
  - Prevents silent failures that result in empty/blank images

### Changed
- Improved CUDA error messages for wavespeed-desktop integration
  - OOM errors now display "CUDA Out of Memory!" instead of technical device info
  - Suppressed verbose device info logs (moved to DEBUG level)
  - Error output goes directly to stderr for proper capture by wavespeed-desktop

## [1.0.0] - 2025-12-28

### Fixed
- Fixed deb package compatibility by using xz compression instead of zstd
  - `dpkg-deb` was using zstd compression by default which causes "not a Debian format archive" errors on some systems
  - Added `-Zxz` flag to force xz compression for better compatibility

### Added
- Initial release of sd-cli-cuda
- CUDA GPU acceleration for NVIDIA GPUs
- Auto-integration with wavespeed-desktop
- Z-Image support for local image generation
