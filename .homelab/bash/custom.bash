export PATH="$HOME/.homelab/bin:$PATH"

export EDITOR='vim'
export VISUAL="$EDITOR"

command -v tty-color-tool &>/dev/null && eval "$(tty-color-tool set-soft $HOME/.homelab/tty-colors/tty-colors-no-lg.txt)"
command -v tty-color-tool &>/dev/null && eval "$(tty-color-tool rc-bash)"
