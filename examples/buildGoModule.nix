{ buildGoModule
, buildGoCache
, fetchFromGitHub
, proxyVendor ? false
, useGoCache ? true
, lib
}:
let

  vendorHash = if proxyVendor then
    "sha256-aMO7nH68E1S5G1iWj29McK0VY0frfjNnJ6D6rJ29cqQ="
  else
    "sha256-UuFPSw4G607GhAH3pf5+vDkJGjxeyUcs7SN0GiGm/h4=";

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
    inherit src vendorHash proxyVendor;
  };
in
buildGoModule {
  pname = "telegraf";
  inherit version;

  subPackages = [ "cmd/telegraf" ];
  buildInputs = lib.optional useGoCache goCache;

  inherit src;
  doCheck = false;

  inherit vendorHash proxyVendor;

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/influxdata/telegraf/internal.Commit=${src.rev}"
    "-X=github.com/influxdata/telegraf/internal.Version=${version}"
  ];
}
