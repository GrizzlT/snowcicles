{
  lib, fetchFromGitHub, rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  version = "nightly-adced14";

  src = fetchFromGitHub {
    owner = "GrizzlT";
    repo = pname;
    # tag = "v0.1.3";
    rev = "adced14a1717f2e691eb544f226c5f5542656623";
    hash = "sha256-UXeasZ1NWEYxVAcrjC9OBuNFBtRJXQonTJKQT6sBsmA=";
  };

  cargoHash = "sha256-9vyH7u53AQNwBbrjnvOil3kDMykFjJBat5CPXyO1jfY=";

  doCheck = false;

  meta = with lib; {
    description = "P2P mesh VPN powered by iroh — connects peers by cryptographic identity";
    homepage = "https://github.com/rayfish/rayfish";
    license = licenses.mpl20;
    mainProgram = "ray";
  };
}

