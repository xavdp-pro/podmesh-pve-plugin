# podmesh-pve-plugin (v2.4.0)

[**🤖 AI-First Install & Config**](AI_INSTALL_AND_CONFIG.md) · [Intent](INTENT.md) · [Law](LAW.md) · [Lineage](LINEAGE.md) · [Agents](AGENTS.md)

> **Official Proxmox VE Storage Plugin (`PVE::Storage::Custom::MeshFSPlugin`) for [`podmesh-meshfs`](https://github.com/xavdp-pro/podmesh-meshfs).**  
> *Sovereign, ultra-lightweight shared storage driver for Proxmox VE. Transitioning from the experimental v2.3.0 demonstrator into v2.4.0 universal multi-storage architecture (Proxmox VE + TrueNAS + Synology + Windows + Podman), with atomic chunk reception, FastCDC / BLAKE3, Merkle Copy-on-Write snapshots, and WireGuard Dual-Hub live VM/LXC migration without SPOF. 100% AI-First CLI installation and operation (see [`AI_INSTALL_AND_CONFIG.md`](AI_INSTALL_AND_CONFIG.md)).*

---

## 1. Overview & Value Proposition

In Proxmox VE virtualization clusters, shared distributed storage typically relies on **Ceph / CephFS**. While effective at large scale, Ceph introduces heavy RAM/CPU consumption (MON, OSD, MGR, MDS daemons), complex administration (CRUSH maps, placement groups), and quorum instability on 1-node or 2-node deployments.

`podmesh-pve-plugin` connects Proxmox VE natively to **[`podmesh-meshfs`](https://github.com/xavdp-pro/podmesh-meshfs)**, providing:
1. **Zero Bloat**: Interfaces with the `< 8 MB RAM` pure Rust `meshfs` daemon over local POSIX/FUSE mounts and HTTP REST (`:7443`).
2. **1-to-N Node Elasticity**: Works seamlessly on a single standalone Proxmox VE node and scales across multi-node clusters.
3. **4 MB SHA-256 Deduplication**: Every VM disk, LXC rootfs, template, and backup is deduplicated at the 4 MB CAS chunk layer.
4. **Instant Merkle CoW Snapshots**: Cryptographic Merkle tree snapshots triggered directly from the Proxmox VE Web UI or `qm snapshot` / `pct snapshot`.
5. **Online Live Migration (`shared 1`)**: Migrate running KVM virtual machines and LXC containers across Proxmox nodes without service interruption.

---

## 2. Architecture

```text
+-------------------------------------------------------------------+
|                        Proxmox VE Host                            |
|                                                                   |
|  [ Web GUI / API ]        [ qm / pct CLI ]       [ pvesm tool ]   |
|          \                       |                     /          |
|           +----------------------+--------------------+           |
|                                  |                                |
|                        PVE::Storage Core Engine                   |
|                                  |                                |
|              +-------------------+-------------------+            |
|              | PVE::Storage::Custom::MeshFSPlugin.pm |            |
|              +-------------------+-------------------+            |
|                                  |                                |
|          +-----------------------+-----------------------+        |
|          | Local POSIX / FUSE Path                       |        |
|          | /mnt/pve/meshfs/images/<vmid>/...             |        |
|          |                                               |        |
|          | REST API (HTTP 7443)                          |        |
|          | /api/v1/meshfs/status                         |        |
|          | /api/v1/meshfs/volumes                        |        |
|          | /api/v1/meshfs/snapshots                      |        |
+----------+-----------------------------------------------+--------+
                                   |
           +-----------------------+-----------------------+
           |         podmesh-meshfs Daemon (v2.4.0)        |
           |          (meshfs.service on port 7443)        |
           +-----------------------------------------------+
```

### Repository Layout

| Path | Description |
| :--- | :--- |
| `PVE/Storage/Custom/MeshFSPlugin.pm` | Proxmox VE Perl storage driver (`type => 'meshfs'`, `APIVER => 16` + dynamic `PVE::Storage::APIVER()`) |
| `bin/install-pve-plugin.sh` | Automated 1-click installer and `/etc/pve/storage.cfg` configurator |
| `packaging/build-deb-pve-plugin.sh` | Debian package builder (`podmesh-pve-plugin_2.4.0_all.deb`) |

---

## 3. Implemented Proxmox VE Storage Hooks

| Hook Method | Behavior |
| :--- | :--- |
| `type()` | Returns `'meshfs'` as the storage plugin identifier. |
| `api()` | Dynamically returns `PVE::Storage::APIVER()` (fallback `APIVER 16`). |
| `plugindata()` | Declares supported formats (`raw`, `qcow2`, `subvol`) and content types (`images`, `rootdir`, `backup`, `iso`, `vztmpl`, `snippets`). |
| `properties()` & `options()` | Configures `server`, `port`, `meshvolume`, `path`, `shared`, `content`, `nodes`, `mountoptions`. |
| `check_config()` | Defaults the local mountpoint to `/mnt/pve/<storage_id>` when omitted. |
| `activate_storage()` | Verifies `/api/v1/meshfs/status`, mounts FUSE if needed, and initializes Proxmox content directories. |
| `deactivate_storage()` | Cleanly unmounts the FUSE mountpoint when deactivated. |
| `status()` | Queries `/api/v1/meshfs/status` and `PVE::Tools::df` to return `(total, free, used, active)`. |
| `alloc_image()` | Allocates VM/LXC disk image and registers the volume via `POST /api/v1/meshfs/volumes`. |
| `free_image()` | Removes disk image and purges associated Merkle snapshots via `POST /api/v1/meshfs/snapshots/delete`. |
| `volume_has_feature()` | Declares native support for `snapshot`, `clone`, `copy`, and `template`. |
| `volume_snapshot()` | Triggers an instant Merkle snapshot (`POST /api/v1/meshfs/snapshots`) and `qemu-img snapshot -c`. |
| `volume_snapshot_delete()` | Deletes the Merkle snapshot and `qemu-img snapshot -d`. |
| `volume_snapshot_rollback()` | Rolls back disk state to the selected snapshot. |

---

## 4. Installation

### Option A: 1-Click Automated Installer

```bash
sudo ./bin/install-pve-plugin.sh --storage-id meshfs --server 127.0.0.1 --port 7443 --shared 1
```

### Option B: Build and Install the `.deb` Package

```bash
./packaging/build-deb-pve-plugin.sh
sudo dpkg -i dist/podmesh-pve-plugin_2.4.0_all.deb
```

### Option C: `/etc/pve/storage.cfg` Declaration

```text
meshfs: meshfs
	path /mnt/pve/meshfs
	server 127.0.0.1
	port 7443
	content images,rootdir,backup,iso,vztmpl,snippets
	shared 1
```

---

## 5. Operations & CLI Examples

```bash
# Verify storage status in Proxmox VE
pvesm status --storage meshfs

# Create a KVM VM with a 20 GiB QCOW2 disk on MeshFS
qm create 100 --name "vm-meshfs-demo" --memory 2048 --cores 2 --scsihw virtio-scsi-pci --scsi0 meshfs:20,format=qcow2

# Create, rollback, and delete a Merkle Copy-on-Write snapshot
qm snapshot 100 snap-pre-upgrade --description "Before kernel upgrade"
qm rollback 100 snap-pre-upgrade
qm delsnapshot 100 snap-pre-upgrade

# Live-migrate a running VM to another Proxmox node
qm migrate 100 pve2 --online
```

---

## Governance & Companion Repositories

- **Intent & Mandate**: [`INTENT.md`](INTENT.md)
- **Architectural Invariants**: [`LAW.md`](LAW.md)
- **Extraction Lineage**: [`LINEAGE.md`](LINEAGE.md)
- **Human–AI Tandem Instructions**: [`AGENTS.md`](AGENTS.md)
- **Dedication**: [`DEDICATION.md`](DEDICATION.md)
- **Storage Engine**: [`xavdp-pro/podmesh-meshfs`](https://github.com/xavdp-pro/podmesh-meshfs)
- **Qualification Lab**: [`xavdp-pro/podmesh-pve-plugin-lab`](https://github.com/xavdp-pro/podmesh-pve-plugin-lab) (private)

## License

Licensed under the Apache License, Version 2.0. See [`LICENSE`](LICENSE) for details.
