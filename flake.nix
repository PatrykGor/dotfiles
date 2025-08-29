{
  description = "My new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # emacs-overlay
    emacs-overlay.url = "github:nix-community/emacs-overlay";

    # nixarr
    nixarr.url = "github:rasmus-kirk/nixarr";

    # catppcucin
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = {
    self,
      nixpkgs,
      home-manager,
      nixarr,
      catppuccin,
      ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    # NixOS configuration entrypoint
    nixosConfigurations = let
      secrets = builtins.fromJSON (builtins.readFile "${self}/secrets/secrets.json");
      specialArgs = {inherit inputs outputs secrets;};
    in {
      patryk-laptop = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
	        ./hosts/patryk-laptop/configuration.nix
	        home-manager.nixosModules.home-manager {
	          home-manager.useGlobalPkgs = true;
	          home-manager.useUserPackages = true;
	          home-manager.extraSpecialArgs = specialArgs;
	          home-manager.users.patryk = import ./users/patryk/home.nix;
          }
          catppuccin.nixosModules.catppuccin
        ];
      };
      home-server = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/home-server/configuration.nix
          nixarr.nixosModules.default
        ];
      };
    };
  };
}
