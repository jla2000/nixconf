{ self, inputs, ... }:
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

      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "de_DE.UTF-8";
        LC_IDENTIFICATION = "de_DE.UTF-8";
        LC_MEASUREMENT = "de_DE.UTF-8";
        LC_MONETARY = "de_DE.UTF-8";
        LC_NAME = "de_DE.UTF-8";
        LC_NUMERIC = "de_DE.UTF-8";
        LC_PAPER = "de_DE.UTF-8";
        LC_TELEPHONE = "de_DE.UTF-8";
        LC_TIME = "de_DE.UTF-8";
      };

      # Allow running non-nix binaries
      programs.nix-ld.enable = true;

      # Use latest kernel.
      boot.kernelPackages = pkgs.linuxPackages_latest;

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

      programs.zoxide.enable = true;

      programs.bash =
        let
          jj-bookmark-widget = pkgs.writeShellScript "jj-bookmark-widget" /* bash */ ''
            bm=$(jj log -r 'heads(::@ & bookmarks())' --no-graph -T bookmarks 2>/dev/null) || exit 0
            [ -n "$bm" ] && echo "$bm"
            exit 0
          '';
        in
        {
          enable = true;
          completion.enable = true;
          promptInit = /* bash */ ''
            PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '
            RPS1='\e[01;35mJJ_BOOKMARK\e[00m'
          '';
          interactiveShellInit = /* bash */ ''
            enable -f ${self.packages.${pkgs.stdenv.system}.flyline}/lib/libflyline.so flyline

            flyline set-agent-mode \
              --system-prompt "Be concise. Answer with a JSON array of at most 3 items with objects containing: command and description. Command will be a Bash command." \
              --trigger-prefix ': ' \
              --command 'claude --effort low --print'

            flyline create-prompt-widget custom --name JJ_BOOKMARK \
              --command ${jj-bookmark-widget} \
              --block 500 --placeholder prev

            set -o vi
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
      ];
    };
}
