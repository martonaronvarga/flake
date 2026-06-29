{
  pkgs,
  lib,
  ...
}: {
  fonts = {
    fontconfig = {
      enable = true;
      antialias = true;

      hinting = {
        enable = true;
        style = "slight";
      };

      subpixel = {
        lcdfilter = "default";
        rgba = "rgb";
      };
    };

    packages =
      (with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji

        dejavu_fonts
        liberation_ttf
        unifont

        stix-two
        libertinus
        lmodern

        nerd-fonts.roboto-mono
        nerd-fonts.commit-mono
        nerd-fonts.terminess-ttf
        nerd-fonts.symbols-only
        nerd-fonts.noto
        nerd-fonts.fantasque-sans-mono

        font-awesome
        material-symbols
        material-design-icons
      ])
      ++ (lib.filter lib.isDerivation (builtins.attrValues pkgs.tex-gyre));

    fontconfig.defaultFonts = {
      serif = ["Terminess Nerd Font" "STIX Two Text" "Libertinus Serif" "TeX Gyre Termes" "Noto Serif" "DejaVu Serif" "Noto Color Emoji"];
      sansSerif = ["Terminess Nerd Font" "Noto Sans" "Noto Sans Symbols 2" "TeX Gyre Heros" "DejaVu Sans" "Liberation Sans" "Noto Color Emoji"];
      monospace = ["Terminess Nerd Font" "RobotoMono Nerd Font" "CommitMono Nerd Font" "Symbols Nerd Font Mono" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
    };
  };
}
