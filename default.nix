let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  nixpkgs = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "3c52ea8c9216a0d5b7a7b4d74a9d2e858b06df5c";
    sha256 = "1sqg1rkkhcq4hg7gl2yrciv1w2b805mnxqnhlll3qvbs4lcw2x36";
  };
  pkgs = import nixpkgs {};
in
  pkgs.mkShell {
    name = "elixir-1.12";
    nativeBuildInputs = [
      pkgs.elixir_1_12
    ] ++ (
      if builtins.match ".*darwin.*" pkgs.system != null then
        [pkgs.darwin.apple_sdk.frameworks.CoreServices]
      else
        []
    );
  }

