{ self, ... }:
{
  flake.nixosModules.desktop =
    { pkgs, ... }:
    {
      imports = [ self.nixosModules.base ];

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

      programs.firefox.enable = true;
      hardware.bluetooth.enable = true;
      networking.networkmanager.enable = true;

      users.users.jan = {
        extraGroups = [ "networkmanager" ];
        packages = with pkgs; [
          kdePackages.kate
        ];
      };

      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.monaspace
        noto-fonts-color-emoji
      ];
    };
}
