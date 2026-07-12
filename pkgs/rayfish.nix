{
  lib, fetchFromGitHub, rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "GrizzlT";
    repo = pname;
    # tag = "v0.1.3";
    rev = "89bd1ca6802672c1acaa2629f937036cb9c83e5d";
    hash = "sha256-uGa1b/pSsguCcOIsTgp3Wryeux2Z+3VVFIjLV9LLYBg=";
  };

  cargoHash = "sha256-dm6gzxhbchgiF+HYb7yYDRINjmsNWu78blNzeCpy3lQ=";

  doCheck = false;

  meta = with lib; {
    description = "P2P mesh VPN powered by iroh — connects peers by cryptographic identity";
    homepage = "https://github.com/rayfish/rayfish";
    license = licenses.mpl20;
    mainProgram = "ray";
  };
}

