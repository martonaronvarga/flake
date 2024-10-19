#!/usr/bin/env bash

MOUNTPOINT="/mnt"

set -e

sudo -u nixos git clone https://github.com/vargamartonaron/flake

# Create secureboot keys
agenix -d /mnt/secrets/GUID.age -o /etc/secureboot/GUID
agenix -d /mnt/secrets/KEK_key.age -o /etc/secureboot/KEK.key
agenix -d /mnt/secrets/PK_cert.age -o /etc/secureboot/PK_cert.pem
agenix -d /mnt/secrets/PK_key.age -o /etc/secureboot/PK.key
agenix -d /mnt/secrets/db_cert.age -o /etc/secureboot/db_cert.pem
agenix -d /mnt/secrets/db_key.age -o /etc/secureboot/db.key

chmod 400 /etc/secureboot

disko-main

mkdir -p ${MOUNTPOINT}/persist/secrets/

mv flake/secrets/*.age "${MOUNTPOINT}"/persist/secrets/

# secrets folder not be accessible by anybody
chmod 700 "${MOUNTPOINT}"/persist/secrets/

nixos-install --flake "./flake#shade" --no-root-passwd --no-channel-copy
