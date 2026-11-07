{ self, ... }:
{
  flake.nixosModules.desktop =
    { pkgs, ... }:
    {
      imports = [ self.nixosModules.base ];

      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;

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
      programs.firefox.enable = true;
      hardware.bluetooth.enable = true;
      networking.networkmanager.enable = true;

      users.users.jan = {
        extraGroups = [ "networkmanager" ];
      };

      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        noto-fonts-color-emoji
      ];
    };
}
