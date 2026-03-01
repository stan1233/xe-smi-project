#!/bin/bash
# xe-smi installer

set -e

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="xe-smi"
SOURCE="$(cd "$(dirname "$0")" && pwd)/${SCRIPT_NAME}"

if [ ! -f "$SOURCE" ]; then
    echo "Error: ${SCRIPT_NAME} not found in current directory"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo ./install.sh"
    exit 1
fi

install -m 755 "$SOURCE" "${INSTALL_DIR}/${SCRIPT_NAME}"
echo "✓ Installed ${SCRIPT_NAME} to ${INSTALL_DIR}/${SCRIPT_NAME}"
echo ""
echo "Usage:"
echo "  sudo xe-smi        # Live monitoring"
echo "  sudo xe-smi -s     # Static snapshot"
echo "  sudo xe-smi -h     # Help"
