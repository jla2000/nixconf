{ self, ... }:
{
  flake.nixosModules.flyline =
    { pkgs, ... }:
    let
      jj-bookmark-widget = pkgs.writeShellScript "jj-bookmark-widget" /* bash */ ''
        bm=$(jj log -r 'heads(::@ & bookmarks())' --no-graph -T bookmarks 2>/dev/null) || exit 0
        [ -n "$bm" ] && echo "$bm"
        exit 0
      '';
    in
    {
      programs.bash = {
        promptInit = /* bash */ ''
          PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '
          RPS1='\e[01;35mJJ_BOOKMARK\e[00m'
        '';
        interactiveShellInit = ''
          enable -f ${self.packages.${pkgs.stdenv.system}.flyline}/lib/libflyline.so flyline

          flyline set-agent-mode \
            --system-prompt "Be concise. Answer with a JSON array of at most 3 items with objects containing: command and description. Command will be a Bash command." \
            --trigger-prefix ': ' \
            --command 'claude --effort low --print'

          flyline create-prompt-widget custom --name JJ_BOOKMARK \
            --command ${jj-bookmark-widget} \
            --block 500 --placeholder prev

        '';
      };
    };

  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages.flyline = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "flyline";
        version = "1.3.0";
        __structuredAttrs = true;

        src = pkgs.fetchFromGitHub {
          owner = "HalFrgrd";
          repo = "flyline";
          tag = "v${finalAttrs.version}";
          hash = "sha256-KciBcUsoMCGuw8bHlVBDHAB55lDfyeGoJxBldmj0MVs=";
        };

        cargoHash = "sha256-zTL33etJpEHGPOrw+mUR6JUP1jzPdHBrGYJZjea13WU=";

        passthru.updateScript = pkgs.nix-update-script { };
        doCheck = false;

        meta = {
          description = "Flyline: a Bash plugin to replace readline for a modern line editing experience: syntax highlighting, agent integration, rich prompts, tooltips, fuzzy history search, and more";
          homepage = "https://github.com/HalFrgrd/flyline";
          changelog = "https://github.com/HalFrgrd/flyline/releases/tag/${finalAttrs.src.tag}";
          license = with lib.licenses; [
            gpl3Only
            mit
          ];
          mainProgram = "flyline";
        };
      });
    };
}
