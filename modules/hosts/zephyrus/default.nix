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
        self.nixosModules.zephyrus-gpu-passthrough
        inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402
      ];

      stylix.colorscheme = "catppuccin-mocha";

      profile.neovim.configDirectory = "/home/jan/.config/nvim";

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "zephyrus";

      environment.systemPackages = with pkgs; [
        ghostty
        zed-editor
        code-cursor
        openspec
      ];

      # The dGPU is bound to vfio-pci in the initrd (see zephyrus-gpu-passthrough),
      # so supergfxd has nothing left to manage. Leaving it on is actively harmful:
      # it writes its own /etc/supergfxd.conf at runtime (ignoring the settings
      # below) and its Vfio mode works by hot-unbinding amdgpu after the card is
      # already initialised, which is the state that hangs the Windows driver.
      # Re-enable this and drop the initrd binding to use the dGPU under Linux.
      services.supergfxd.enable = false;

      programs.virt-manager.enable = true;

      system.stateVersion = "26.05";
    };
}
