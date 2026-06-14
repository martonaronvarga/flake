{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";
    mouse = true;
    newSession = true;
    plugins = with pkgs.tmuxPlugins; [
      resurrect
      yank
      tmux-thumbs
    ];
  };
}
