#!/usr/bin/env bash

MOUNTPOINT="/mnt"

set -e

sudo -u nixos git clone https://github.com/vargamartonaron/flake


# Create secureboot keys
agenix -d /flake/secrets/secureboot/GUID.age -o /etc/secureboot/GUID
agenix -d /flake/secrets/secureboot/KEK_key.age -o /etc/secureboot/KEK.key
agenix -d /flake/secrets/secureboot/PK_cert.age -o /etc/secureboot/PK_cert.pem
agenix -d /flake/secrets/secureboot/PK_key.age -o /etc/secureboot/PK.key
agenix -d /flake/secrets/secureboot/db_cert.age -o /etc/secureboot/db_cert.pem
agenix -d /flake/secrets/secureboot/db_key.age -o /etc/secureboot/db.key

chmod 400 /etc/secureboot

disko-main

mkdir -p ${MOUNTPOINT}/persist/secrets/

mv flake/secrets/*.age "${MOUNTPOINT}"/persist/secrets/

# secrets folder not be accessible by anybody
chmod 700 "${MOUNTPOINT}"/persist/secrets/

nixos-install --flake "./flake#shade" --no-root-passwd --no-channel-copy
