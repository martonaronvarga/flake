{
  programs.yazi.theme.mgr = {
    cwd = {fg = "#e25303";};

    # Hovered
    hovered = {
      fg = "black";
      bg = "#e25303";
    };

    preview_hovered = {
      fg = "white";
      bg = "#2a5c45";
    };

    # Find
    find_keyword = {
      fg = "#e25303";
      italic = true;
    };

    find_position = {
      fg = "#e25303";
      bg = "reset";
      italic = true;
    };

    # Marker
    marker_selected = {
      fg = "black";
      bg = "#e25303";
    };
    marker_copied = {
      fg = "black";
      bg = "#e25303";
    };
    marker_cut = {
      fg = "lightred";
      bg = "lightred";
    };

    # Tab
    tab_active = {
      fg = "black";
      bg = "#2a5c45";
    };
    tab_inactive = {
      fg = "white";
      bg = "darkgray";
    };
    tab_width = 1;

    # Border;
    border_symbol = "│";
    border_style = {fg = "gray";};

    # Highlighting;
    syntect_theme = "";
  };
}
