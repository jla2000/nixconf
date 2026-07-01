{ inputs, ... }:
{
  # flake-parts perSystem provides its own pkgs (bare legacyPackages) which
  # does not inherit the NixOS nixpkgs.config.allowUnfree setting. Without
  # this override, packages built through perSystem (e.g. the neovim wrapper)
  # will fail to evaluate unfree dependencies like copilot-language-server.
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    };

  flake.nixosModules.common =
    { pkgs, ... }:
    {
      imports = [ inputs.nix-index-database.nixosModules.default ];
      programs.nix-index-database.comma.enable = true;

      # Misc options
      time.timeZone = "Europe/Berlin";

      # Allow running non-nix binaries
      programs.nix-ld.enable = true;

      environment.variables.EDITOR = "nvim";

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # Global nix settings
      nix = {
        registry.nixpkgs.flake = inputs.nixpkgs;
        settings = {
          auto-optimise-store = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [ "jan" ];
        };
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.bash = {
        enable = true;
        completion.enable = true;
        shellInit = /* bash */ ''
          bind 'TAB:menu-complete'
          set -o vi
        '';
      };

      programs.fish = {
        enable = true;
        interactiveShellInit = /* fish */ ''
          fish_vi_key_bindings
        '';
      };

      environment.systemPackages = with pkgs; [
        uutils-coreutils-noprefix
        eza
        htop-vim
        fzf
        file
        killall
        ripgrep
        duf
        man-pages
        man-pages-posix
        python3
        fishPlugins.bass
        fishPlugins.autopair
        fishPlugins.fzf
      ];

      users.defaultUserShell = pkgs.fish;
    };
}
