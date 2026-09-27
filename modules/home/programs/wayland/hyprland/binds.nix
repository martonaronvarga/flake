{lib, ...}: let
  bind = key: action: flags: {_args = [key (lib.generators.mkLuaInline action) flags];};
  exec = key: command: flags: bind key "hl.dsp.exec_cmd(${lib.generators.toLua {} command})" flags;
  # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
  workspaces = builtins.concatLists (builtins.genList (
      x: let
        ws = let
          c = (x + 1) / 10;
        in
          builtins.toString (x + 1 - (c * 10));
      in [
        (bind "SUPER + ${ws}" ''hl.dsp.focus({ workspace = "${toString (x + 1)}" })'' {})
        (bind "SUPER + SHIFT + ${ws}" ''hl.dsp.window.move({ workspace = "${toString (x + 1)}" })'' {})
      ]
    )
    10);

  toggle = program: let
    prog = builtins.substring 0 14 program;
  in "pkill ${prog} || uwsm app -- ${program}";

  runOnce = program: "pgrep ${program} || uwsm app -- ${program}";
in {
  wayland.windowManager.hyprland.settings = {
    # binds
    bind =
      [
        # compositor commands
        (exec "SUPER + SHIFT + E" "uwsm stop" {})
        (bind "SUPER + Q" ''hl.dsp.window.close()'' {})
        (bind "SUPER + F" ''hl.dsp.window.fullscreen()'' {})
        (bind "SUPER + SHIFT + F" ''hl.dsp.window.fullscreen()'' {})
        (bind "SUPER + G" ''hl.dsp.group.toggle()'' {})
        (bind "SUPER + SHIFT + N" ''hl.dsp.group.next()'' {})
        (bind "SUPER + SHIFT + P" ''hl.dsp.group.prev()'' {})
        (bind "SUPER + R" ''hl.dsp.layout("togglesplit")'' {})
        (bind "SUPER + T" ''hl.dsp.window.float()'' {})
        (bind "SUPER + P" ''hl.dsp.window.pseudo()'' {})
        # Removed the empty resizeactive binding: it had no resize delta.

        # utility
        (exec "SUPER + B" "firefox" {})
        # terminal
        (exec "SUPER + Return" "uwsm app -- kitty" {})
        # logout menu
        (exec "SUPER + Escape" "${toggle "wlogout"} -p layer-shell" {})
        # lock screen
        (exec "SUPER + L" "loginctl lock-session" {})
        # fuzzel
        (exec "SUPER + D" "fuzzel" {})

        # move focus
        (bind "SUPER + left" ''hl.dsp.focus({ direction = "left" })'' {})
        (bind "SUPER + right" ''hl.dsp.focus({ direction = "right" })'' {})
        (bind "SUPER + up" ''hl.dsp.focus({ direction = "up" })'' {})
        (bind "SUPER + down" ''hl.dsp.focus({ direction = "down" })'' {})
        (bind "SUPER + Tab" ''hl.dsp.window.cycle_next()'' {})
        (bind "SUPER + Tab" ''hl.dsp.window.bring_to_top()'' {})

        # screenshot
        # area
        (exec "Print" "${runOnce "grimblast"} --notify copysave area" {})
        (exec "SUPER + SHIFT + R" "${runOnce "grimblast"} --notify copysave area" {})

        # current screen
        (exec "CTRL + Print" "${runOnce "grimblast"} --notify --cursor copysave output" {})
        (exec "SUPER + SHIFT + CTRL + R" "${runOnce "grimblast"} --notify --cursor copysave output" {})

        # all screens
        (exec "ALT + Print" "${runOnce "grimblast"} --notify --cursor copysave screen" {})
        (exec "SUPER + SHIFT + ALT + R" "${runOnce "grimblast"} --notify --cursor copysave screen" {})

        # special workspace
        (bind "SUPER + SHIFT + grave" ''hl.dsp.window.move({ workspace = "special" })'' {})
        (bind "SUPER + grave" ''hl.dsp.workspace.toggle_special()'' {})

        # cycle workspaces
        (bind "SUPER + bracketleft" ''hl.dsp.focus({ workspace = "m-1" })'' {})
        (bind "SUPER + bracketright" ''hl.dsp.focus({ workspace = "m+1" })'' {})

        # cycle monitors
        (bind "SUPER + SHIFT + bracketleft" ''hl.dsp.focus({ monitor = "l" })'' {})
        (bind "SUPER + SHIFT + bracketright" ''hl.dsp.focus({ monitor = "r" })'' {})

        # send focused workspace to left/right monitors
        (bind "SUPER + SHIFT + ALT + bracketleft" ''hl.dsp.workspace.move({ monitor = "l" })'' {})
        (bind "SUPER + SHIFT + ALT + bracketright" ''hl.dsp.workspace.move({ monitor = "r" })'' {})
      ]
      ++ workspaces
      ++ [
        (exec "SUPER + SHIFT + W" "select-wallpaper" {release = true;})
        (exec "SUPER + SHIFT + B" "select-waybar" {release = true;})
      ]
      ++ [
        # media controls
        (exec "XF86AudioPlay" "playerctl play-pause" {locked = true;})
        (exec "XF86AudioPrev" "playerctl previous" {locked = true;})
        (exec "XF86AudioNext" "playerctl next" {locked = true;})

        # volume
        (exec "XF86AudioMute" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" {locked = true;})
        (exec "XF86AudioMicMute" "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" {locked = true;})
      ]
      ++ [
        # volume
        (exec "XF86AudioRaiseVolume" "wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%+" {
          locked = true;
          repeating = true;
        })
        (exec "XF86AudioLowerVolume" "wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%-" {
          locked = true;
          repeating = true;
        })

        # backlight
        (exec "XF86MonBrightnessUp" "brillo -q -u 300000 -A 5" {
          locked = true;
          repeating = true;
        })
        (exec "XF86MonBrightnessDown" "brillo -q -u 300000 -U 5" {
          locked = true;
          repeating = true;
        })
      ]
      ++ [
        (bind "SUPER + mouse:273" ''hl.dsp.window.resize()'' {mouse = true;})
        (bind "SUPER + ALT + mouse:272" ''hl.dsp.window.resize()'' {mouse = true;})
        (bind "SUPER + mouse:272" ''hl.dsp.window.drag()'' {mouse = true;})
      ];
  };
}
