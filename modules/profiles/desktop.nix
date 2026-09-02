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
        pulse.enable = true;
      };

      # Screen reader stack (orca, speech-dispatcher, mbrola voices) is 750 MiB.
      services.orca.enable = false;
      services.speechd.enable = false;
      # Akonadi + kdepim-runtime + a mariadb-server: 380 MiB, no PIM apps used.
      programs.kde-pim.enable = false;
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        plasma-workspace-wallpapers # 255 MiB; the default wallpaper ships in plasma-workspace
        elisa
        khelpcenter
        krdp
        kwin-x11 # Wayland session only
      ];
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
        noto-fonts-color-emoji
      ];
    };
}
