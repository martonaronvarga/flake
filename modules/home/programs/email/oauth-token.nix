{
  pkgs,
  lib,
  account,
  name ? "aerc-oauth-token",
  label ? "Gmail",
  reauthCommand ? "aerc-oauth-reauth",
}:
pkgs.writeShellApplication {
  inherit name;
  runtimeInputs = [pkgs.oama pkgs.coreutils pkgs.gnugrep pkgs.libnotify];
  text = ''
    umask 077
    workdir="$(mktemp -d)"
    trap 'rm -rf "$workdir"' EXIT

    if oama access ${lib.escapeShellArg account} >"$workdir/token" 2>"$workdir/error"; then
      if [ -s "$workdir/token" ]; then
        cat "$workdir/token"
        exit 0
      fi
    fi

    if grep -Eqi 'invalid_grant|expired|revoked|InvalidGrant|reauthor' "$workdir/error"; then
      notify-send "${label} OAuth reauthorization needed" "Run: ${reauthCommand}" || true
    fi
    # OAuth error payloads can contain credentials. Do not copy them to logs.
    printf '%s OAuth access failed; run %s if authorization expired.\n' \
      ${lib.escapeShellArg label} ${lib.escapeShellArg reauthCommand} >&2
    exit 1
  '';
}
