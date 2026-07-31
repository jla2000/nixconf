{ self, ... }:
{
  flake.nixosModules.zephyrus-gpu-passthrough =
    { pkgs, lib, ... }:
    let
      # Pinned to the exact commit the Windows host app was built from. Looking
      # Glass requires client and host to match: nixpkgs ships the B7 release,
      # which puts the LGMP header at a different offset than this master build
      # and so reports "host application seems to not be running".
      looking-glass = pkgs.looking-glass-client.overrideAttrs (old: {
        version = "B7-356-g6a0526fc1e";
        src = pkgs.fetchFromGitHub {
          owner = "gnif";
          repo = "LookingGlass";
          rev = "6a0526fc1e900e5058f4a09323f0ffa45bf044fc";
          fetchSubmodules = true;
          hash = "sha256-njBNaN2rlRlzzqtA8TWckAS+kGiTrmPKgiKWlR7OlIM=";
        };

        # Drop the upstream launcher entry. It starts a bare client with no
        # domain and no SPICE port, so it connects to the default 5900 (which is
        # VNC here) and dies. Sitting next to "Windows VM" in the menu it is
        # just a trap; the binary is still on PATH for manual use.
        postInstall = (old.postInstall or "") + ''
          rm -f "$out/share/applications/looking-glass-client.desktop"
        '';
      });

      # Boots the guest, attaches Looking Glass, and shuts the guest down again
      # when the window closes.
      windows-vm = pkgs.writeShellApplication {
        name = "windows-vm";
        runtimeInputs = [
          pkgs.libvirt
          pkgs.coreutils
          pkgs.gnugrep
          looking-glass
        ];
        text = ''
          uri=qemu:///system
          domain=win11
          shm=/dev/shm/looking-glass

          state() {
            virsh -c "$uri" domstate "$domain" 2>/dev/null | tr -d '[:space:]'
          }

          # Shut the guest down when the client exits, however it exits.
          cleanup() {
            if [ "$(state)" != "running" ]; then
              return 0
            fi
            virsh -c "$uri" shutdown "$domain" >/dev/null 2>&1 || true
            i=0
            while [ "$i" -lt 90 ]; do
              if [ "$(state)" = "shutoff" ]; then
                return 0
              fi
              sleep 2
              i=$((i + 1))
            done
            # Guest ignored ACPI shutdown (installer, blocked dialog, hung app).
            virsh -c "$uri" destroy "$domain" >/dev/null 2>&1 || true
          }
          trap cleanup EXIT

          if [ "$(state)" != "running" ]; then
            virsh -c "$uri" start "$domain"
          fi

          # The host app only publishes its LGMP header once Windows has booted
          # far enough to start capturing; connecting before that just fails.
          # Process substitution, not a pipe: grep -q exits on the first match,
          # which SIGPIPEs head, and pipefail would turn that into a failed
          # condition. As a pipeline this check can never succeed, so the loop
          # always burns the full timeout before connecting.
          i=0
          while [ "$i" -lt 120 ]; do
            if grep -qa LGMP < <(head -c 4194304 "$shm" 2>/dev/null); then
              break
            fi
            sleep 1
            i=$((i + 1))
          done

          # autoport means the SPICE port moves between boots, so read it back.
          # SPICE carries keyboard and mouse; Looking Glass only carries video.
          spiceurl=$(virsh -c "$uri" domdisplay --all "$domain" 2>/dev/null \
            | grep '^spice://' | head -1 || true)
          spiceport=''${spiceurl##*:}

          # Open windowed, and do not size the window at startup: no -F
          # (fullscreen) and no -T (maximize). KWin drives this panel at 1.45
          # fractional scale (2560x1600 native, 1766x1104 logical), and the
          # Wayland surface scale is only negotiated once the surface is mapped.
          # Any startup sizing flag therefore commits to the logical size, and
          # the guest display driver follows it, ending up cropped and resampled.
          # Maximize or fullscreen by hand once the window is up.
          #
          # Everything scaling-related is left at upstream defaults on purpose.
          # Overriding wayland:fractionScale or win:setGuestRes compensates for
          # this in the wrong place and breaks differently.
          lgopts=(
            -S
            input:escapeKey=KEY_RIGHTCTRL
            input:captureOnFocus=yes
            input:rawMouse=yes
          )

          if [ -z "$spiceport" ]; then
            echo "warning: no SPICE port found, input will not work" >&2
            looking-glass-client "''${lgopts[@]}" || true
          else
            looking-glass-client "''${lgopts[@]}" \
              spice:host=127.0.0.1 "spice:port=$spiceport" || true
          fi
        '';
      };

      windows-vm-desktop = pkgs.makeDesktopItem {
        name = "windows-vm";
        desktopName = "Windows VM";
        comment = "Boot the Windows guest and attach Looking Glass";
        exec = "${windows-vm}/bin/windows-vm";
        icon = "computer";
        categories = [ "System" ];
        terminal = false;
      };
    in
    {
      boot.kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "vfio_pci.ids=1002:73ef,1002:ab28"
        "vfio_pci.disable_vga=1"
      ];

      # vfio-pci has to claim the dGPU in the initrd, before amdgpu gets a chance.
      # Loading it from boot.kernelModules (stage 2) is too late: amdgpu binds
      # 03:00.0 first and fully brings up the ASIC (PSP/SMU/DMUB). A later
      # hot-unbind hands Windows a half-initialised Navi 23, which is what makes
      # the Adrenalin installer hang while loading the display driver.
      boot.initrd.kernelModules = [
        "vfio_pci"
        "vfio_iommu_type1"
        "vfio"
      ];

      # softdep forces vfio-pci to load ahead of amdgpu even if amdgpu is pulled
      # in early for the iGPU (07:00.0), which must stay on amdgpu.
      boot.extraModprobeConfig = ''
        options vfio-pci ids=1002:73ef,1002:ab28 disable_vga=1
        softdep amdgpu pre: vfio-pci
      '';

      virtualisation.libvirtd = {
        qemu = {
          package = pkgs.qemu_kvm;
          swtpm.enable = true;
        };
      };

      environment.systemPackages = [
        looking-glass
        windows-vm
        windows-vm-desktop
      ];

      # qemu sizes this file itself (see windows-vm.xml, currently 128 MiB); the
      # rule only fixes ownership so the client can read it as a member of kvm.
      systemd.tmpfiles.rules = [
        "f /dev/shm/looking-glass 0660 qemu-libvirtd kvm - -"
      ];


      security.sudo.wheelNeedsPassword = false;

      # libvirtd, not libvirt: NixOS names the group after the daemon, and the
      # polkit rule in 10-nixos.rules grants this group passwordless access to
      # qemu:///system. Being in wheel alone still prompts.
      users.users.jan.extraGroups = [
        "kvm"
        "libvirtd"
      ];
    };
}
