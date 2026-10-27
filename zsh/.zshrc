# Configuración de zsh: powerlevel10k con los colores del tema (theme.zsh)

# Instant prompt de p10k: muestra el prompt al instante mientras carga el resto.
# Todo lo que pida entrada por consola debe ir antes de este bloque.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Historial compartido entre terminales y sin duplicados
mkdir -p ~/.cache/zsh
HISTFILE=~/.cache/zsh/history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks

# Autocompletado (menú con flechas, sin distinguir mayúsculas)
autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

setopt auto_cd interactive_comments
bindkey -e

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias n='nvim'
alias lg='lazygit'
# bat en lugar de cat: con resaltado y números, sin paginador. El tema `ansi` usa los
# 16 colores de kitty, así que sigue al tema activo. Por tubería se comporta como cat.
if command -v bat >/dev/null; then
    export BAT_THEME=ansi
    alias cat='bat --paging=never'
fi

command -v mise >/dev/null && eval "$(mise activate zsh)"
# zoxide: `z carpeta` salta a la más visitada que coincida; `zi` la elige con fzf
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Prompt: el estilo lo genera `p10k configure` (~/.p10k.zsh) y los colores salen del tema
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Plugins (syntax-highlighting siempre el último)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.config/zsh/theme.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
