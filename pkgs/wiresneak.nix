{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage {
  pname = "wiresneak";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "GrizzlT";
    repo = "wiresneak";
    rev = "f73ff22fe580ffac53fe7aec5416506b20c31012";               # pin a specific commit
    hash = "sha256-IRkaaC1evdUCviqPrN382+vqZzRI1SH5dC+fhGc//Co=";                # replace after first build
  };

  cargoHash = "sha256-kwHxIc7bLtaneMkz/x2tLKXUvCTOPHbQqHYTLH/pYcM=";             # replace after first build

  meta = {
    description = "Wireguard-style static IP tunnel built on Iroh";
    homepage = "https://github.com/GrizzlT/wiresneak";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    mainProgram = "wiresneakd";
  };
}

