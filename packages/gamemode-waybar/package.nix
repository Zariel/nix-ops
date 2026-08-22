{
  lib,
  makeWrapper,
  rustPlatform,
  systemd,
}:

rustPlatform.buildRustPackage {
  pname = "gamemode-waybar";
  version = "0.1.0";

  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/gamemode-waybar" \
      --set BUSCTL ${lib.getExe' systemd "busctl"}
  '';

  meta = {
    description = "Waybar status helper listing active GameMode clients";
    mainProgram = "gamemode-waybar";
    platforms = lib.platforms.linux;
  };
}
