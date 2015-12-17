#!/bin/sh

# Check if necessary tools are installed
command -v wget >/dev/null 2>&1 || { echo >&2 "Please install wget"; exit 1; }
command -v tar >/dev/null 2>&1 || { echo >&2 "Please install tar"; exit 1; }
command -v shasum >/dev/null 2>&1 || { echo >&2 "Please install shasum"; exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "Please install patch"; exit 1; }
command -v make >/dev/null 2>&1 || { echo >&2 "Please install make"; exit 1; }

# Installation
wget -nc http://mirrors.nycbug.org/pub/OpenBSD/OpenSSH/portable/openssh-6.9p1.tar.gz
#git clone -b V_6_9_P1 https://anongit.mindrot.org/openssh.git
tar xzf openssh-6.?p?.tar.gz

CHECKSUM=$(shasum -a 256 openssh-6.?p?.tar.gz)
if [ "$CHECKSUM" != "6e074df538f357d440be6cf93dc581a21f22d39e236f217fcd8eacbb6c896cfe  openssh-6.9p1.tar.gz" ]; then
  echo "Error: Checksum check failed!"
  exit 1
fi

cd openssh-6.?p?
patch -p1 < ../openssh.patch
./configure
make

