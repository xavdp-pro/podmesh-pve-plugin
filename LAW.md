# Law — podmesh-pve-plugin

The following architectural invariants govern `podmesh-pve-plugin` (v2.3.0):

## 1. Strict `PVE::Storage::Plugin` Contract Compliance
- `PVE::Storage::Custom::MeshFSPlugin` must inherit cleanly from `PVE::Storage::Plugin` and dynamically report `PVE::Storage::APIVER()` (with fallback to `APIVER => 16`) so Proxmox VE upgrades never break storage registration.
- The module must pass `perl -I/usr/share/perl5 -c PVE/Storage/Custom/MeshFSPlugin.pm` without syntax errors or undefined symbol imports.

## 2. Deterministic Activation & Health Verification
- `activate_storage()` and `status()` must verify live daemon readiness via `GET /api/v1/meshfs/status` (`ok == true`) before reporting the storage pool active or allocating images.
- If the local mountpoint `/mnt/pve/<storeid>` is unmounted and `/usr/bin/meshfs-mount` is present, activation mounts the target volume deterministically before initializing standard Proxmox subdirectories (`images`, `dump`, `template/iso`, `template/cache`, `snippets`).

## 3. Atomic Coordinated Merkle + QEMU Snapshots
- `volume_snapshot()` and `volume_snapshot_delete()` must synchronize the MeshFS Merkle snapshot API (`/api/v1/meshfs/snapshots` and `/api/v1/meshfs/snapshots/delete`) with local `qemu-img snapshot` state so VM disk state and CAS Merkle roots never diverge.

## 4. Zero Hardcoded Cluster Topology
- Storage parameters (`server`, `port`, `meshvolume`, `path`, `shared`, `content`) are read exclusively from `/etc/pve/storage.cfg` (defaulting to `127.0.0.1:7443` and `/mnt/pve/<sectionId>`). No private laboratory IP or credential is ever hardcoded in the plugin.
