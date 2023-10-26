{ buildGoModule
, buildGoCache
, fetchFromGitHub
}:
let
  vendorHash = "sha256-aMO7nH68E1S5G1iWj29McK0VY0frfjNnJ6D6rJ29cqQ=";
  version = "1.28.3";
  src = fetchFromGitHub {
    owner = "influxdata";
    repo = "telegraf";
    rev = "321c5a4070cd46d699826432ab4858224f25001d";
    hash = "sha256-Jel/XE3lPIymTUqDT0LPY/vmVodbdPFMomoDl2y4194=";
    #rev = "v${version}";
    #hash = "sha256-9BwAsLk8pz1QharomkuQdsoNVQYzw+fSU3nDkw053JE=";
  };

  goCache = buildGoCache {
    importPackagesFile = ./imported-packages;
    inherit src vendorHash;
  };
in
buildGoModule {
  pname = "telegraf";
  inherit version;

  subPackages = [ "cmd/telegraf" ];
  buildInputs = [ goCache ];

  inherit src;
  doCheck = false;
  foo = 2;

  inherit vendorHash;
  proxyVendor = true;

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/influxdata/telegraf/internal.Commit=${src.rev}"
    "-X=github.com/influxdata/telegraf/internal.Version=${version}"
  ];
}
