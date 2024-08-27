let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  nixpkgs = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "d0231321f54073526c85c3198a899eb8aead4dee";
    sha256 = "/Kri8HRUkkwQGS3S1TVzbRWtLWgTDLOI7jBr/+6Z+PA=";
  };
  pkgs = import nixpkgs {};
in
  pkgs.mkShell {
    name = "elixir-1.17";
    nativeBuildInputs = [
      (pkgs.elixir_1_17.override {
        erlang = pkgs.erlang_27;
      })
    ] ++ (
      if builtins.match ".*darwin.*" pkgs.system != null then
        [pkgs.darwin.apple_sdk.frameworks.CoreServices]
      else
        []
    );
  }

