{ self, inputs, ... }:
{
  flake.nixosConfigurations.zephyrus = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.zephyrus
    ];
  };

  flake.nixosModules.zephyrus =
    { pkgs, lib, ... }:
    {
      imports = [
        self.nixosModules.desktop
        self.nixosModules.ghostty
        self.nixosModules.zephyrus-hardware
        inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402
      ];


      profile.neovim.configDirectory = "/home/jan/.config/nvim";

      boot.plymouth = {
        enable = true;
        theme = lib.mkForce "bgrt";
      };
      boot.kernelParams = [
        "quiet"
        "splash"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
      ];
      boot.loader.timeout = 0;
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "zephyrus";
      # nixos-hardware defaults this on. Second mesa+llvm+glibc for 32-bit
      # GL/Vulkan is 810 MiB; nothing 32-bit (Steam, Wine) runs here.
      hardware.graphics.enable32Bit = false;

      environment.systemPackages = with pkgs; [
        adwaita-icon-theme
        chromium
        gnome-themes-extra
        herdr-desktop
        pi-coding-agent
        claude-code
      ];

      system.stateVersion = "26.05";
    };
}
