{pkgs, ...}: {
  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      # icon fonts
      material-symbols
      nerd-fonts.roboto-mono
      nerd-fonts.noto
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.commit-mono
      nerd-fonts.terminess-ttf

      nerd-fonts.symbols-only
    ];

    # causes more issues than it solves
    enableDefaultPackages = false;

    # user defined fonts
    fontconfig.defaultFonts = let
      addAll =
        builtins.mapAttrs
        (_: v: ["Symbols Nerd Font"] ++ v);
    in
      addAll {
        serif = ["Terminess Nerd Font"];
        sansSerif = ["Terminess Nerd Font"];
        monospace = ["Terminess Nerd Font"];
        emoji = [];
      };
  };
}
