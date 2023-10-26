{
  description = "A very basic flake";

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
          example = pkgs.callPackage ./example.nix {
            inherit (self.legacyPackages.${system}) buildGoCache;
          };
        });
    };
}
