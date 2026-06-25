{ self, inputs, ... }:
{
  flake.nixosModules.herdr =
    { pkgs, ... }:
    {
      environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.herdr ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.herdr = inputs.wrapper-modules.lib.wrapPackage (
        { ... }:
        {
          inherit pkgs;
          package = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
          env.HERDR_CONFIG_PATH = ../config/herdr/config.toml;
        }
      );
    };
}
