{pkgs, ...}: {
  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      # icon fonts
      material-symbols
      # Sans(Serif) fonts
      noto-fonts-color-emoji
      roboto
      nerd-fonts.roboto-mono
      nerd-fonts.noto
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.commit-mono
      nerd-fonts.terminess-ttf
      (google-fonts.override {fonts = ["Inter"];})

      nerd-fonts.symbols-only
    ];

    # causes more issues than it solves
    enableDefaultPackages = false;

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = let
      addAll =
        builtins.mapAttrs
        (_: v: ["Symbols Nerd Font"] ++ v ++ ["Noto Color Emoji"]);
    in
      addAll {
        serif = ["CommitMono Nerd Font"];
        sansSerif = ["CommitMono Nerd Font"];
        monospace = ["CommitMono Nerd Font"];
        emoji = [];
      };
  };
}
