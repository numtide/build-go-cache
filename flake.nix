{
  description = "A very basic flake";
  # even more performance: https://github.com/NixOS/nixpkgs/pull/266075/files (optional)
  inputs.nixpkgs.url = "github:Mic92/nixpkgs/build-go-module";

  outputs = { self, nixpkgs }:
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
          example = pkgs.callPackage ./examples/buildGoModule.nix {
            inherit (self.legacyPackages.${system}) buildGoCache;
          };
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
        });
    };
}
