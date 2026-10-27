#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="podmesh-pve-plugin"
PKG_VERSION="2.3.0"
PKG_ARCH="all"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/build-${PKG_NAME}.XXXXXX)"
DIST_DIR="${ROOT_DIR}/dist"

echo "=== [PVE Plugin] Building Debian package: ${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb ==="

trap 'rm -rf "${BUILD_DIR}"' EXIT

mkdir -p "${BUILD_DIR}/DEBIAN"
mkdir -p "${BUILD_DIR}/usr/share/perl5/PVE/Storage/Custom"
mkdir -p "${BUILD_DIR}/usr/share/podmesh-pve-plugin/bin"
mkdir -p "${DIST_DIR}"

cp "${ROOT_DIR}/PVE/Storage/Custom/MeshFSPlugin.pm" "${BUILD_DIR}/usr/share/perl5/PVE/Storage/Custom/MeshFSPlugin.pm"
chmod 644 "${BUILD_DIR}/usr/share/perl5/PVE/Storage/Custom/MeshFSPlugin.pm"

cp "${ROOT_DIR}/bin/install-pve-plugin.sh" "${BUILD_DIR}/usr/share/podmesh-pve-plugin/bin/install-pve-plugin.sh"
chmod 755 "${BUILD_DIR}/usr/share/podmesh-pve-plugin/bin/install-pve-plugin.sh"

cat << EOF > "${BUILD_DIR}/DEBIAN/control"
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Section: admin
Priority: optional
Architecture: ${PKG_ARCH}
Depends: perl, libwww-perl, libjson-perl
Recommends: podmesh-meshfs (>= 2.3.0)
Maintainer: Xavier <xavier@xavdp.pro>
Description: Proxmox VE Storage Plugin for PodMesh MeshFS (v2.3.0)
 Official Proxmox VE storage driver (PVE::Storage::Custom::MeshFSPlugin)
 providing native KVM/QEMU and LXC storage integration, Merkle Copy-on-Write
 snapshots, and shared live-migration over PodMesh MeshFS 4MB CAS storage.
EOF

cat << 'EOF' > "${BUILD_DIR}/DEBIAN/postinst"
#!/usr/bin/env bash
set -e
if [ "$1" = "configure" ]; then
    if [ -d "/usr/share/perl5/PVE" ]; then
        ln -sf /usr/share/perl5/PVE/Storage/Custom/MeshFSPlugin.pm /usr/share/perl5/PVE/Storage/MeshFSPlugin.pm 2>/dev/null || true
        systemctl reload-or-restart pvedaemon pveproxy pvestatd 2>/dev/null || true
        echo "[podmesh-pve-plugin] Registered PVE::Storage::Custom::MeshFSPlugin and reloaded Proxmox VE daemons."
    fi
fi
exit 0
EOF
chmod 755 "${BUILD_DIR}/DEBIAN/postinst"

dpkg-deb --root-owner-group --build "${BUILD_DIR}" "${DIST_DIR}/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"
echo "[PVE Plugin] Package built: ${DIST_DIR}/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"
