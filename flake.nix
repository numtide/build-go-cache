{
  description = "A very basic flake";
  # even more performance: https://github.com/NixOS/nixpkgs/pull/266075/files (optional)
  inputs.nixpkgs.url = "github:Mic92/nixpkgs/build-go-module";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";
  inputs.gomod2nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, gomod2nix }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      legacyPackages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          buildGoCache = pkgs.callPackage ./buildGoCache.nix { };
          get-external-imports = pkgs.callPackage ./get-external-imports.nix { };
          # FIXME: error: cannot coerce null to a string
          # example = pkgs.callPackage ./examples/buildGoModule.nix {
          #   inherit (self.legacyPackages.${system}) buildGoCache;
          # };
          example-no-cache = pkgs.callPackage ./examples/buildGoModule.nix {
            inherit (self.legacyPackages.${system}) buildGoCache;
            useGoCache = false;
          };
          example-proxy-vendor = pkgs.callPackage ./examples/buildGoModule.nix {
            inherit (self.legacyPackages.${system}) buildGoCache;
            proxyVendor = true;
          };
          example-proxy-vendor-no-cache = pkgs.callPackage ./examples/buildGoModule.nix {
            inherit (self.legacyPackages.${system}) buildGoCache;
            proxyVendor = true;
            useGoCache = false;
          };
          example-gomod2nix = pkgs.callPackage ./examples/buildGoApplication.nix {
            inherit (self.legacyPackages.${system}) buildGoCache;
            inherit (gomod2nix.legacyPackages.${system}) buildGoApplication;
          };
          example-gomod2nix-no-cache = pkgs.callPackage ./examples/buildGoApplication.nix {
            inherit (self.legacyPackages.${system}) buildGoCache;
            inherit (gomod2nix.legacyPackages.${system}) buildGoApplication;
            useGoCache = false;
          };
        });
      checks = forAllSystems (system:
        builtins.removeAttrs self.legacyPackages.${system} ["buildGoCache"]
      );
    };
}
