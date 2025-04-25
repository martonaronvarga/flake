{
  programs.yazi.theme.manager = {
    cwd = {fg = "#e25303";};

    # Hovered
    hovered = {
      fg = "black";
      bg = "#e25303";
    };

    preview_hovered = {
      fg = "black";
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
      fg = "#e25303";
      bg = "#e25303";
    };
    marker_copied = {
      fg = "#e25303";
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

    # Offset;
    folder_offset = [1 0 1 0];
    preview_offset = [1 1 1 1];

    # Highlighting;
    syntect_theme = "";
  };
}
