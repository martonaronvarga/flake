{pkgs, ...}: {

  hardware.cpu = {
    intel.updateMicrocode = true;
  };

  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      vpl-gpu-rt
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      libva
      intel-media-driver
    ];

    extraPackages32 = with pkgs.pkgsi686Linux; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
}
