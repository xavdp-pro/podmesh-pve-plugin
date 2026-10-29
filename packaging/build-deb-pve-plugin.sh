#!/usr/bin/env bash
# =============================================================================
# PodMesh Proxmox VE Storage Plugin v2.4.0 — Debian 13 / PVE 9.x Builder
# Hardened under Claude Fable 5.1 & GPT-6 Astra Counter-Reviews:
#  - Enforces 0755 on ./ and all structural directories (fixes mktemp -d 0700 bug)
#  - Reversible postinst / prerm / postrm for PVE daemon reload
#  - Reproducible SHA-256 build via SOURCE_DATE_EPOCH
# =============================================================================
set -euo pipefail
umask 0022

PKG_NAME="podmesh-pve-plugin"
PKG_VERSION="2.4.1"
PKG_ARCH="all"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/build-${PKG_NAME}.XXXXXX)"
DIST_DIR="${ROOT_DIR}/dist"

echo "=== [PVE Plugin] Building Debian 13 / PVE 9.x package: ${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb ==="

trap 'rm -rf "${BUILD_DIR}"' EXIT

chmod 0755 "${BUILD_DIR}"
mkdir -p -m 0755 "${BUILD_DIR}/DEBIAN"
mkdir -p -m 0755 "${BUILD_DIR}/usr" "${BUILD_DIR}/usr/share" "${BUILD_DIR}/usr/share/perl5" \
  "${BUILD_DIR}/usr/share/perl5/PVE" "${BUILD_DIR}/usr/share/perl5/PVE/Storage" \
  "${BUILD_DIR}/usr/share/perl5/PVE/Storage/Custom"
mkdir -p -m 0755 "${BUILD_DIR}/usr/share/podmesh-pve-plugin" "${BUILD_DIR}/usr/share/podmesh-pve-plugin/bin"
mkdir -p "${DIST_DIR}"

install -m 0644 "${ROOT_DIR}/PVE/Storage/Custom/MeshFSPlugin.pm" \
  "${BUILD_DIR}/usr/share/perl5/PVE/Storage/Custom/MeshFSPlugin.pm"
install -m 0755 "${ROOT_DIR}/bin/install-pve-plugin.sh" \
  "${BUILD_DIR}/usr/share/podmesh-pve-plugin/bin/install-pve-plugin.sh"

INSTALLED_SIZE="$(du -sk "${BUILD_DIR}" | awk '{print $1}')"

cat << EOF > "${BUILD_DIR}/DEBIAN/control"
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Section: admin
Priority: optional
Architecture: ${PKG_ARCH}
Installed-Size: ${INSTALLED_SIZE}
Depends: perl, libwww-perl, libjson-perl
Recommends: podmesh-meshfs (>= 2.4.0)
Maintainer: Xavier DP <xavier@xavdp.pro>
Homepage: https://meshfs.xavdp.pro
Description: Proxmox VE Storage Plugin for PodMesh MeshFS (v2.4.0)
 Official Proxmox VE storage driver (PVE::Storage::Custom::MeshFSPlugin)
 providing native KVM/QEMU and LXC storage integration, Merkle Copy-on-Write
 snapshots, and shared live-migration over PodMesh MeshFS 4MB CAS storage.
EOF
chmod 0644 "${BUILD_DIR}/DEBIAN/control"

cat << 'EOF' > "${BUILD_DIR}/DEBIAN/postinst"
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = "configure" ]; then
    if [ -d "/usr/share/perl5/PVE" ]; then
        ln -sf /usr/share/perl5/PVE/Storage/Custom/MeshFSPlugin.pm /usr/share/perl5/PVE/Storage/MeshFSPlugin.pm 2>/dev/null || true
        if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
            systemctl try-reload-or-restart pvedaemon pveproxy pvestatd 2>/dev/null || true
        fi
        echo "[podmesh-pve-plugin] Registered PVE::Storage::Custom::MeshFSPlugin (v2.4.0) and reloaded Proxmox VE daemons."
    fi
fi
exit 0
EOF
chmod 0755 "${BUILD_DIR}/DEBIAN/postinst"

cat << 'EOF' > "${BUILD_DIR}/DEBIAN/prerm"
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = "remove" ] || [ "${1:-}" = "deconfigure" ]; then
    rm -f /usr/share/perl5/PVE/Storage/MeshFSPlugin.pm 2>/dev/null || true
    if [ -f /usr/share/perl5/PVE/Storage.pm ]; then
        sed -i '/use PVE::Storage::Custom::MeshFSPlugin;/d' /usr/share/perl5/PVE/Storage.pm || true
        sed -i '/PVE::Storage::Custom::MeshFSPlugin->register();/d' /usr/share/perl5/PVE/Storage.pm || true
    fi
fi
exit 0
EOF
chmod 0755 "${BUILD_DIR}/DEBIAN/prerm"

cat << 'EOF' > "${BUILD_DIR}/DEBIAN/postrm"
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = "remove" ] || [ "${1:-}" = "purge" ]; then
    if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
        systemctl try-reload-or-restart pvedaemon pveproxy pvestatd 2>/dev/null || true
    fi
fi
exit 0
EOF
chmod 0755 "${BUILD_DIR}/DEBIAN/postrm"

find "${BUILD_DIR}" -type d -exec chmod 0755 {} +

if git -C "${ROOT_DIR}" rev-parse HEAD >/dev/null 2>&1; then
    export SOURCE_DATE_EPOCH="$(git -C "${ROOT_DIR}" log -1 --format=%ct)"
else
    export SOURCE_DATE_EPOCH="1793100000"
fi
find "${BUILD_DIR}" -exec touch -h -d "@${SOURCE_DATE_EPOCH}" {} +

DEB_OUT="${DIST_DIR}/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"
dpkg-deb --root-owner-group -Zxz --build "${BUILD_DIR}" "${DEB_OUT}"

ROOT_PERM="$(dpkg-deb -c "${DEB_OUT}" | awk '$6 == "./" {print $1}')"
if [ "${ROOT_PERM}" != "drwxr-xr-x" ]; then
    echo "FATAL [Invariant Breach]: ${DEB_OUT} root dir is ${ROOT_PERM}" >&2
    exit 1
fi

sha256sum "${DEB_OUT}" > "${DIST_DIR}/SHA256SUMS"
echo "[PVE Plugin] Package built & verified: ${DEB_OUT}"
cat "${DIST_DIR}/SHA256SUMS"
