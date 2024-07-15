{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Declarative disk partitioning and formatting using nix
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # A collection of NixOS modules covering hardware quirks.
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Modules to help you handle persistent state on systems with ephemeral root storage
    #impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, ... } @ inputs: let

    # Function to build a nixos configuration from system modules
    nixosSystem = host: system: systemModules: 
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit (self) inputs outputs;};
        modules = systemModules ++ [./hosts/${host}/configuration.nix];
      };
      
  in {

    nixosConfigurations = {

      laptop = nixosSystem "void" "x86_64-linux" [
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
      ];

    };
  };
}
