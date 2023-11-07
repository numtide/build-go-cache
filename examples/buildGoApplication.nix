{ buildGoCache
, useGoCache ? true
, buildGoApplication
, fetchFromGitHub
, lib
}:
let

  version = "1.28.3";
  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "gomod2nix";
    rev = "f95720e89af6165c8c0aa77f180461fe786f3c21";
    hash = "sha256-c49BVhQKw3XDRgt+y+uPAbArtgUlMXCET6VxEBmzHXE=";
  };
  modules = ./gomod2nix.toml;

  # use gomod2nix to generate a vendor directory for our project for use in buildGoCache
  inherit (buildGoApplication {
    pname = "vendor-env";
    inherit src version modules;
    doCheck = false;
  }) vendorEnv;

  goCache = buildGoCache {
    importPackagesFile = ./imported-packages-go-mod2nix;
    inherit src vendorEnv;
  };
in
buildGoApplication {
  pname = "gomod2nix";
  inherit version src modules;
  buildInputs = lib.optional useGoCache goCache;
  subPackages = [ "." ];
  vendorHash = null;
}
