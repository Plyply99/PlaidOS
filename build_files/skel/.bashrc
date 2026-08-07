# .bashrc

# Ghostty shell integration for Bash. This should be at the top of your bashrc!
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
    builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi

# Bash settings
HISTSIZE=-1
HISTFILESIZE=-1
HISTCONTROL=ignoreboth
shopt -s histappend
export HISTCONTROL=ignoreboth:erasedups

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# --- Plaid: terminal settings ---
[ -f '/usr/share/gnome-shell/extensions/plaid@plyply99/plaid-terminal-settings.sh' ] && source '/usr/share/gnome-shell/extensions/plaid@plyply99/plaid-terminal-settings.sh'
# --- end Plaid ---
