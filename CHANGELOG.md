# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2026-01-03

### Added
- CUDA memory check before image generation
  - Exits immediately with "CUDA Out of Memory!" when free GPU memory is below 4GB
  - Checks memory before any CUDA initialization to provide clean error messages

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
