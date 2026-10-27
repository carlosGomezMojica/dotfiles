# Colores del tema activo (~/.config/theme) para powerlevel10k, autosuggestions y
# syntax-highlighting. Lee la paleta JSON directamente y, si `theme` cambia de tema,
# la vuelve a leer antes del siguiente prompt (las terminales abiertas también cambian).

zmodload -F zsh/stat b:zstat
typeset -gA theme_color
typeset -g _theme_dir=~/.config/theme _theme_mtime=

# Paleta activa → theme_color[token] = '#rrggbb' (el JSON es plano: una clave por línea)
_theme_read() {
    local name line file
    name="$(<$_theme_dir/current)" 2>/dev/null || return 1
    file=$_theme_dir/palettes/$name.json
    [[ -r $file ]] || return 1
    theme_color=()
    for line in "${(@f)$(<$file)}"; do
        [[ $line =~ '"([a-z0-9_]+)" *: *"(#[0-9a-fA-F]{6})"' ]] && theme_color[$match[1]]=$match[2]
    done
    (( ${#theme_color} ))
}

# powerlevel10k. El estilo del asistente se deduce de POWERLEVEL9K_BACKGROUND:
#   vacío (lean, pure) → solo colores de texto
#   con valor (classic) → fondo común `surface` y colores de texto
#   sin definir (rainbow) → cada segmento con su color de fondo y texto `bg`
_theme_p10k() {
    local -A c=("${(@kv)theme_color}")
    local s

    if (( ! ${+POWERLEVEL9K_BACKGROUND} )); then
        typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=$c[bg] POWERLEVEL9K_OS_ICON_BACKGROUND=$c[text]
        typeset -g POWERLEVEL9K_DIR_FOREGROUND=$c[bg] POWERLEVEL9K_DIR_BACKGROUND=$c[accent]
        typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=$c[surface]
        typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=$c[bg]
        typeset -g POWERLEVEL9K_VCS_{CLEAN,MODIFIED,UNTRACKED,CONFLICTED,LOADING}_FOREGROUND=$c[bg]
        typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=$c[success]
        typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=$c[warning]
        typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=$c[info]
        typeset -g POWERLEVEL9K_VCS_CONFLICTED_BACKGROUND=$c[error]
        typeset -g POWERLEVEL9K_VCS_LOADING_BACKGROUND=$c[muted]
        typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=$c[success] POWERLEVEL9K_STATUS_OK_BACKGROUND=$c[surface]
        for s in ERROR ERROR_SIGNAL ERROR_PIPE; do
            typeset -g POWERLEVEL9K_STATUS_${s}_FOREGROUND=$c[bg] POWERLEVEL9K_STATUS_${s}_BACKGROUND=$c[error]
        done
        typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$c[bg]
        typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=$c[yellow]
        typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$c[aqua] POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=$c[surface]
        typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=$c[muted] POWERLEVEL9K_CONTEXT_BACKGROUND=$c[surface]
        typeset -g POWERLEVEL9K_CONTEXT_{ROOT,REMOTE,REMOTE_SUDO}_FOREGROUND=$c[error]
        typeset -g POWERLEVEL9K_CONTEXT_{ROOT,REMOTE,REMOTE_SUDO}_BACKGROUND=$c[surface]
        typeset -g POWERLEVEL9K_TIME_FOREGROUND=$c[text] POWERLEVEL9K_TIME_BACKGROUND=$c[surface]
    else
        [[ -n $POWERLEVEL9K_BACKGROUND ]] && typeset -g POWERLEVEL9K_BACKGROUND=$c[surface]
        typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=$c[text]
        typeset -g POWERLEVEL9K_DIR_FOREGROUND=$c[accent]
        typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=$c[muted]
        typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=$c[accent]
        typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=$c[success]
        typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=$c[warning]
        typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=$c[info]
        typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=$c[error]
        typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=$c[muted]
        typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=$c[success]
        typeset -g POWERLEVEL9K_STATUS_{ERROR,ERROR_SIGNAL,ERROR_PIPE}_FOREGROUND=$c[error]
        typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$c[yellow]
        typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$c[aqua]
        typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=$c[muted]
        typeset -g POWERLEVEL9K_CONTEXT_{ROOT,REMOTE,REMOTE_SUDO}_FOREGROUND=$c[error]
        typeset -g POWERLEVEL9K_TIME_FOREGROUND=$c[muted]
        typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=$c[success]
        # Entornos (lenguajes, nube, contenedores): info; shells anidadas en gestores
        # de archivos: aqua; tareas e historial: muted
        for s in DIRENV ASDF VIRTUALENV ANACONDA PYENV GOENV NODENV NVM NODEENV RBENV RVM \
                 FVM LUAENV JENV PLENV PERLBREW PHPENV SCALAENV HASKELL_STACK \
                 KUBECONTEXT_DEFAULT TERRAFORM_OTHER TERRAFORM_VERSION AWS_DEFAULT AWS_EB_ENV \
                 AZURE_OTHER GCLOUD GOOGLE_APP_CRED_DEFAULT TOOLBOX NIX_SHELL CHEZMOI_SHELL NORDVPN; do
            typeset -g POWERLEVEL9K_${s}_FOREGROUND=$c[info]
        done
        for s in RANGER YAZI NNN LF XPLR VIM_SHELL MIDNIGHT_COMMANDER; do
            typeset -g POWERLEVEL9K_${s}_FOREGROUND=$c[aqua]
        done
        for s in TODO TIMEWARRIOR TASKWARRIOR PER_DIRECTORY_HISTORY_{LOCAL,GLOBAL}; do
            typeset -g POWERLEVEL9K_${s}_FOREGROUND=$c[muted]
        done
    fi

    # Comunes a todos los estilos
    for s in VIINS VICMD VIVIS VIOWR; do
        typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_${s}_FOREGROUND=$c[success]
        typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_${s}_FOREGROUND=$c[error]
    done
    typeset -g POWERLEVEL9K_MULTILINE_{FIRST,NEWLINE,LAST}_PROMPT_GAP_FOREGROUND=$c[border_inactive]
    typeset -g POWERLEVEL9K_RULER_FOREGROUND=$c[border_inactive]
}

# Sugerencias y resaltado de la línea de comandos
_theme_zle() {
    local -A c=("${(@kv)theme_color}")
    typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$c[muted]"
    typeset -gA ZSH_HIGHLIGHT_STYLES
    ZSH_HIGHLIGHT_STYLES[command]="fg=$c[success]"
    ZSH_HIGHLIGHT_STYLES[builtin]="fg=$c[success]"
    ZSH_HIGHLIGHT_STYLES[alias]="fg=$c[success]"
    ZSH_HIGHLIGHT_STYLES[function]="fg=$c[success]"
    ZSH_HIGHLIGHT_STYLES[precommand]="fg=$c[success],underline"
    ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=$c[accent]"
    ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=$c[error]"
    ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=$c[accent]"
    ZSH_HIGHLIGHT_STYLES[path]="fg=$c[info],underline"
    ZSH_HIGHLIGHT_STYLES[globbing]="fg=$c[aqua]"
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=$c[aqua]"
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=$c[aqua]"
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=$c[yellow]"
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=$c[yellow]"
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=$c[yellow]"
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]="fg=$c[warning]"
    ZSH_HIGHLIGHT_STYLES[redirection]="fg=$c[warning]"
    ZSH_HIGHLIGHT_STYLES[comment]="fg=$c[muted]"
}

# Antes de cada prompt: si `theme` escribió otro tema, releer y aplicar
_theme_sync() {
    local mtime
    mtime=$(zstat +mtime $_theme_dir/current 2>/dev/null) || return
    [[ $mtime == $_theme_mtime ]] && return
    local first=$(( ! ${#_theme_mtime} ))
    _theme_mtime=$mtime
    _theme_read || return
    _theme_p10k
    _theme_zle
    # Al arrancar p10k aún no ha pintado: basta con las variables
    (( first )) || p10k reload
}

_theme_sync
# Delante de los hooks de p10k para que el prompt ya salga con los colores nuevos
precmd_functions=(_theme_sync ${precmd_functions:#_theme_sync})
