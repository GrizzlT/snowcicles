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
    rev = "b4a45fd3a097f42783fd9f11ff7c218f70de96e9";               # pin a specific commit
    hash = "sha256-hxfMaVtp8OvpXiZOdJZcEHF/FSmy+l8uClGEknW1Fvo=";                # replace after first build
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

