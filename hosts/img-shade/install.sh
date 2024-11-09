#!/usr/bin/env bash

MOUNTPOINT="/mnt"

set -e

#sudo -u nixos git clone https://github.com/vargamartonaron/flake

mkdir -p /etc/secureboot/


sudo chmod 400 /etc/secureboot

#sudo disko-main

sudo mkdir -p ${MOUNTPOINT}/persist/secrets/

# secrets folder not be accessible by anybody
chmod 700 "${MOUNTPOINT}"/persist/secrets/

nixos-install --flake "./flake#shade" --no-root-passwd --no-channel-copy
