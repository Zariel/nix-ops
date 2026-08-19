{
  coreutils,
  writeShellApplication,
}:

writeShellApplication {
  name = "format-commit-message";
  runtimeInputs = [ coreutils ];
  text = ''
    exec fmt --width=72
  '';
}
