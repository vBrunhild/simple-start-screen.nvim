{
  description = "Minimal output flake for simple-start-screen";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    pkgsFor = system: import nixpkgs {inherit system;};
  in {
    packages = forAllSystems (
      system: let
        pkgs = pkgsFor system;
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "simple-start-screen.nvim";
          src = ./.;
        };
      in {
        default = plugin;
        simple-start-screen-nvim = plugin;
      }
    );
  };
}
