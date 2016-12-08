#!/usr/bin/env bash

OPENSSH_VER='7.3p1'
ARCHIVE_SHA_256='3ffb989a6dcaa69594c3b550d4855a5a2e1718ccdde7f5e36387b424220fbecc'

# Check if necessary tools are installed
command -v wget >/dev/null 2>&1 || { echo >&2 "Please install wget"; exit 1; }
command -v tar >/dev/null 2>&1 || { echo >&2 "Please install tar"; exit 1; }
command -v shasum >/dev/null 2>&1 || { echo >&2 "Please install shasum"; exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "Please install patch"; exit 1; }
command -v make >/dev/null 2>&1 || { echo >&2 "Please install make"; exit 1; }

# Installation
wget -nc "http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VER}.tar.gz"
#git clone -b V_6_9_P1 https://anongit.mindrot.org/openssh.git

CHECKSUM=$(shasum -a 256 "openssh-${OPENSSH_VER}.tar.gz")
if [ "$CHECKSUM" != "$ARCHIVE_SHA_256  openssh-${OPENSSH_VER}.tar.gz" ]; then
  echo "Error: Checksum verification failed!"
  exit 1
fi

tar xzf "openssh-${OPENSSH_VER}.tar.gz"
cd openssh-"$OPENSSH_VER"
patch -p1 < ../openssh.patch
./configure
make

