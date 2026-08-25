{ inputs, ... }:
{
  flake.nixosModules.dev-tools =
    { pkgs, lib, ... }:
    let
      how = pkgs.writeShellApplication {
        name = "how";
        runtimeInputs = [ pkgs.claude-code ];
        text = /* bash */ ''
          if [ $# -eq 0 ]; then
            echo "usage: how <what you want to do>" >&2
            exit 2
          fi

          cmd=$(claude --print --effort low --tools "" --no-session-persistence \
            --system-prompt "Output a single bash command doing what the user asks.
          Output ONLY the raw command: no markdown fences, no backticks, no explanation.
          Prefer POSIX/coreutils. Shell is bash on NixOS. Current directory: $PWD.
          If the request is impossible, output: false" \
            -- "$*")

          [ -n "$cmd" ] || { echo "how: no command returned" >&2; exit 1; }

          printf '%s\n' "$cmd"
          read -r -p "run? [y/N] " ans < /dev/tty
          # ponytail: subshell, so `cd`/`export` do not persist into the caller
          case "$ans" in
            [yY]) exec bash -c "$cmd" ;;
            *) exit 1 ;;
          esac
        '';
      };
    in
    {
      programs.bat.enable = true;

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableBashIntegration = true;
      };

      environment.systemPackages = with pkgs; [
        how
        fd
        gdb
        nix-output-monitor
        sd
        gcc
        gnumake
        tree
        fastfetch
        scc
        zig
        cargo
        rustc
        rust-analyzer
        gh
        mesa-demos
        xclip
        xdg-utils
        unixtools.xxd
        bacon
        rusty-man
        jjui
        lazyjj
        attic-client

        # LSP's
        zls
        zuban
        clang-tools
        nixd
        taplo
        lua-language-server
        wgsl-analyzer
        lldb
        glsl_analyzer

        # Formatter
        stylua
        marksman
        markdownlint-cli2
        shfmt
        nixfmt
      ];
    };
}
