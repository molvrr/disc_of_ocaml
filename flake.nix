{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nix-ocaml/nix-overlays";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
          (self: super: { ocamlPackages = super.ocaml-ng.ocamlPackages_5_1; })
        ];
        inherit (pkgs) ocamlPackages;
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with ocamlPackages; [
            dune_3
            findlib
            melange
            ocaml
            ocaml-lsp
            ocamlformat
          ];
          buildInputs = with ocamlPackages; [
            cohttp-lwt-unix
            websocketaf-lwt-unix
            yojson
            ppx_yojson_conv
          ];
        };

        formatter = pkgs.nixfmt;
      });
}
