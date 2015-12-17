#!/bin/sh

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

