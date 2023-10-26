# buildGoCache

buildGoCache speeds up nix's buildGoModule by pre-compiling imported go modules

## Potential speed-up

For telegraf we measured the following build times with and without the buildGoCache.

Build machine: AMD Ryzen 9 7950X3D 16-Core Processor, 128G DDR4 RAM, zfs raid0

without cache:

```
time nix build .#example -L
0.29s user 0.20s system 0% cpu 1:14.27 total
```

with cache:

```
time nix build .#example -L
0.24s user 0.17s system 1% cpu 26.189 total
```

Speedup: ~2.8x

## Usage

First we generate a list of all imported packages:

```
nix run .#get-external-imports -- ./. imported-packages
```

Than we modify our `buildGoModule` to use your go build cache:

```nix
let
  vendorHash = "sha256-aMO7nH68E1S5G1iWj29McK0VY0frfjNnJ6D6rJ29cqQ=";
  src = ./.; # replace this with the source directory

  goCache = buildGoCache {
    importPackagesFile = ./imported-packages;
    inherit src vendorHash;
  };
in
buildGoModule {
  name = "myproject";

  buildInputs = [ goCache ];

  inherit src;

  inherit vendorHash;
  proxyVendor = true; # we only support proxyVendor with buildGoCache just now
}
```

See [./example.nix]() for a real-world example based on telegraf

