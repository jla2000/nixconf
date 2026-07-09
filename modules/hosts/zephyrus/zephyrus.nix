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
        self.nixosModules.common
        self.nixosModules.jujutsu
        self.nixosModules.git
        self.nixosModules.dev-tools
        self.nixosModules.stylix
        self.nixosModules.zephyrus-hardware
        self.nixosModules.herdr
        self.nixosModules.tmux
        self.nixosModules.opencode
        self.nixosModules.flyline
        inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402
      ];

      stylix.colorscheme = "catppuccin-mocha";

      hardware.bluetooth.enable = true;

      services.supergfxd = {
        settings = {
          vfio_enable = true;
        };
      };

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "zephyrus";
      networking.networkmanager.enable = true;

      services.displayManager.plasma-login-manager.enable = true;
      services.desktopManager.plasma6.enable = true;

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      users.users."jan" = {
        isNormalUser = true;
        description = "Jan";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        packages = with pkgs; [
          kdePackages.kate
        ];
      };

      programs.firefox.enable = true;

      environment.systemPackages = with pkgs; [
        ghostty
        zed-editor
        distrobox
        self.packages.${pkgs.stdenv.hostPlatform.system}.neovim-dev
      ];

      virtualisation = {
        libvirtd.enable = true;
        containers.enable = true;
        podman.enable = true;
      };

      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.monaspace
        noto-fonts-color-emoji
      ];

      system.stateVersion = "26.05";
    };
}
