{
  lib, fetchFromGitHub, rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  version = "nightly-9c8e68a";

  src = fetchFromGitHub {
    owner = "GrizzlT";
    repo = pname;
    # tag = "v0.1.3";
    rev = "9c8e68aedb0a16678b250eb84731860ce0387e89";
    hash = "sha256-qGhxE3oYpPTkIdd9AmZstAA8mTUvkjuBNm2BDCKr5Jw=";
  };

  cargoHash = "sha256-fVz+l1D5hupGN6YfMJI0FLFVttRjkxZc+8tBmabu1J4=";

  doCheck = false;

  meta = with lib; {
    description = "P2P mesh VPN powered by iroh — connects peers by cryptographic identity";
    homepage = "https://github.com/rayfish/rayfish";
    license = licenses.mpl20;
    mainProgram = "ray";
  };
}

