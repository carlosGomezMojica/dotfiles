# Comandos y atajos

Referencia de todo lo que hay configurado en estos dotfiles. `SUPER` es la tecla Windows; el teclado es **Dvorak**, por eso el movimiento usa `H/S/N/T` (izquierda / derecha / arriba / abajo) en lugar de HJKL.

## Hyprland (escritorio)

### Programas y paneles

| Atajo | Función |
| --- | --- |
| `SUPER + RETURN` | Abrir terminal (kitty) |
| `SUPER + E` | Gestor de archivos (yazi en kitty) |
| `SUPER + A` | Lanzador de aplicaciones |
| `SUPER + W` | Selector de tema y wallpaper |
| `SUPER + SHIFT + V` | Historial del portapapeles |
| `SUPER + ,` | Cerrar todas las notificaciones |
| `SUPER + L` | Bloquear la sesión |
| `SUPER + M` | Salir de Hyprland |

### Ventanas y workspaces

| Atajo | Función |
| --- | --- |
| `SUPER + Q` | Cerrar la ventana |
| `SUPER + F` | Alternar ventana flotante |
| `SUPER + P` | Pseudo-tiling |
| `SUPER + J` | Cambiar la orientación del split |
| `SUPER + H / S / N / T` | Foco a la izquierda / derecha / arriba / abajo |
| `SUPER + 1…0` | Ir al workspace 1…10 |
| `SUPER + SHIFT + 1…0` | Mover la ventana al workspace 1…10 |
| `SUPER + SHIFT + H / S` | Workspace anterior / siguiente |
| `SUPER + rueda` | Workspace anterior / siguiente |
| `SUPER + D` | Mostrar / ocultar el workspace especial |
| `SUPER + SHIFT + D` | Mover la ventana al workspace especial |
| `SUPER + clic izquierdo` (arrastrar) | Mover ventana |
| `SUPER + clic derecho` (arrastrar) | Redimensionar ventana |

### Portapapeles

| Atajo | Función |
| --- | --- |
| `SUPER + C` | Copiar (envía `Ctrl+Shift+C`, vale también en la terminal) |
| `SUPER + V` | Pegar (envía `Ctrl+Shift+V`) |
| `SUPER + SHIFT + V` | Historial: `↑↓` / `Ctrl+N/T` moverse, `Enter` copia, `Shift+Supr` borra, `Esc` cierra |

### Capturas de pantalla

| Atajo | Función |
| --- | --- |
| `Print` o `SUPER + SHIFT + P` | Captura de una región |
| `SHIFT + Print` | Captura de una ventana |
| `CTRL + Print` | Captura de la pantalla completa |

Se guardan en `~/Imágenes/Capturas` y se copian al portapapeles. La notificación ofrece **EDITAR** (satty), **COPIAR** y **CARPETA**.

### Teclas multimedia

| Tecla | Función |
| --- | --- |
| Subir / bajar volumen | ±5 % (tope en 100 %) |
| Silenciar | Silenciar la salida de audio |
| Silenciar micrófono | Silenciar la entrada |
| Subir / bajar brillo | ±5 % |

## Quickshell (barra y paneles)

### Teclas dentro de los paneles

| Panel | Teclas |
| --- | --- |
| Lanzador | `↑↓`, `Ctrl+T` (abajo), `Ctrl+N` (arriba), `Ctrl+J/K`; `Enter`/`Tab` abre; `Esc` cierra. Escribe `/font` para cambiar la fuente |
| Selector de tema | `←→`, `Ctrl+H` / `Ctrl+S`, rueda o clic; `Enter` aplica; `Esc` cierra |
| Reproductor MPD: álbumes | `←→`, `Ctrl+H` / `Ctrl+S`, rueda; `Enter` abre el álbum |
| Reproductor MPD: canciones | `↑↓`, `Ctrl+N` / `Ctrl+T`; `Enter` reproduce; `Esc` o `←` vuelve |
| Reproductor MPD: reproduciendo | `Espacio` pausa; `←→` canción anterior / siguiente |
| Red (contraseña) | `Enter` conecta, `Esc` cancela |

### Comandos IPC (`qs ipc call <destino> <función>`)

| Comando | Función |
| --- | --- |
| `qs ipc call launcher toggle\|open\|close` | Lanzador |
| `qs ipc call launcher openWith <texto>` | Abrir el lanzador con un texto escrito (p. ej. `/font`) |
| `qs ipc call themes toggle\|open\|close` | Selector de tema |
| `qs ipc call clipboard toggle\|open\|close` | Historial del portapapeles |
| `qs ipc call notifications dismissAll\|dismissLatest` | Cerrar todas / la última notificación |
| `qs ipc call lock lock` | Bloquear (normalmente con `loginctl lock-session`) |
| `qs ipc call caffeine toggle\|on\|off` | Cafeína: impide apagar la pantalla y suspender |
| `qs ipc call indicators volume\|brightness` | Mostrar el aviso de volumen / brillo |
| `qs ipc call indicators media` | Mostrar la alerta de lo que suena |

## Scripts (`~/.local/bin`)

| Comando | Función |
| --- | --- |
| `theme` | Listar los temas (el activo con `*`) |
| `theme <tema> [wallpaper]` | Aplicar tema y wallpaper a todo (Hyprland, Quickshell, kitty, zsh, nvim, zathura, KDE, greeter) |
| `font` | Listar las fuentes instaladas |
| `font "<familia>"` | Aplicar la fuente a todo el escritorio |
| `captura region\|window\|output` | Captura de pantalla con notificación |
| `captura --satty-config` | Regenerar la config de satty con el tema |
| `kde-colors` | Regenerar los colores de las apps KDE/Qt (lo llama `theme`) |
| `greeter-sync` | Copiar tema, fuente y wallpaper a la pantalla de inicio (lo llaman `theme` y `font`) |

## Terminal (zsh)

| Comando | Función |
| --- | --- |
| `n` | Neovim |
| `lg` | lazygit |
| `cat` | bat (con resaltado) |
| `z <nombre>` | Saltar a la carpeta más visitada que coincida (zoxide) |
| `zi` | Elegir carpeta con fzf |
| `extract <archivo>` / `x <archivo>` | Descomprimir cualquier formato (`-r` borra el original) |

## Neovim

`<leader>` es `Espacio`. Pulsar `<leader>` y esperar muestra todos los atajos (which-key). Aquí están los propios y los más útiles de LazyVim.

### Ventanas y archivos

| Atajo | Función |
| --- | --- |
| `Ctrl + H / S / N / T` | Split de la izquierda / derecha / arriba / abajo (como Hyprland) |
| `Ctrl + S` (insertar) / `:w` | Guardar |
| `-` | Abrir el directorio del archivo en oil (editar el buffer y `:w` renombra, mueve o borra) |
| `g.` (en oil) | Mostrar / ocultar archivos ocultos |
| `<leader>e` | Explorador lateral |
| `<leader><leader>` / `<leader>ff` | Buscar archivo |
| `<leader>/` | Buscar texto en el proyecto |
| `<leader>,` | Buffers abiertos |
| `<leader>gg` | lazygit |
| `y` / `p` | Copiar / pegar con el portapapeles del sistema |

### Código

| Atajo | Función |
| --- | --- |
| `gd` / `gr` | Ir a la definición / referencias |
| `K` | Documentación |
| `<leader>ca` | Acciones de código |
| `<leader>cr` | Renombrar símbolo |
| `<leader>cf` | Formatear |
| `]d` / `[d` | Diagnóstico siguiente / anterior |

### Markdown y notas (vault `~/Documentos/notas`)

| Atajo | Función |
| --- | --- |
| `<leader>um` | Alternar el markdown renderizado |
| `]s` / `[s` | Siguiente / anterior falta de ortografía (español e inglés) |
| `z=` | Sugerencias para la palabra |
| `zg` / `zw` | Añadir la palabra al diccionario / marcarla como incorrecta |
| `<leader>us` | Alternar el corrector |
| `<leader>cp` | Vista previa en el navegador |
| `<leader>ip` | Pegar imagen del portapapeles (en el vault `![[...]]` en `assets/`) |
| `<leader>on` | Nueva nota |
| `<leader>oo` | Buscar nota |
| `<leader>os` | Buscar texto en las notas |
| `<leader>ot` / `<leader>oy` | Nota de hoy / de ayer (en `diario/`) |
| `<leader>ob` | Backlinks |
| `<leader>ol` | Enlaces de la nota |
| `<leader>og` | Etiquetas |
| `<leader>or` | Renombrar nota (actualiza los enlaces) |
| `<leader>oc` | Marcar / desmarcar casilla |
| `[[` | Autocompletar enlace a otra nota |
| `Enter` / `gf` | Seguir un enlace `[[...]]` |

Las imágenes y los bloques ` ```mermaid ` se dibujan dentro del buffer (kitty), con los colores del tema.

### Lenguajes

| Atajo / comando | Función |
| --- | --- |
| `<leader>cf` | Formatear (prettier en web y markdown, `dart format`, `rustfmt`…) |
| `<leader>uf` / `<leader>uF` | Activar o desactivar el formateo al guardar (global / buffer) |
| `:EslintFixAll` | Corregir todo lo que ESLint sabe arreglar |
| Abreviatura Emmet (`div.card>ul>li*3`) | Escribirla y aceptarla en el menú de completado |
| `<leader>cR` | Acciones de código de Rust (rustaceanvim) |
| `:RustLsp runnables` / `:RustLsp testables` | Ejecutar binarios / tests de Rust |
| `<leader>Fr` / `<leader>Fq` | Flutter: ejecutar / parar |
| `<leader>Fl` / `<leader>FR` | Flutter: hot reload / hot restart |
| `<leader>Fd` / `<leader>Fe` | Flutter: dispositivos / emuladores |
| `<leader>Fo` / `<leader>Fc` | Flutter: árbol de widgets / log |

### Claude Code (code-preview.nvim)

| Comando | Función |
| --- | --- |
| `:CodePreviewInstallClaudeCodeHooks` | Activar las vistas previas en el proyecto (luego reiniciar Claude Code) |
| `:CodePreviewUninstallClaudeCodeHooks` | Desactivarlas |
| `<leader>dq` / `:CodePreviewCloseDiff` | Cerrar el diff abierto |
| `:CodePreviewStatus` | Estado de la conexión y los hooks |

### Mantenimiento

| Comando | Función |
| --- | --- |
| `:Lazy` | Plugins (actualizar con `U`) |
| `:Mason` | Servidores de lenguaje y formateadores |
| `:checkhealth` | Diagnóstico |

## Sistema y dotfiles

| Comando | Función |
| --- | --- |
| `cd ~/dotfiles && stow <paquete>` | Enlazar un paquete |
| `stow -R <paquete>` / `stow -D <paquete>` | Re-enlazar / quitar enlaces |
| `hyprctl reload` / `hyprctl configerrors` | Recargar Hyprland / ver errores |
| `qs` | Ejecutar Quickshell en una terminal (muestra errores, recarga al guardar) |
| `pacman -Qqen > packages.txt` / `pacman -Qqem > aur.txt` | Regenerar las listas de paquetes |
| `sudo pacman -S --needed - < packages.txt` / `yay -S --needed - < aur.txt` | Reinstalar paquetes |
| `mise use -g <herramienta>@<versión>` | Instalar una versión global con mise (queda en `mise/.config/mise/config.toml`) |
| `mise use <herramienta>@<versión>` | Fijar la versión en el proyecto actual (`mise.toml`) |
| `rustup update` / `rustup component add rust-analyzer` | Actualizar Rust / instalar su LSP |
| `flutter doctor` | Comprobar qué le falta a Flutter (Android SDK, Chrome…) |
| `systemctl --user enable --now bt-agent` | Agente de bluetooth (emparejar desde el panel) |
| `loginctl lock-session` | Bloquear la sesión |
