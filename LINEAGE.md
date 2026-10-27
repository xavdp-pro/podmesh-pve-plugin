# Lineage — podmesh-pve-plugin

## Extraction & Modular Separation — v2.3.0 (2026-10-27)

- **Extracted Version**: `2.3.0`
- **Extraction Date**: `2026-10-27`
- **Upstream Source**: Extracted from [`xavdp-pro/podmesh`](https://github.com/xavdp-pro/podmesh) (`packaging/proxmox/`) under the **SHAPER PHOENIX** modular architecture.
- **Companion Storage Engine**: [`xavdp-pro/podmesh-meshfs`](https://github.com/xavdp-pro/podmesh-meshfs) (`v2.3.0`)
- **Companion Lab Repository**: [`xavdp-pro/podmesh-pve-plugin-lab`](https://github.com/xavdp-pro/podmesh-pve-plugin-lab) (private)

## Evolution Summary

1. **v1.0–v2.0**: Developed inside `podmesh/packaging/proxmox` as `PVE::Storage::Custom::MeshFSPlugin`, adding dynamic `APIVER` detection, `PVE::JSONSchema` compatibility, and Merkle CoW snapshot hooks.
2. **v2.3.0 (2026-10-27)**: Extracted into standalone public repository `xavdp-pro/podmesh-pve-plugin` with dedicated Debian packaging (`podmesh-pve-plugin_2.3.0_all.deb`) and 1-click installer (`bin/install-pve-plugin.sh`).
