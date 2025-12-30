{pkgs, ...}: {
  hardware.cpu = {intel.updateMicrocode = true;};

  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      vpl-gpu-rt
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
      libva
      mesa
      driversi686Linux.mesa
      intel-media-driver
    ];

    extraPackages32 = with pkgs.pkgsi686Linux; [intel-vaapi-driver libvdpau-va-gl];
  };
}
