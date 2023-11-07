# buildGoCache

buildGoCache speeds up nix's buildGoModule by pre-compiling imported go modules

## Potential speed-up

For telegraf we measured the following build times with and without the buildGoCache.

Build machine: AMD Ryzen 9 7950X3D 16-Core Processor, 128G DDR4 RAM, zfs raid0

without cache:

```
time nix build .#example-no-cache -L
0.28s user 0.20s system 0% cpu 59.539 total
time nix build .#example-proxy-vendor-no-cachA
0.30s user 0.20s system 0% cpu 1:14.01 total
```

with cache:

```
time nix build .#example -L
0.23s user 0.18s system 1% cpu 25.872 total
time nix build .#example-proxy-vendor -L
0.03s user 0.04s system 0% cpu 30.501 total
```

Speedup: 2.3x..~2.4x

## Usage

First we generate a list of all imported packages:

```
nix run .#get-external-imports -- ./. imported-packages
```

Than we modify our `buildGoModule` to use your go build cache:

```nix
let
  vendorHash = "sha256-aMO7nH68E1S5G1iWj29McK0VY0frfjNnJ6D6rJ29cqQ=";
  proxyVendor = true; # must be in sync for buildGoCache and buildGoModule
  src = ./.; # replace this with the source directory

  goCache = buildGoCache {
    importPackagesFile = ./imported-packages;
    inherit src vendorHash proxyVendor;
  };
in
buildGoModule {
  name = "myproject";

  buildInputs = [ goCache ];

  inherit src;

  inherit vendorHash proxyVendor;
}
```

See [./examples]() for real-world examples based on telegraf and gomod2nix

Other [real-world example](https://github.com/replit/upm/pull/155)
