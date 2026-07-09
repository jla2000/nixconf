{ inputs, ... }:
{
  flake.nixosModules.dev-tools =
    { pkgs, lib, ... }:
    {
      programs.bat.enable = true;

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableBashIntegration = true;
      };

      environment.systemPackages = with pkgs; [
        fd
        gdb
        nh
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
