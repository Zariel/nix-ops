{
  stdenvNoCC,
  python3,
}:

stdenvNoCC.mkDerivation {
  pname = "git-commit-wrapped";
  version = "0.1.0";

  srcs = [
    ./git-commit-wrapped.py
    ./git-commit-wrapped.1
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 ${./git-commit-wrapped.py} "$out/bin/git-commit-wrapped"
    install -Dm644 ${./git-commit-wrapped.1} "$out/share/man/man1/git-commit-wrapped.1"
    patchShebangs "$out/bin/git-commit-wrapped"

    runHook postInstall
  '';

  nativeBuildInputs = [
    python3
  ];

  meta = {
    description = "Git commit helper that lowercases titles and wraps commit bodies";
    mainProgram = "git-commit-wrapped";
  };
}
