{ inputs, ... }:
{
  flake.nixosModules.wsl =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.nixos-wsl.nixosModules.default ];

      wsl = {
        enable = true;
        # /init polls `systemctl is-system-running | grep -E "running|degraded"`
        # and `systemctl is-active user@1000.service` through sh with a bare
        # PATH, so both binaries must exist in /bin or boot and login-session
        # detection time out.
        extraBin = [
          { src = "${config.systemd.package}/bin/systemctl"; }
          { src = "${pkgs.gnugrep}/bin/grep"; }
        ];
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

      # WSL 2.7.3-2.7.11 stopped mounting /mnt/shared_memory in the user distro,
      # so weston's rdp_allocate_shared_memory fails with EIO, sets
      # use_gfxredir=0, and every window falls back to RAIL "[WARN: COPY MODE]"
      # instead of VAIL shared memory. https://github.com/microsoft/wslg/issues/1456
      # The condition matters: once WSL mounts virtiofs there again, stacking
      # tmpfs on top would silently re-break VAIL. Drop this block then.
      systemd.mounts = [
        {
          what = "tmpfs";
          where = "/mnt/shared_memory";
          type = "tmpfs";
          wantedBy = [ "multi-user.target" ];
          unitConfig.ConditionPathIsMountPoint = "!/mnt/shared_memory";
        }
      ];

      # WSL never shuts the VM down cleanly, so journald finds the active
      # journal dirty on every boot and renames it to *.journal~ instead of
      # rotating it. Default SystemMaxUse is 10% of the disk, so on a 1T root
      # that debris is allowed to reach 100G before anything reclaims it.
      services.journald.extraConfig = "SystemMaxUse=500M";

      # The only Windows tools actually used; wrappers keep them on PATH
      # without the slow /mnt/c directories.
      environment.systemPackages = [
        # WSLg has no desktop environment, so nothing else pulls in an icon
        # theme and GTK apps render with blank icons.
        pkgs.adwaita-icon-theme
        (pkgs.writeShellScriptBin "wsl.exe" ''exec /mnt/c/Windows/system32/wsl.exe "$@"'')
        (pkgs.writeShellScriptBin "explorer.exe" ''exec /mnt/c/Windows/explorer.exe "$@"'')
        # xdg-open's WSL branch opens non-file URLs via rundll32.exe.
        (pkgs.writeShellScriptBin "rundll32.exe" ''exec /mnt/c/Windows/system32/rundll32.exe "$@"'')
      ];
    };
}
