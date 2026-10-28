# Lineage — podmesh-pve-plugin

## Universal Multi-Storage & Proxmox VE Plugin — v2.4.0 (2026-10-28)

- **Current Version**: `2.4.0`
- **Release Date**: `2026-10-28`
- **Extraction Origin (v2.3.0)**: Extracted from [`xavdp-pro/podmesh`](https://github.com/xavdp-pro/podmesh) (`packaging/proxmox/`) under the **SHAPER PHOENIX** modular architecture.
- **Companion Storage Engine**: [`xavdp-pro/podmesh-meshfs`](https://github.com/xavdp-pro/podmesh-meshfs) (`v2.4.0`)
- **Companion Lab Repository**: [`xavdp-pro/podmesh-pve-plugin-lab`](https://github.com/xavdp-pro/podmesh-pve-plugin-lab) (private)

## Evolution Summary

1. **v1.0–v2.0**: Developed inside `podmesh/packaging/proxmox` as `PVE::Storage::Custom::MeshFSPlugin`, adding dynamic `APIVER` detection, `PVE::JSONSchema` compatibility, and Merkle CoW snapshot hooks.
2. **v2.3.0 (2026-10-27)**: Extracted into standalone public repository `xavdp-pro/podmesh-pve-plugin` with dedicated Debian packaging (`podmesh-pve-plugin_2.3.0_all.deb`) and 1-click installer (`bin/install-pve-plugin.sh`).
3. **v2.4.0 (2026-10-28)**: Universal Multi-Storage Architecture Evolution:
   - **Sortie du démonstrateur expérimental v2.3.0** : intégration de production pour hyperviseurs Proxmox VE 8.x et 9.x.
   - **Entrée dans l'ère multi-plateformes universelle** : interopérabilité directe entre clusters Proxmox VE et stockages distribués unifiés (TrueNAS, Synology, Windows, Podman).
   - **Support FastCDC / BLAKE3 & Réception atomique des chunks** : alignement complet avec le moteur CAS MeshFS v2.4.0 pour une absence totale de corruption ou de déchirement d'écriture sur disques VM / conteneurs LXC.
   - **Topologie WireGuard Dual-Hub sans SPOF** : réplication transparente inter-nœuds Proxmox VE et migration à chaud sur liens redondés.
