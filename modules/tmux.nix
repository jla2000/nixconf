{ self, inputs, ... }:
{
  flake.nixosModules.tmux =
    { pkgs, ... }:
    {
      programs.tmux = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.tmux;
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.tmux = inputs.wrapper-modules.wrappers.tmux.wrap {
        inherit pkgs;
        prefix = "C-s";
        mouse = true;
        escapeTime = 10;
        terminal = "tmux-256color";
        plugins = with pkgs.tmuxPlugins; [
          vim-tmux-navigator
          fingers
        ];
        modeKeys = "vi";
        statusKeys = "vi";
        configAfter = /* tmux */ ''
          set -g status-style "bg=default,fg=default"
          set -g focus-events on
          set -ag terminal-overrides ",xterm-256color:RGB"

          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
          bind-key -T copy-mode-vi i send-keys -X cancel

          # Image nvim
          set -g allow-passthrough on
          set -g visual-activity off

          bind c new-window -c "#{pane_current_path}"
          bind '"' split-window -c "#{pane_current_path}"
          bind % split-window -h -c "#{pane_current_path}"

          bind -n C-g new-window -c "#{pane_current_path}" -n jjui jjui

          # Border style
          set -g popup-border-lines rounded

          # undercurl support
          set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
          set -as terminal-overrides ',*:Setulc=\E[58::2::::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
        '';
      };
    };
}
