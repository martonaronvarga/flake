self: super: {
    wl-screenrec = super.wl-screenrec.override {
      ffmpeg = super.ffmpeg_6;
      };
}

