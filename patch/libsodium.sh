#!/bin/bash

# If you suppose your server supports chacha and salsa,
# this script must be run.

wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.11.tar.gz
tar xvzf libsodium-1.0.11.tar.gz
cd libsodium-1.0.11
./configure
make
make install
cd ..

echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig
