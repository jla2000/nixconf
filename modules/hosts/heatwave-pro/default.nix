{ self, inputs, ... }:
let
  nixpkgs-vector = fetchGit {
    url = "https://github1.vg.vector.int/jlafferton/nixpkgs-vector.git";
    rev = "a0640cb67a49705f9ddea95bd3c0a53733875b41";
  };
in
{
  flake.nixosConfigurations.heatwave-pro = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.heatwave-pro
    ];
  };

  flake.nixosModules.heatwave-pro =
    { pkgs, lib, ... }:
    {
      imports = [
        "${nixpkgs-vector}/modules/vector/default.nix"
        self.nixosModules.base
        self.nixosModules.alacritty
        self.nixosModules.wsl
        self.nixosModules.helix
      ];

      profile.identity = {
        name = "Lafferton, Jan";
        email = "jan.lafferton@vector.com";
      };
      profile.neovim.configDirectory = "/home/jan/.config/nvim";

      networking.hostName = "heatwave-pro";
      vector.proxy-settings.enable = true;

      stylix.colorscheme = "catppuccin-latte";

      environment.systemPackages = with pkgs; [
        distrobox
        github-copilot-cli
        copilot-language-server
        nodejs

        qemu
        bridge-utils
        unixtools.ifconfig
        dnsmasq
      ];

      # Set the suid bit for the qemu-bridge-helper
      security.wrappers.qemu-bridge-helper = {
        owner = "root";
        group = "root";
        setuid = true;
        source = "${pkgs.qemu}/libexec/qemu-bridge-helper";
      };

      services.ollama.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia.open = true;

      environment.sessionVariables = {
        LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
        MESA_D3D12_DEFAULT_ADAPTER_NAME = "Nvidia";
      };

      nix.settings = {
        substituters = [ "http://vistrpesbul1041.vi.vector.int:8080/fenet" ];
        trusted-public-keys = [ "fenet:wgmgt7W5UYsB6UK9izZ1do1aF5xm7R3WAvDw4vEX4Ts=" ];
      };

      systemd.services.nix-daemon.serviceConfig = {
        Environment = [
          "NIX_SSL_CERT_FILE=\"/etc/ssl/certs/ca-certificates.crt\""
          "SSL_CERT_FILE=\"/etc/ssl/certs/ca-certificates.crt\""
        ];
      };

      nixpkgs.hostPlatform = "x86_64-linux";

      virtualisation.podman.dockerCompat = true;

      system.stateVersion = "24.05";
    };
}
