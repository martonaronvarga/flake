{ pkgs, ... }: {
  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      # icon fonts
      material-symbols
      # Sans(Serif) fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      roboto
      (google-fonts.override { fonts = [ "Inter" ]; })

      # monospace fonts
      roboto-mono

      # nerdfonts
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    ];

    # causes more issues than it solves
    enableDefaultPackages = false;

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = let
      addAll = builtins.mapAttrs
        (_: v: [ "Symbols Nerd Font" ] ++ v ++ [ "Noto Color Emoji" ]);
    in addAll {
      serif = [ "Roboto" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "Roboto Mono" ];
      emoji = [ ];
    };
  };
}
