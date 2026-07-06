{ ... }:
{
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
