#!/usr/bin/env bash

MOUNTPOINT="/mnt"

set -e

#sudo -u nixos git clone https://github.com/vargamartonaron/flake

mkdir -p /etc/secureboot/keys/db

sudo -u nixos gpg -o db.pem -d flake/secrets/raw/db.pem.asc
sudo -u nixos gpg -o db.key -d flake/secrets/raw/db.key.asc

mv db.pem /etc/secureboot/keys/db/db.pem
mv db.key /etc/secureboot/keys/db/db.key

sudo chmod 400 /etc/secureboot

#sudo disko-main

sudo mkdir -p ${MOUNTPOINT}/persist/secrets/



sudo -u nixos gpg -o usu_ed25519 -d flake/secrets/raw/usu_ed25519.asc
mv usu_ed25519 ${MOUNTPOINT}/persist/secrets/usu_ed25519

# secrets folder not be accessible by anybody
chmod 700 "${MOUNTPOINT}"/persist/secrets/

nixos-install --flake "./flake#shade" --no-root-passwd --no-channel-copy
