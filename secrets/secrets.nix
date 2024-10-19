let
  usu =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHlpRMbmc5c/qQA9Nb9CSov4DD4f8B+hAJ5ZH/0sRgwA usu@shade";

  shade =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDQXBIxdgUYifXrPJ6ttAYMquKgduASBmb36r8v7kK5D root@shade";

in { 
  "usu-pw.age".publicKeys = [ usu shade ];
  "secureboot/db_key.age".publicKeys = [ usu shade ];
  "secureboot/db_cert.age".publicKeys = [ usu shade ];
  "secureboot/KEK_key.age".publicKeys = [ usu shade ];
  "secureboot/KEK_cert.age".publicKeys = [ usu shade ];
  "secureboot/PK_key.age".publicKeys = [ usu shade ];
  "secureboot/PK_cert.age".publicKeys = [ usu shade ];
  "secureboot/GUID.age".publicKeys = [ usu shade ];
}
