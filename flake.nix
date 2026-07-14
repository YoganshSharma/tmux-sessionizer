{
  description = "Tmux sessionizer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    treefmt-nix,
    git-hooks,
    ...
  }: let
    eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f system nixpkgs.legacyPackages.${system});

    treefmtEval = eachSystem (
      system: pkgs:
        treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.alejandra.enable = true;
          programs.shellcheck.enable = true;
        }
    );
  in {
    packages = eachSystem (system: pkgs: {
      default = pkgs.writeShellApplication {
        name = "sz";
        runtimeInputs = with pkgs; [skim fzf tmux];
        text = builtins.readFile ./tmux-sessionizer;
      };
    });

    formatter = eachSystem (system: pkgs: treefmtEval.${system}.config.build.wrapper);

    checks = eachSystem (system: pkgs: {
      treefmt = treefmtEval.${system}.config.build.check ./.;
      pre-commit-check = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          shellcheck.enable = true;
        };
      };
    });

    devShells = eachSystem (system: pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [shellcheck shfmt];
      };
    });

    apps = eachSystem (system: pkgs: {
      default = {
        type = "app";
        program = "${nixpkgs.lib.getExe self.packages.${system}.default}";
      };
    });
  };
}
