# Changelog

All notable changes to this project will be documented in this file.

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
