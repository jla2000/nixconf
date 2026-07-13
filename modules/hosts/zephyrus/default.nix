{ self, inputs, ... }:
{
  flake.nixosConfigurations.zephyrus = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.zephyrus
    ];
  };

  flake.nixosModules.zephyrus =
    { pkgs, ... }:
    {
      imports = [
        self.nixosModules.desktop
        self.nixosModules.zephyrus-hardware
        inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402
      ];

      stylix.colorscheme = "catppuccin-mocha";

      profile.neovim.configDirectory = "/home/jan/.config/nvim";

      services.supergfxd = {
        settings = {
          vfio_enable = true;
        };
      };

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "zephyrus";

      environment.systemPackages = with pkgs; [
        ghostty
        zed-editor
        code-cursor
        openspec
      ];

      system.stateVersion = "26.05";
    };
}
