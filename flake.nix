{
  description = "config";

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";

    home-manager.url = "github:nix-community/home-manager";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nvf.url = "github:NotAShelf/nvf";

      #nix-doom-emacs-unstraightened = {
      #url = "github:marienz/nix-doom-emacs-unstraightened";
      #inputs.nixpkgs.follows = "nixpkgs";
      #};
    };

  outputs = {self, nixpkgs, home-manager, nix-index-database, ...}@inputs: {
    nixosConfigurations.happyhomedesigner = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        nix-index-database.nixosModules.default
        inputs.nvf.nixosModules.nvf
         {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.ethan = import ./home/home.nix;
            extraSpecialArgs = { inherit inputs; };
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}
