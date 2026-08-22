{
  dbus,
  lib,
  pkg-config,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "gamemode-waybar";
  version = "0.1.0";

  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];

  meta = {
    description = "Waybar status helper listing active GameMode clients";
    mainProgram = "gamemode-waybar";
    platforms = lib.platforms.linux;
  };
}
