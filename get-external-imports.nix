{ stdenv
, makeWrapper
, lib
, gnugrep
, gawk
, coreutils
, go
}:

stdenv.mkDerivation {
  name = "get-external-imports";
  nativeBuildInputs = [ makeWrapper ];
  src = ./.;
  installPhase = ''
    install -D -m755 get-external-imports $out/bin/get-external-imports
    wrapProgram $out/bin/get-external-imports \
      --prefix PATH ":" ${lib.makeBinPath [ gnugrep gawk coreutils go ]}
  '';
}
