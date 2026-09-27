{pkgs, ...}: let
  popupPinentryChild = pkgs.writeShellApplication {
    name = "pinentry-popup-child";
    runtimeInputs = [
      pkgs.gnused
      pkgs.pinentry-curses
    ];
    text = ''
      set -euo pipefail

      request_fifo="$1"
      response_fifo="$2"
      shift 2

      popup_tty="$(tty)"
      sed -u "s|^OPTION ttyname=.*|OPTION ttyname=$popup_tty|" "$request_fifo" \
        | pinentry-curses "$@" >"$response_fifo"
    '';
  };

  terminalPopupPinentry = pkgs.writeShellApplication {
    name = "pinentry";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.kitty
      pkgs.pinentry-curses
    ];
    text = ''
      set -euo pipefail

      if [[ -z "''${WAYLAND_DISPLAY:-}" && -z "''${DISPLAY:-}" ]]; then
        exec pinentry-curses "$@"
      fi

      runtime_base="''${XDG_RUNTIME_DIR:-/tmp}"
      relay_dir="$(mktemp -d "$runtime_base/pinentry-kitty.XXXXXX")"
      chmod 0700 "$relay_dir"
      request_fifo="$relay_dir/request"
      response_fifo="$relay_dir/response"
      mkfifo -m 0600 "$request_fifo" "$response_fifo"
      exec {agent_input_fd}<&0

      popup_pid=""
      request_pid=""
      cleanup() {
        [[ -z "$request_pid" ]] || kill "$request_pid" 2>/dev/null || true
        [[ -z "$popup_pid" ]] || kill "$popup_pid" 2>/dev/null || true
        rm -rf "$relay_dir"
      }
      trap cleanup EXIT HUP INT TERM

      kitty \
        --class pinentry-terminal \
        --title "GPG passphrase" \
        --override remember_window_size=no \
        --override initial_window_width=500 \
        --override initial_window_height=160 \
        --override font_size=8 \
        --override window_padding_width=4 \
        ${popupPinentryChild}/bin/pinentry-popup-child \
        "$request_fifo" "$response_fifo" "$@" \
        </dev/null \
        >/dev/null 2>&1 &
      popup_pid="$!"

      sleep 0.2
      if ! kill -0 "$popup_pid" 2>/dev/null; then
        wait "$popup_pid" || true
        popup_pid=""
        cleanup
        trap - EXIT HUP INT TERM
        exec pinentry-curses "$@"
      fi

      cat <&"$agent_input_fd" >"$request_fifo" &
      request_pid="$!"

      set +e
      cat "$response_fifo"
      response_status="$?"
      wait "$popup_pid"
      popup_status="$?"
      set -e

      kill "$request_pid" 2>/dev/null || true
      wait "$request_pid" 2>/dev/null || true
      exec {agent_input_fd}<&-
      request_pid=""
      popup_pid=""

      [[ "$response_status" -eq 0 ]] || exit "$response_status"
      exit "$popup_status"
    '';
  };
in {
  programs.gnupg.agent = {
    enable = true;
    enableExtraSocket = true;
    pinentryPackage = terminalPopupPinentry;
  };
}
