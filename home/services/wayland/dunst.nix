{ pkgs, inputs, lib, config, ...}: {
  services.dunst = {
    enable = true;
    settings = {
      font = "Terminus Font 12";
      allow_markup = "yes";
      format = "<b>%s</b>\n%b";
      sort = "yes";
      indicate_hidden = "yes";
      alignment = "left";
      bounce_freq = 0;
      ellipsize = "middle";
      show_age_threshold = -1;
      word_wrap = "yes";
      ignore_newline = "no";

      width = 320;
      heigth = 500;
      origin = "top_right";
      offet = "10x12";
      progress_bar = true;
      progress_bar_heigth = 14;
      progress_bar_frame_wifth = 1;
      progress_bar_min_width = 150;
      progress_bar_max_width = 300;

      frame_width = 3;
      frame_color = "#000000";
      transparency = 0;
      idle_threshold = 0;
      monitor = 0;
      follow = "keyboard";
      show_indicators = "no";
      sticky_history = "yes";
      line_height = 0;
      separator_height = 3;
      padding = 16;
      horizontal_padding = 12;

      text_icon_padding = 16;
      separator_color = "frame";

      startup_notification = "no";
      icon_position = "left";

      min_icon_size = 32;
      max_icon_size = 48;

      corner_radius = 15;
      always_run_script = "true";

      mouse_left_click = "close_current";
      mouse_middle_click = "do_action, close_current";
      mouse_right_click = "close_all";

      urgency_low = {
        timeout = 6;
        background = "#000000";
        foreground = "#ffffff";
        frame_color = "#ffffff";
        highlight_color = "#ffffff";
      };

      urgency_normal = {
        timeout = 6;
        background = "#000000";
        foreground = "#ffffff";
        frame_color = "#ffffff";
        highlight = "#ffffff";
      };

      urgency_critical = {
        timeout = 0;
        background = "#ff0000";
        foreground = "#ffffff";
        frame_color = "#ffffff";
        highlight = "#ffffff";
      };

      backlight = {
        summary = "Backlight";
        highlight = "#ffffff";
        set_stack_tag = "backlight";
      };

      volume = {
        summary = "Volume";
        set_stack_tag = "volume";
      };

      volume-muted = {
        summary = "Volume Muted";
        highlight = "#ff0000";
      };

      volumte-unmuted = {
        summary = "Volume Unmuted";
        highlight = "#00ff00";
      };




    };
  };
}
