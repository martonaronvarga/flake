let
  domain = "martonaronvarga.dev";
in {
  inherit domain;
  mail = {
    sender = "martonaronvarga@gmail.com";
    alertRecipient = "szemgolyobis@gmail.com";
    aliases = map (local: "${local}@${domain}") [
      "admin"
      "contact"
      "git"
      "research"
    ];
  };

  network = {
    wireguard = {
      subnet = "10.200.200.0/24";
      interface = "wg0";
    };
    gloam = {
      publicIp = "129.159.11.56";
      sshUser = "ubuntu";
      wireguard = {
        address = "10.200.200.1";
        cidr = "10.200.200.1/24";
        port = 51820;
        publicKey = "kwwH2C4zxQ+tFyATlJJ7M8YG2XEvb9gtpthocK+4CGQ=";
      };
    };
    dusk = {
      wireguard = {
        address = "10.200.200.2";
        cidr = "10.200.200.2/32";
        publicKey = "5jfqQTM6Ms/JrcQLKOBFKT+LDWxlXv+NMj8fPG76iTI=";
      };
      ports = {
        website = 8080;
        vaultwarden = 8222;
        forgejo = 3001;
        grafana = 3000;
        prometheus = 9090;
        nodeExporter = 9100;
        matrix = 6167;
      };
    };
    shade = {
      wireguard = {
        address = "10.200.200.3";
        cidr = "10.200.200.3/32";
        publicKey = "/IvwqxIkfzB3DxDqeKzH2Wf5S5anky4Gdor6jvq4MA8=";
      };
      ports.nodeExporter = 9100;
    };
  };
}
