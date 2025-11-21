{ config, pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";

    # Basic settings
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
    mouse = true;
    keyMode = "vi";
    secureSocket = false;
    newSession = true;

    plugins = [
      pkgs.tmuxPlugins.catppuccin
    ];

    # Import your existing configuration
    extraConfig = ''
      # Set default shell to fish

      # Ensure EDITOR is passed through to tmux sessions
      set -g update-environment "DISPLAY KRB5CCNAME MSYSTEM SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"
      set -ag update-environment "EDITOR"
      set -ag update-environment "KUBECONFIG"
      set -ag update-environment "DEPLOYED_BY"

      # remove SSH_AUTH_SOCK from the default environment
      # set -ug update-environment SSH_AUTH_SOCK
      setenv -g SSH_AUTH_SOCK ${config.home.homeDirectory}/.ssh/ssh_auth_sock

      set -g default-terminal "$TERM"
      set -ag terminal-overrides ",$TERM:Tc"

      # Renumber windows when one is closed
      set-option -g renumber-windows on

      # Hotkeys using Alt/Option as a modifier
      bind-key -n M-n new-window -c "#{pane_current_path}"
      bind-key -n M-1 select-window -t :1
      bind-key -n M-2 select-window -t :2
      bind-key -n M-3 select-window -t :3
      bind-key -n M-4 select-window -t :4
      bind-key -n M-5 select-window -t :5
      bind-key -n M-6 select-window -t :6
      bind-key -n M-7 select-window -t :7
      bind-key -n M-8 select-window -t :8
      bind-key -n M-9 select-window -t :9
      bind-key -n M-0 select-window -t :0
      bind-key -n M-. select-window -n
      bind-key -n M-, select-window -p
      bind-key -n M-< swap-window -t -1
      bind-key -n M-> swap-window -t +1
      bind-key -n M-X confirm-before "kill-window"
      bind-key -n M-- split-window -v -c "#{pane_current_path}"
      bind-key -n M-\\ split-window -h -c "#{pane_current_path}"
      bind-key -n M-v split-window -h -c "#{pane_current_path}"
      bind-key -n M-V split-window -v -c "#{pane_current_path}"
      bind-key -n M-R command-prompt -I "#W" "rename-window '%%'"

      bind-key -n M-f resize-pane -Z
      bind-key -n M-h select-pane -L
      bind-key -n M-l select-pane -R
      bind-key -n M-k select-pane -U
      bind-key -n M-j select-pane -D
      bind-key -n M-Left select-pane -L
      bind-key -n M-Right select-pane -R
      bind-key -n M-Up select-pane -U
      bind-key -n M-Down select-pane -D
      bind-key -n "M-H" if-shell -F '#{==:#{pane_at_left},0}' 'select-pane -m \; select-pane -L \; swap-pane \; select-pane -M'
      bind-key -n "M-J" if-shell -F '#{==:#{pane_at_bottom},0}' 'select-pane -m \; select-pane -D \; swap-pane \; select-pane -M'
      bind-key -n "M-K" if-shell -F '#{==:#{pane_at_top},0}' 'select-pane -m \; select-pane -U \; swap-pane \; select-pane -M'
      bind-key -n "M-L" if-shell -F '#{==:#{pane_at_right},0}' 'select-pane -m \; select-pane -R \; swap-pane \; select-pane -M'
      bind-key -n "M-S-Left" if-shell -F '#{==:#{pane_at_left},0}' 'select-pane -m \; select-pane -L \; swap-pane \; select-pane -M'
      bind-key -n "M-S-Down" if-shell -F '#{==:#{pane_at_bottom},0}' 'select-pane -m \; select-pane -D \; swap-pane \; select-pane -M'
      bind-key -n "M-S-Up" if-shell -F '#{==:#{pane_at_top},0}' 'select-pane -m \; select-pane -U \; swap-pane \; select-pane -M'
      bind-key -n "M-S-Right" if-shell -F '#{==:#{pane_at_right},0}' 'select-pane -m \; select-pane -R \; swap-pane \; select-pane -M'
      bind-key -n M-x confirm-before "kill-pane"

      bind-key -n M-/ copy-mode
      bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "nc -q1 127.0.0.1 2224"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "nc -q1 127.0.0.1 2224"

      set-option -g status-keys vi
      set-option -g set-titles on
      set-option -g set-titles-string 'tmux - #W'
      set -g bell-action any
      set-option -g visual-bell off
      set-option -g set-clipboard off

      setw -g monitor-activity on

      # Notifications
      set -g visual-activity on

      # Statusbar (commented while testing catppuccin theme)
      # set -g status-style fg=colour15
      # set -g status-justify centre
      # set -g status-left ""
      # set -g status-right ""
      # set -g status-interval 1

      # set -g message-style fg=colour0,bg=colour3
      # setw -g window-status-current-style fg=yellow,bold
      # setw -g window-status-current-format ' #W '
      # setw -g window-status-style fg=colour250
      # setw -g window-status-format ' #W '
      # setw -g window-status-bell-style fg=colour1
    '';
  };

}
