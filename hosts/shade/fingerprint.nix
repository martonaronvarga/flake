{pkgs, ...}: let
  pythonValidity = pkgs.callPackage ../../packages/python-validity.nix {};
in {
  environment = {
    etc."python-validity/dbus-service.yaml".text = ''
      user_to_sid: {}
    '';
    systemPackages = [
      pkgs.fprintd
      pythonValidity
    ];
  };

  services.dbus.packages = [
    pkgs.open-fprintd
    pythonValidity
  ];

  systemd = {
    packages = [pkgs.open-fprintd];
    services = {
      # Keep open-fprintd's D-Bus proxy alive across sleep so hyprlock retains
      # its authentication session. These packaged units suspend and resume
      # the underlying device instead of replacing the proxy process.
      open-fprintd-suspend.wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
      open-fprintd-resume.wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];

      python-validity = {
        description = "Validity fingerprint sensor driver";
        wantedBy = ["multi-user.target"];
        wants = ["open-fprintd.service"];
        after = ["open-fprintd.service"];
        serviceConfig = {
          Type = "simple";
          # The driver can exit successfully after the sensor disconnects. It
          # still needs to come back, independently of its exit status.
          Restart = "always";
          RestartSec = 2;
          RuntimeDirectory = "python-validity";
          RuntimeDirectoryMode = "0700";
          ExecStartPre = "${pkgs.coreutils}/bin/install -m 0400 ${pythonValidity}/share/python-validity/6_07f_lenovo_mis_qm.xpfwext /run/python-validity/6_07f_lenovo_mis_qm.xpfwext";
          ExecStart = "${pythonValidity}/lib/python-validity/dbus-service";
        };
      };
    };
  };

  security.pam.services = {
    login.fprintAuth = true;
    "polkit-1".fprintAuth = true;
  };
}
