_: {
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;
    extraConfig.pipewire = {
      "10-echo-cancel" = {
        "context.modules" = [
          {
            name = "libpipewire-module-echo-cancel";
            args = {
              "library.name" = "aec/libspa-aec-webrtc";
              "node.passive" = true;
              "source.props" = {
                "node.name" = "echo-cancel-source";
                "node.description" = "Echo-Cancelled Microphone";
              };
              "sink.props" = {
                "node.name" = "echo-cancel-sink";
                "node.description" = "Echo-Cancelled Audio Sink";
              };
            };
          }
        ];
      };
    };
    wireplumber.extraConfig = {
      "wireplumber.profiles".main."monitor.libcamera" = "disabled";
      "10-bluetooth"."wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
    };
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
}
