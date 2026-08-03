{ inputs, ... }:
{
  flake.nixosModules.ghostty =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (inputs.wrapper-modules.lib.wrapPackage (
          { config, ... }:
          {
            inherit pkgs;
            package = pkgs.ghostty;
            flagSeparator = "=";
            flags."--config-file" = config.constructFiles.generatedConfig.path;
            constructFiles.generatedConfig = {
              content = ''
                font-size = 13.5
                window-decoration = server
              '';
              relPath = "ghostty-config";
            };
          }
        ))
      ];
    };
}
