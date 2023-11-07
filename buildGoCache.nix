{ buildGoModule
, lib
, rsync
}:
{ importPackagesFile
, src
, vendorHash
, proxyVendor ? false
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
    inherit vendorHash proxyVendor;
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
  inherit proxyVendor;
  buildPhase = ''
    export HOME=$TMPDIR
    mkdir -p $out/

    export GOFLAGS=-trimpath
    ${if proxyVendor then ''
      export GOPROXY="file://${goModules}"
      mkdir -p $out/go-mod-cache
      export GOMODCACHE=$out/go-mod-cache
    '' else ''
      export GOPROXY=off
      export GOSUMDB=off
      cp -r --reflink=auto ${goModules} vendor
    ''}
    export GOCACHE=$out/go-cache
    xargs go install <${importPackagesFile}
    mkdir -p $out/nix-support
    cat > $out/nix-support/setup-hook <<EOF
      cp --reflink=auto -r $out/go-cache $TMPDIR/go-cache
      chmod -R +w $TMPDIR/go-cache
      ${lib.optionalString proxyVendor ''export GOMODCACHE="$out/go-mod-cache"''}
    EOF
  '';

  doCheck = false;
  allowGoReference = true;
  phases = [ "unpackPhase" "buildPhase" ];
}
