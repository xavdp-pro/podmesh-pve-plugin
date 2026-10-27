# AI-First Installation & Proxmox VE Storage Configuration Protocol — `podmesh-pve-plugin` (v2.3.0)

> **Core Directive for Autonomous AI Agents**:
> `podmesh-pve-plugin` integrates `podmesh-meshfs` directly into the Proxmox VE Storage Subsystem (`pvesm`, `qm`, `pct`, `vzdump`).
> **Zero Proxmox Web GUI interaction is required**. AI agents install the Perl plugin, register the shared storage in `/etc/pve/storage.cfg`, reload Proxmox daemons, and provision/migrate VMs and LXC containers 100% via CLI.

---

## 1. Operational Invariants for AI Agents (`LAW.md`)

1. **Sanctuary Rule**: When qualifying or operating inside a nested Proxmox VE test cluster (e.g., `pve-cluster-a` / `pve-cluster-b`), NEVER install or alter storage configurations on the physical outer hypervisor host OS unless explicitly instructed.
2. **Prerequisite Daemon**: Every Proxmox VE node participating in the shared storage pool MUST have `podmesh-meshfs` (`meshfs.service` on `:7443` and/or `meshfs-p2p` on `/mnt/pve/<storage_id>`) active and healthy before enabling the storage in Proxmox VE.
3. **Rule 38 Bounded Retry ($k \le 2$)**: If `pvesm status` shows the storage as `inactive`, attempt at most $k \le 2$ corrective actions (verify `meshfs ping`, restart `pvestatd pvedaemon`) before halting fail-closed.

---

## 2. Step-by-Step AI Installation on Proxmox VE Nodes

### 2.1 Option A — Automated 1-Command CLI Installer (`bin/install-pve-plugin.sh`)

Run as `root` on each Proxmox VE node in the cluster:

```bash
./bin/install-pve-plugin.sh \
  --storage-id shared-meshfs \
  --server 127.0.0.1 \
  --port 7443 \
  --volume default \
  --path /mnt/pve/shared-meshfs \
  --shared 1 \
  --content images,rootdir,backup,iso,vztmpl,snippets
```

### 2.2 Option B — Debian Package Installation (`.deb`)

Build the `.deb` package and install it across all Proxmox VE cluster nodes:

```bash
./packaging/build-deb-pve-plugin.sh
dpkg -i dist/podmesh-pve-plugin_2.3.0_all.deb
```

### 2.3 Option C — Explicit Manual Deployment (For Granular AI Control)

1. **Install the Perl storage plugin**:
   ```bash
   install -d -m 0755 /usr/share/perl5/PVE/Storage/Custom
   install -m 0644 PVE/Storage/Custom/MeshFSPlugin.pm /usr/share/perl5/PVE/Storage/Custom/MeshFSPlugin.pm
   perl -c /usr/share/perl5/PVE/Storage/Custom/MeshFSPlugin.pm
   ```
2. **Prepare the mountpoint subdirectories on every node**:
   ```bash
   mkdir -p /mnt/pve/shared-meshfs/{images,dump,template/iso,template/cache,private,snippets}
   ```
3. **Register the storage in `/etc/pve/storage.cfg`** (once per cluster, as `/etc/pve` is replicated via `pmxcfs`):
   ```bash
   pvesm add meshfs shared-meshfs \
     --path /mnt/pve/shared-meshfs \
     --meshfs-server 127.0.0.1 \
     --meshfs-port 7443 \
     --meshfs-volume default \
     --shared 1 \
     --content images,rootdir,backup,iso,vztmpl,snippets
   ```
   *(Or use `dir: shared-meshfs` with `--shared 1` when backed by an active-active `meshfs-p2p` POSIX mount at `/mnt/pve/shared-meshfs`.)*
4. **Reload Proxmox VE storage daemons**:
   ```bash
   systemctl reload-or-restart pvedaemon pveproxy pvestatd
   ```

---

## 3. AI Verification & VM Lifecycle Commands

### 3.1 Verify Storage Status Across Cluster

```bash
pvesm status --storage shared-meshfs
```

Expected output:
```text
Name             Type     Status           Total            Used       Available        %
shared-meshfs  meshfs     active        20467712         1648640        17754112    8.05%
```

### 3.2 Provision a VM on Shared MeshFS Storage

```bash
qm create 9501 \
  --name meshfs-ha-vm \
  --memory 512 \
  --cores 1 \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci \
  --scsi0 shared-meshfs:1,format=raw \
  --ostype l26
```

### 3.3 Instant Merkle CoW Snapshot & Rollback

```bash
# Create snapshot
qm snapshot 9501 snap-ai-test --description "AI-First Merkle CoW Snapshot"

# Rollback to snapshot
qm rollback 9501 snap-ai-test

# Delete snapshot
qm delsnapshot 9501 snap-ai-test
```

### 3.4 Zero-Downtime Live Migration Across Proxmox Nodes

```bash
# Start VM on node A
qm start 9501

# Live-migrate VM to node B using shared MeshFS storage
qm migrate 9501 pve-cluster-b --online
```
