{
  pkgs,
  inputs,
  ...
}: let
  pkgs-mesa = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  hardware.cpu = {intel.updateMicrocode = true;};

  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
    package = pkgs-mesa.mesa;
    enable32Bit = true;
    package32 = pkgs-mesa.pkgsi686Linux.mesa;

    extraPackages = with pkgs; [
      vpl-gpu-rt
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
      libva
      intel-media-driver
    ];

    extraPackages32 = with pkgs.pkgsi686Linux; [intel-vaapi-driver libvdpau-va-gl];
  };
}
