#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../pbs-client-installer.sh
source "$REPO_ROOT/pbs-client-installer.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/os-release" <<'EOF'
ID=pop
ID_LIKE="ubuntu debian"
VERSION_ID="22.04"
PRETTY_NAME="Pop!_OS 22.04 LTS"
EOF

OS_RELEASE_FILE="$tmpdir/os-release" LSB_RELEASE_FILE="$tmpdir/missing-lsb-release" detect_distro

if [ "$OS" != "ubuntu" ]; then
    echo "Expected Pop!_OS to use the Ubuntu installer path, got OS=$OS" >&2
    exit 1
fi

if [ "${OS_ID:-}" != "pop" ]; then
    echo "Expected original OS_ID to remain 'pop', got OS_ID=${OS_ID:-unset}" >&2
    exit 1
fi

if [ "$OS_VERSION" != "22.04" ]; then
    echo "Expected VERSION_ID=22.04 to be preserved, got OS_VERSION=$OS_VERSION" >&2
    exit 1
fi

echo "Pop!_OS detection maps to Ubuntu installer path"
