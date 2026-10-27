# Agents — podmesh-pve-plugin

> **🤖 AI-First Installation & Configuration Mandate**:
> `podmesh-pve-plugin` is deployed, registered in `/etc/pve/storage.cfg`, and operated 100% via CLI (`bin/install-pve-plugin.sh`, `pvesm`, `qm`, `pct`) without requiring the Proxmox Web GUI.
> 👉 **Autonomous AI Agents: Read [`AI_INSTALL_AND_CONFIG.md`](AI_INSTALL_AND_CONFIG.md) first for deterministic Proxmox VE deployment and verification protocols.**

`podmesh-pve-plugin` follows the SHAPER PHOENIX two-repository + vault discipline. All committed files and documentation must be written in English (`en-US`).

| Where | What belongs there | What never goes there |
| --- | --- | --- |
| **`xavdp-pro/podmesh-pve-plugin`** (this repository, public) | `PVE/Storage/Custom/MeshFSPlugin.pm`, 1-click installer (`bin/install-pve-plugin.sh`), Debian packaging (`packaging/build-deb-pve-plugin.sh`), user & architecture documentation, canonical governance (`INTENT.md`, `LAW.md`, `LINEAGE.md`, `AGENTS.md`, `DEDICATION.md`) | Laboratory Proxmox host IPs, VM qualification logs, private credentials |
| **`xavdp-pro/podmesh-pve-plugin-lab`** (private companion) | Proxmox VE `pvesm`/`qm`/`pct` qualification records, live-migration and snapshot test logs, lab topology maps | Signing keys, root passwords, SSH private keys |
| **The vault** | Signing keys, credentials, private tokens | — |

## Verification Checklist for Agents

1. Validate Perl syntax when modifying `PVE/Storage/Custom/MeshFSPlugin.pm`:
   ```bash
   perl -c PVE/Storage/Custom/MeshFSPlugin.pm
   ```
   *(Note: on non-PVE hosts without `PVE::Storage::Plugin` installed, test syntax in a PVE container/host or verify package build with `./packaging/build-deb-pve-plugin.sh`.)*
2. Keep REST API endpoints (`/api/v1/meshfs/status`, `/api/v1/meshfs/volumes`, `/api/v1/meshfs/snapshots`, `/api/v1/meshfs/snapshots/delete`) strictly aligned with [`xavdp-pro/podmesh-meshfs`](https://github.com/xavdp-pro/podmesh-meshfs).
