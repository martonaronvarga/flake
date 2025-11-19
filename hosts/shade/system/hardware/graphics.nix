{pkgs, ...}: {
  hardware.cpu = {intel.updateMicrocode = true;};

  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      vpl-gpu-rt
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      libva
      mesa
      driversi686Linux.mesa
      intel-media-driver
    ];

    extraPackages32 = with pkgs.pkgsi686Linux; [vaapiVdpau libvdpau-va-gl];
  };
}
