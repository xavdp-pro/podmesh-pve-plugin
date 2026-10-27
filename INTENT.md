# Intent — podmesh-pve-plugin

Provide the native Proxmox VE storage plugin (`PVE::Storage::Custom::MeshFSPlugin`) connecting Proxmox VE hypervisors (`pvesm`, `qm`, `pct`, `pvedaemon`, `pveproxy`, `pvestatd`) to the [`podmesh-meshfs`](https://github.com/xavdp-pro/podmesh-meshfs) 4 MB Content-Addressable Storage (CAS) and Merkle Copy-on-Write snapshot engine.

## Purpose and Architectural Role

In sovereign, edge, and 1-to-N node Proxmox VE clusters, Ceph/CephFS imposes high memory overhead, operational complexity, and strict three-node quorum constraints. `podmesh-pve-plugin` bridges Proxmox VE's native `PVE::Storage::Plugin` architecture (API version 16, dynamic `PVE::Storage::APIVER()` compatibility across PVE 7.x, 8.x, and 9.x) directly to `podmesh-meshfs`.

It enables:
- Full lifecycle management of KVM virtual machine disks (`raw`, `qcow2`), LXC container root filesystems (`subvol`), VZDump backups, ISOs, templates, and Cloud-Init snippets.
- Instantaneous cryptographic Merkle tree Copy-on-Write snapshots (`POST /api/v1/meshfs/snapshots`) coordinated with `qemu-img` internal consistency.
- Shared cluster storage semantics (`shared 1`) supporting zero-downtime live migration (`qm migrate --online`) across Proxmox VE nodes.

## Interface and Authority

- `podmesh-pve-plugin` acts solely as a Proxmox VE storage driver translating `PVE::Storage` hooks into local POSIX/FUSE operations under `/mnt/pve/<storage_id>` and HTTP REST calls (`http://127.0.0.1:7443/api/v1/meshfs/*`).
- It holds no cluster governance authority and never embeds private host credentials or topology defaults.
- All hardware qualification evidence and PVE storage test records reside in the private companion repository [`xavdp-pro/podmesh-pve-plugin-lab`](https://github.com/xavdp-pro/podmesh-pve-plugin-lab).
