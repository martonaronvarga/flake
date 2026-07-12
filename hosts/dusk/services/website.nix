{
  infraNetwork,
  pkgs,
  ...
}: let
  siteRoot = pkgs.writeTextDir "index.html" ''
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Marton Aron Varga</title>
        <style>
          :root {
            color-scheme: light dark;
            font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: #111;
            color: #eee;
          }
          body {
            margin: 0;
            min-height: 100vh;
            display: grid;
            place-items: center;
          }
          main {
            width: min(680px, calc(100vw - 48px));
          }
          h1 {
            font-size: clamp(2rem, 6vw, 4rem);
            line-height: 1;
            margin: 0 0 1rem;
            font-weight: 700;
          }
          p {
            max-width: 42rem;
            margin: 0;
            color: #bbb;
            font-size: 1.125rem;
            line-height: 1.6;
          }
        </style>
      </head>
      <body>
        <main>
          <h1>Marton Aron Varga</h1>
          <p>This page is served from dusk over a WireGuard tunnel, with gloam acting as the public edge.</p>
        </main>
      </body>
    </html>
  '';
in {
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    virtualHosts."martonaronvarga.dev" = {
      listen = [
        {
          addr = infraNetwork.dusk.wireguard.address;
          port = infraNetwork.dusk.ports.website;
        }
      ];
      root = siteRoot;
      extraConfig = ''
        access_log off;
      '';
    };
  };

  networking.firewall.interfaces.${infraNetwork.wireguard.interface}.allowedTCPPorts = [
    infraNetwork.dusk.ports.website
  ];
}
