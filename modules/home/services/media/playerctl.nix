{pkgs, ...}: {
  # playerctl talks to MPRIS players directly. playerctld adds a virtual
  # player, but its probing of optional TrackList and Playlists interfaces
  # produces repeated errors for players that do not implement them.
  home.packages = [pkgs.playerctl];
}
