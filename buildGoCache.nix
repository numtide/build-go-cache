{ buildGoModule
, lib
}:
{ importPackagesFile
, src
, vendorHash
, buildInputs ? [ ]
, nativeBuildInputs ? [ ]
}:
let
  filteredSource = builtins.filterSource
    (path: type: type == "regular" && (baseNameOf path == "go.sum" || baseNameOf path == "go.mod"))
    src;
  goModules = (buildGoModule {
    name = "deps";
    src = src;
    proxyVendor = true;
    inherit vendorHash;
  }).goModules;
in
buildGoModule {
  name = "go-cache";
  src = filteredSource;
  inherit buildInputs nativeBuildInputs;
  vendorHash = null;
  unpackPhase = ''
    mkdir source
    cp -r $src/* source
    chmod -R +w source
    cd source
  '';
  buildPhase = ''
    export HOME=$TMPDIR
    mkdir -p $out/
    export GOPROXY="file://${goModules}"
    export GOCACHE=$out/go-cache
    export GOMODCACHE=$out/go-mod-cache
    export GOFLAGS=-trimpath
    xargs go install <${importPackagesFile}
    mkdir -p $out/nix-support
    cat > $out/nix-support/setup-hook <<EOF
      cp --reflink=auto -r $out/go-cache $TMPDIR/go-cache
      chmod -R +w $TMPDIR/go-cache
      export GOMODCACHE="$out/go-mod-cache";
    EOF
  '';

  doCheck = false;
  allowGoReference = true;
  phases = [ "unpackPhase" "buildPhase" ];
}
