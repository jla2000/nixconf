{ inputs, ... }:
{
  flake.nixosModules.wsl =
    { lib, pkgs, ... }:
    {
      imports = [ inputs.nixos-wsl.nixosModules.default ];

      wsl = {
        enable = true;
        startMenuLaunchers = true;
        useWindowsDriver = true;
        interop.register = true;
        defaultUser = "jan";
        wslConf = {
          automount.root = lib.mkDefault "/mnt";
          user.default = lib.mkDefault "jan";
          # Windows PATH dirs live on 9p and make every PATH scan
          # (e.g. flyline completion warming) take seconds.
          interop.appendWindowsPath = false;
        };
      };

      # The only Windows tools actually used; wrappers keep them on PATH
      # without the slow /mnt/c directories.
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "wsl.exe" ''exec /mnt/c/Windows/system32/wsl.exe "$@"'')
        (pkgs.writeShellScriptBin "explorer.exe" ''exec /mnt/c/Windows/explorer.exe "$@"'')
      ];
    };
}
