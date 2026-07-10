{ self, ... }:
{
  flake.nixosModules.base =
    { lib, pkgs, ... }:
    {
      imports = [
        self.nixosModules.common
        self.nixosModules.git
        self.nixosModules.jujutsu
        self.nixosModules.neovim
        self.nixosModules.dev-tools
        self.nixosModules.stylix
        self.nixosModules.herdr
        self.nixosModules.tmux
        self.nixosModules.opencode
        self.nixosModules.flyline
      ];

      options.profile.identity = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Jan Lafferton";
          description = "Display name used for VCS (git, jujutsu) identity.";
        };
        email = lib.mkOption {
          type = lib.types.str;
          default = "jan@lafferton.de";
          description = "Email used for VCS (git, jujutsu) identity.";
        };
      };

      config = {
        virtualisation = {
          libvirtd.enable = true;
          containers.enable = true;
          podman = {
            enable = true;
            dockerCompat = true;
          };
        };

        environment.systemPackages = [
          pkgs.claude-code
          pkgs.distrobox
        ];

        users.users.jan = {
          isNormalUser = true;
          description = "Jan";
          extraGroups = [ "wheel" ];
        };
      };
    };
}
