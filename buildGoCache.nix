{ buildGoModule
, lib
, rsync
}:
{ importPackagesFile
, src
, vendorHash ? null
, vendorEnv ? null
, proxyVendor ? false
, buildInputs ? [ ]
, nativeBuildInputs ? [ ]
}:
assert (!(vendorHash != null && vendorEnv != null)); # vendorHash and vendorEnv are mutually exclusive
assert (vendorHash != null || vendorEnv != null); # one of vendorHash or vendorEnv must be set
assert (proxyVendor -> vendorEnv == null); # proxyVendor is not compatible with vendorEnv
let
  filteredSource = builtins.path {
    path = src;
    filter = path: type: type == "regular" && (baseNameOf path == "go.sum" || baseNameOf path == "go.mod" || baseNameOf path == "vendor");
    name = "go-cache-src";
  };

  goModules =
    if vendorEnv == null then (buildGoModule {
      name = "deps";
      src = src;
      inherit vendorHash proxyVendor;
    }).goModules
    else vendorEnv;

in
buildGoModule {
  name = "go-cache";
  src = filteredSource;
  inherit buildInputs;
  nativeBuildInputs = [ rsync ] ++ nativeBuildInputs;
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

      cp -r --reflink=auto ${goModules}/ vendor
      export GOFLAGS="''${GOFLAGS} -mod=vendor"
    ''}
    export GOCACHE=$out/go-cache
    export GO_NO_VENDOR_CHECKS="1"
    export GOPATH=$TMPDIR/go
    export GOBIN=$GOPATH/bin
    mkdir -p $GOPATH/src
    xargs go build <${importPackagesFile}
    mkdir -p $out/nix-support
    cat > $out/nix-support/setup-hook <<'EOF'
      mkdir -p "$TMPDIR" || true
      if [ -d "$TMPDIR" ]; then
        echo "copying ${placeholder "out"}/go-cache" "$TMPDIR/go-cache"
        cp --reflink=auto -r "${placeholder "out"}/go-cache" "$TMPDIR/go-cache"
        chmod -R +w "$TMPDIR/go-cache"
      else
        echo skipping build-go-cache copy
      fi
      ${lib.optionalString proxyVendor ''export GOMODCACHE="${placeholder "out"}/go-mod-cache"''}
    EOF
  '';

  doCheck = false;
  allowGoReference = true;
  phases = [ "unpackPhase" "buildPhase" ];
}
