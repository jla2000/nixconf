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
        self.nixosModules.ghostty
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

      programs.ssh.startAgent = true;
      stylix.colorscheme = "catppuccin-mocha";

      environment.systemPackages =
        with pkgs;
        let
          grimoire = stdenv.mkDerivation rec {
            name = "grimoire";
            version = "v0.11.1";
            src = fetchTarball {
              url = "https://github.com/grimoire-rs/grimoire/releases/download/${version}/grimoire-x86_64-unknown-linux-gnu.tar.gz";
              sha256 = "sha256:17c7pih7jcaiwcy79fyacxqbr1clq59j6blqyxf59d4821nkn6p3";
            };
            nativeBuildInputs = [ autoPatchelfHook ];
            buildInputs = [ libgcc ];
            installPhase = ''
              install -Dm755 grim $out/bin/grim
            '';
          };
          no-mistakes = stdenv.mkDerivation rec {
            name = "no-mistakes";
            version = "v1.45.3";
            src = fetchurl {
              url = "https://github.com/kunchenguid/no-mistakes/releases/download/${version}/no-mistakes-${version}-linux-amd64.tar.gz";
              hash = "sha256-dohvlOgbP57IDMQEXp3dBGpRP8rRRFCgyaKzeAORKSk=";
            };
            sourceRoot = ".";
            installPhase = ''
              install -Dm755 no-mistakes $out/bin/no-mistakes
            '';
          };
          treehouse = stdenv.mkDerivation rec {
            name = "treehouse";
            version = "v2.1.1";
            src = fetchurl {
              url = "https://github.com/kunchenguid/treehouse/releases/download/${version}/treehouse-${version}-linux-amd64.tar.gz";
              hash = "sha256-L+PgEiCuUalnw+W6bM8Q7IO9uujkIDaNGUKFqNBMnvg=";
            };
            sourceRoot = ".";
            installPhase = ''
              install -Dm755 treehouse $out/bin/treehouse
            '';
          };
          gnhf =
            let
              # gnhf ships a bundled dist/cli.mjs that keeps these three as
              # runtime imports; ESM ignores NODE_PATH, so they have to sit in
              # node_modules next to dist/.
              deps = {
                commander = fetchurl {
                  url = "https://registry.npmjs.org/commander/-/commander-14.0.3.tgz";
                  hash = "sha256-WElwPFAODzJOsBNA2L2h+exI/De7e+lxLrDdUqrZL2w=";
                };
                js-yaml = fetchurl {
                  url = "https://registry.npmjs.org/js-yaml/-/js-yaml-4.3.1.tgz";
                  hash = "sha256-CNYoK3ej5yQgYfbdVRbAGbJcUwQa0me8o7eQ153dXzQ=";
                };
                argparse = fetchurl {
                  url = "https://registry.npmjs.org/argparse/-/argparse-2.0.1.tgz";
                  hash = "sha256-J5A4R/yCFeb8WjPoFJD3urpmQD+KreM3cbmIzKCXcow=";
                };
              };
            in
            stdenv.mkDerivation rec {
              name = "gnhf";
              version = "0.1.43";
              src = fetchurl {
                url = "https://registry.npmjs.org/gnhf/-/gnhf-${version}.tgz";
                hash = "sha256-6l9EAyaO83+jDCmihJ0xugGwIw/RhPr99uF0HujXsvs=";
              };
              nativeBuildInputs = [ makeWrapper ];
              installPhase = ''
                mkdir -p $out/lib/gnhf
                cp -r . $out/lib/gnhf/
                ${lib.concatStrings (
                  lib.mapAttrsToList (dep: tarball: ''
                    mkdir -p $out/lib/gnhf/node_modules/${dep}
                    tar -xzf ${tarball} -C $out/lib/gnhf/node_modules/${dep} --strip-components=1
                  '') deps
                )}
                makeWrapper ${nodejs}/bin/node $out/bin/gnhf \
                  --add-flags $out/lib/gnhf/dist/cli.mjs
              '';
            };
        in
        [
          nodejs
          qemu
          bridge-utils
          unixtools.ifconfig
          dnsmasq
          glab
          jira-cli-go
          hunk
          grimoire
          no-mistakes
          treehouse
          gnhf
          openjdk
          codex
        ];

      # Set the suid bit for the qemu-bridge-helper
      security.wrappers.qemu-bridge-helper = {
        owner = "root";
        group = "root";
        setuid = true;
        source = "${pkgs.qemu}/libexec/qemu-bridge-helper";
      };

      # services.ollama = {
      #   enable = true;
      #   package = pkgs.ollama-cuda;
      # };

      environment.sessionVariables = {
        # GPU access comes from wsl.useWindowsDriver (wsl-lib), not the nvidia
        # driver: there is no /dev/nvidia*, only /dev/dxg. /run/opengl-driver/lib
        # is not on the default loader path, so libcuda needs this.
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
        # There is no /dev/dri, so mesa's loader picks swrast on its own.
        # GALLIUM_DRIVER selects the backend (mesa 26 ignores
        # MESA_LOADER_DRIVER_OVERRIDE now that DRI is libdril-based);
        # the adapter name then picks the dGPU over the Intel iGPU.
        GALLIUM_DRIVER = "d3d12";
        MESA_D3D12_DEFAULT_ADAPTER_NAME = "Nvidia";
        SIP_DIR = "/home/jan/work/pes-bf-communication";
      };

      nix.settings = {
        substituters = [ "http://vistrpesbul1041.vi.vector.int:8080/fenet" ];
        trusted-public-keys = [ "fenet:wgmgt7W5UYsB6UK9izZ1do1aF5xm7R3WAvDw4vEX4Ts=" ];
        # The 1 MiB default throttles substitution from a LAN-local cache.
        download-buffer-size = 512 * 1024 * 1024;
      };

      boot.tmp.cleanOnBoot = true;

      # podman leaks multi-GB scratch files here on interrupted pulls, and the
      # tmpfiles default of 30d lets them pile up.
      systemd.tmpfiles.rules = [ "d /var/tmp 1777 root root 7d" ];

      systemd.services.nix-daemon.serviceConfig = {
        Environment = [
          "NIX_SSL_CERT_FILE=\"/etc/ssl/certs/ca-certificates.crt\""
          "SSL_CERT_FILE=\"/etc/ssl/certs/ca-certificates.crt\""
        ];
      };

      nixpkgs.hostPlatform = "x86_64-linux";
      nix.settings.sandbox-dev-shm-size = "1G";

      system.stateVersion = "24.05";
    };
}
