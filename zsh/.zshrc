# Configuración de zsh: powerlevel10k con los colores del tema (theme.zsh)

# Instant prompt de p10k: muestra el prompt al instante mientras carga el resto.
# Todo lo que pida entrada por consola debe ir antes de este bloque.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Scripts propios (theme, font, gitSyncBranch…) en el PATH, sin duplicar al recargar
typeset -U path
path=(~/.local/bin $path)

# Historial compartido entre terminales y sin duplicados
mkdir -p ~/.cache/zsh
HISTFILE=~/.cache/zsh/history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks

# Autocompletado (menú con flechas, sin distinguir mayúsculas)
# _extract: completado del plugin extract (zsh-extract-git, AUR)
fpath+=(/usr/share/zsh/plugins/zsh-extract)
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
# lsd en lugar de ls: iconos (Nerd Font) y colores; sin él queda el ls de arriba.
command -v lsd >/dev/null && alias ls='lsd'

if command -v mise >/dev/null; then
    eval "$(mise activate zsh)"
    # Claude Code siempre con node 24, aunque el proyecto fije otra versión en su mise.toml
    alias claude='mise exec node@24 -- claude'
fi
# zoxide: `z carpeta` salta a la más visitada que coincida; `zi` la elige con fzf
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Prompt: el estilo lo genera `p10k configure` (~/.p10k.zsh) y los colores salen del tema
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Plugins (syntax-highlighting siempre el último)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# extract (de oh-my-zsh): `extract archivo` (o `x`) descomprime casi cualquier formato
[[ -f /usr/share/zsh/plugins/zsh-extract/extract.plugin.zsh ]] && source /usr/share/zsh/plugins/zsh-extract/extract.plugin.zsh
source ~/.config/zsh/theme.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Autocompletado de Angular CLI, solo si `ng` responde con la versión de node activa
# (el shim de mise falla y ensucia el instant prompt si no está en esa versión)
if command -v ng >/dev/null && ng_completion=$(ng completion script 2>/dev/null); then
    source <(print -r -- "$ng_completion")
fi
unset ng_completion
