{
  description = "Tmux sessionizer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let 
    pkgs = nixpkgs.legacyPackages.x86_64-linux; 
  in 
  {

    packages.x86_64-linux.default = pkgs.writeShellApplication {
      name="sz";
      runtimeInputs = with pkgs; [
        fzf
        tmux
      ];
      text = builtins.readFile ./tmux-sessionizer;

    };

  };
}
