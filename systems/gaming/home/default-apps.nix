let
  appFor =
    desktopFiles: mimeTypes:
    builtins.listToAttrs (
      map (mimeType: {
        name = mimeType;
        value = desktopFiles;
      }) mimeTypes
    );

  mpv = [ "mpv.desktop" ];
  firefox = [ "firefox.desktop" ];
  gwenview = [ "org.kde.gwenview.desktop" ];
  ark = [ "org.kde.ark.desktop" ];
  textEditor = [
    "org.kde.kate.desktop"
    "org.kde.kwrite.desktop"
  ];

  browserTypes = [
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ];

  imageTypes = [
    "image/avif"
    "image/bmp"
    "image/gif"
    "image/heic"
    "image/jpeg"
    "image/png"
    "image/svg+xml"
    "image/tiff"
    "image/webp"
  ];

  archiveTypes = [
    "application/gzip"
    "application/vnd.rar"
    "application/x-7z-compressed"
    "application/x-bzip2"
    "application/x-compressed-tar"
    "application/x-rar"
    "application/x-tar"
    "application/x-xz"
    "application/zip"
  ];

  textTypes = [
    "application/json"
    "application/x-shellscript"
    "text/plain"
  ];

  mediaTypes = [
    "application/ogg"
    "application/x-cue"
    "application/x-extension-m4a"
    "application/x-extension-mp4"
    "application/x-matroska"
    "application/x-mpegurl"
    "audio/aac"
    "audio/ac3"
    "audio/eac3"
    "audio/flac"
    "audio/m4a"
    "audio/mpeg"
    "audio/ogg"
    "audio/opus"
    "audio/vnd.wave"
    "audio/wav"
    "audio/webm"
    "audio/x-flac"
    "audio/x-m4a"
    "audio/x-matroska"
    "audio/x-mpegurl"
    "audio/x-ms-wma"
    "audio/x-vorbis+ogg"
    "audio/x-wav"
    "video/3gpp"
    "video/3gpp2"
    "video/avi"
    "video/divx"
    "video/mp2t"
    "video/mp4"
    "video/mp4v-es"
    "video/mpeg"
    "video/ogg"
    "video/quicktime"
    "video/vnd.avi"
    "video/vnd.divx"
    "video/webm"
    "video/x-avi"
    "video/x-flv"
    "video/x-m4v"
    "video/x-matroska"
    "video/x-ms-asf"
    "video/x-ms-wmv"
    "video/x-msvideo"
    "video/x-ogm+ogg"
    "video/x-theora+ogg"
  ];
in
{
  xdg = {
    enable = true;
    mimeApps.enable = true;
    mimeApps.associations.added = appFor mpv mediaTypes;
    mimeApps.defaultApplications = {
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
      "application/pdf" = [ "org.kde.okular.desktop" ];
    }
    // appFor firefox browserTypes
    // appFor gwenview imageTypes
    // appFor ark archiveTypes
    // appFor textEditor textTypes
    // appFor mpv mediaTypes;
  };
}
