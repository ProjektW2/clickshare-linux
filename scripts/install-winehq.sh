#!/bin/sh
# Installs current stable Wine from the official WineHQ repository.
# Distribution Wine packages are often far too old (Ubuntu 22.04 ships 6.0,
# which crashes the ClickShare app).
#
# Supports Ubuntu and derivatives (Pop!_OS, Linux Mint, ...). For other
# distributions see https://gitlab.winehq.org/wine/wine/-/wikis/Download
#
# Usage: sudo sh scripts/install-winehq.sh
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root: sudo sh $0" >&2
    exit 1
fi

. /etc/os-release
CODENAME=${UBUNTU_CODENAME:-$VERSION_CODENAME}
if [ -z "$CODENAME" ]; then
    echo "Could not determine the Ubuntu codename." >&2
    exit 1
fi
echo "Using WineHQ repository for '$CODENAME'"

dpkg --add-architecture i386
mkdir -pm755 /etc/apt/keyrings
curl -fsSL -o /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
curl -fsSL -o "/etc/apt/sources.list.d/winehq-$CODENAME.sources" \
    "https://dl.winehq.org/wine-builds/ubuntu/dists/$CODENAME/winehq-$CODENAME.sources"

apt-get update
apt-get install -y --install-recommends winehq-stable

wine --version
