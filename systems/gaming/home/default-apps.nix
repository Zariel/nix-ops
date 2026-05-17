{
  xdg = {
    enable = true;
    mimeApps.enable = true;
    mimeApps.defaultApplications = {
      "inode/directory" = [ "org.kde.dolphin.desktop" ];

      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];

      "image/jpeg" = [ "org.kde.gwenview.desktop" ];
      "image/png" = [ "org.kde.gwenview.desktop" ];
      "image/gif" = [ "org.kde.gwenview.desktop" ];
      "image/webp" = [ "org.kde.gwenview.desktop" ];
      "application/pdf" = [ "org.kde.okular.desktop" ];

      "application/zip" = [ "org.kde.ark.desktop" ];
      "application/x-7z-compressed" = [ "org.kde.ark.desktop" ];
      "application/x-rar" = [ "org.kde.ark.desktop" ];
      "application/x-tar" = [ "org.kde.ark.desktop" ];
      "application/gzip" = [ "org.kde.ark.desktop" ];

      "text/plain" = [
        "org.kde.kate.desktop"
        "org.kde.kwrite.desktop"
      ];
      "application/json" = [
        "org.kde.kate.desktop"
        "org.kde.kwrite.desktop"
      ];

      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];
      "audio/ogg" = [ "mpv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "video/webm" = [ "mpv.desktop" ];
    };
  };
}
