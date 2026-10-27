# dotfiles

Configuración personal de **Arch Linux + Hyprland**, con una shell propia escrita en **Quickshell** (QML) y un sistema de temas (colores + wallpapers) compartido por Hyprland, Quickshell y kitty. Teclado **Dvorak** (`dvorak-intl`).

## Qué incluye

| Paquete | Destino | Contenido |
|---|---|---|
| `hypr/` | `~/.config/hypr` | Hyprland con la **API Lua** (`hyprland.lua` + módulos `keybinds`, `animations`, `theme`) |
| `quickshell/` | `~/.config/quickshell` | Barra superior, cápsula de red, indicadores de volumen y brillo, notificaciones, panel de batería, lanzador, fondo de escritorio y selector de tema |
| `theme/` | `~/.config/theme`, `~/.local/bin` | Paletas de color, wallpapers por tema y script `theme` para cambiarlos |
| `kitty/` | `~/.config/kitty` | `kitty.conf` (incluye los colores del tema activo) |
| `nvim/` | `~/.config/nvim` | Neovim con **LazyVim**, los colores del tema (cambian en caliente) y LSP para Lua, QML, shell y web |
| `lazygit/` | `~/.config/lazygit` | lazygit con iconos Nerd y los colores ANSI de la terminal (siguen al tema) |
| `qt/` | `~/.config/environment.d` | `QT_QPA_PLATFORMTHEME=kde`: Dolphin y apps Qt/KDE con los colores del tema |
| `yazi/` | `~/.config/yazi` | yazi: los PDF se abren con zathura |
| `zathura/` | `~/.config/zathura` | zathura (visor de PDF) con los colores del tema |
| `zsh/` | `~/.zshrc`, `~/.config/zsh` | zsh con **powerlevel10k**, autosugerencias y resaltado de sintaxis, con los colores del tema |
| `bluetooth/` | `~/.config/systemd/user` | Servicio `bt-agent` (agente de BlueZ para emparejar desde el panel) |
| `mpd/` | `~/.config/mpd`, `~/.config/systemd/user` | MPD (biblioteca en `~/Música`) y ajuste del servicio `mpd-mpris` |
| `packages.txt` / `aur.txt` | — | Paquetes oficiales y de AUR |

### Barra (Quickshell)
- **Cafeína**: a la izquierda del todo de la cápsula expandida, una taza (gris apagada, amarilla activa). Activa, la pantalla no se apaga ni el equipo se suspende por inactividad (normalmente: pantalla apagada a los 10 min y suspensión a los 30, con **hypridle**).
- **Uso de IA (Claude Code)** a la izquierda de los workspaces: plegada, 5 segmentos naranjas con el uso de la sesión; expandida, un robot con el %. Al pulsarlo, un panel al estilo del de batería con la sesión de 5 h y su reinicio, el uso semanal, los tokens (sesión, hoy y semana) y el próximo reinicio semanal. Los límites salen de la API de uso de Anthropic con la sesión de Claude Code (como en Omarchy) y los tokens de sus registros locales.
- Cápsula superior que **se auto-oculta**: oculta muestra barritas finas de los 9 workspaces y 10 segmentos de batería; al pasar el ratón se expande con puntos clicables y el icono de pila con el porcentaje.
- **Panel de batería**: al pulsar la pila se despliega una tarjeta con el nivel en un anillo de puntos, tiempo restante, salud (capacidad real frente a la de diseño), ciclos de carga, consumo y selector de **perfil de energía** (ahorro / equilibrado / rendimiento, vía `power-profiles-daemon`).

### Red (Quickshell)
- Cápsula arriba a la izquierda con 4 segmentos de señal (verde, ámbar si la conectividad es limitada, rojo sin red).
- Al pasar el ratón muestra el **reloj** y el nombre de la red. Al pulsar el reloj se abre el **calendario**: día de la semana y fecha, el mes (flechas para cambiar, clic en el mes para volver a hoy) y cuánto queda del año en porcentaje, días restantes y semana.
- Al pulsar la red se abre el panel de conexión: red actual con su IP, señal, seguridad e interfaz, y las redes wifi cercanas (clic para conectar o desconectar, olvidar las guardadas con doble confirmación, interruptor de wifi y campo de contraseña para redes nuevas: Enter conecta, Esc cancela).

### Bluetooth (en la cápsula de red)
- Barrita junto a la señal wifi: **azul** con un dispositivo conectado, **roja** encendido sin conexión, **gris** apagado. Arranca apagado en cada sesión.
- Al pulsar la zona del bluetooth: interruptor, dispositivos emparejados (conectar, desconectar, olvidar con doble confirmación y batería si la reportan) y **BUSCAR** para emparejar dispositivos nuevos. Los que piden PIN se emparejan con `bluetoothctl`.

### Indicadores (arriba a la derecha)
- Cápsula con una barra horizontal en **aqua** que se mueve con el audio que está sonando.
- Al subir o bajar el **volumen** se expande un momento con la barra y el porcentaje en **rojo**; con el **brillo**, en **amarillo**.
- **Al pulsarla** se abre el panel multimedia: carátula con reflejo al estilo iPod y el título encima, tiempo de reproducción, botones anterior / reproducir-pausa / siguiente, y sliders de volumen y brillo (clic en el porcentaje de volumen para silenciar). Pestañas **MPRIS** (lo que suene en cualquier app) y **MPD**.
- Cuando empieza a sonar algo (o se reanuda), muestra unos segundos la **carátula**, el título y el artista con la app que lo reproduce (MPRIS).
- Al pasar el ratón muestra el volumen en **rojo** y el brillo en **amarillo** (icono y porcentaje); si está sonando algo, a su izquierda aparecen la carátula, el título y la app. Deslizando **dos dedos** en el touchpad (o con la rueda) sobre cada uno se sube o baja ese nivel.

### Reproductor de música (MPD)
- En la pestaña **MPD** del panel multimedia: tus álbumes de `~/Música` en **cover flow** con reflejo. Muévete con `←` `→`, `Ctrl+H` / `Ctrl+S`, la rueda o dos dedos en el touchpad; `Enter` o clic en la carátula central abre el álbum.
- Lista de canciones del álbum (la que suena en aqua): `↑` `↓` o `Ctrl+N` / `Ctrl+T` para moverte, `Enter` o clic para reproducir desde ahí, `Esc` vuelve a los álbumes.
- Reproduciendo: carátula con reflejo, título, álbum y artista, tiempo (clic para saltar) y anterior / reproducir-pausa / siguiente (también `←` `→` y `Espacio`).
- Carátulas: `cover.jpg`/`folder.jpg`/`front.jpg` de la carpeta del álbum o la imagen incrustada en el archivo.

### Bloqueo e inicio de sesión
- **Bloqueo** (`SUPER + L`, a los 10 min de inactividad junto con el apagado de pantalla y antes de suspender): el wallpaper desenfocado, la hora grande sobre cristal con la fecha, tu usuario y la contraseña, batería, red y DVORAK arriba, lo que suena abajo a la izquierda (con controles) y suspender / reiniciar / apagar abajo a la derecha.
- **Inicio de sesión** con el mismo diseño (greetd + Quickshell), teclado Dvorak y selector de sesión. Sigue el tema, la fuente y el wallpaper que elijas. Instalación: `sudo pacman -S greetd`, `sudo greeter/install.sh` y, tras probar, `sudo greeter/install.sh --enable` (vuelta atrás: `sudo systemctl disable greetd && sudo systemctl enable sddm`).

### Portapapeles
- `SUPER + SHIFT + V` abre el historial de todo lo copiado (texto, enlaces e imágenes, vía **cliphist**), con el diseño del lanzador: buscador, lista y vista previa.
- `↑` `↓` o `Ctrl+N` / `Ctrl+T` para moverte, `Enter` o clic copia la entrada (pégala con `SUPER + V` o `Ctrl+V`), `Shift+Supr` la borra del historial, `Esc` cierra.

### Capturas de pantalla
- `Print` (región), `SHIFT + Print` (ventana), `CTRL + Print` (pantalla) o `SUPER + SHIFT + P` (región): **hyprshot** guarda la captura en `~/Imágenes/Capturas` y la copia al portapapeles.
- Aparece una notificación con la vista previa y tres acciones: **EDITAR** (abre **satty** para anotarla; al guardar o copiar se sobrescribe y va al portapapeles), **COPIAR** y **CARPETA**. Clic en la tarjeta también edita.
- satty se abre flotante y centrado (80 % de la pantalla), con los colores del tema y la fuente del escritorio (se regenera con `theme` y `font`).

### Notificaciones
- Las muestra Quickshell (sustituye a dunst) arriba a la derecha, como tarjetas con el estilo de los paneles: app y hora, título, cuerpo, acciones como píldoras y una línea con el tiempo restante (se pausa con el ratón encima). Las urgentes van con borde rojo y no caducan. Clic para abrir o descartar, `×` para cerrar; `SUPER + ,` las cierra todas.

### Lanzador de aplicaciones
- `SUPER + A` abre un buscador propio (sustituye a wofi): búsqueda sin acentos por nombre, descripción y palabras clave, con coincidencia difusa.
- Teclas: `↑↓` o `Ctrl+T` / `Ctrl+N` (abajo/arriba, como el foco Dvorak), `Enter` o `Tab` abre, `Esc` cierra.
- Las apps de terminal (nvim, htop, yazi…) se abren dentro de kitty.

### Temas y wallpapers
Una sola fuente de colores para Hyprland, Quickshell y kitty: `theme/.config/theme/palettes/<tema>.json` con tokens semánticos (`bg`, `accent`, `surface`, `success`, `highlight`…) y los 16 colores de terminal. Cada tema tiene sus wallpapers en `theme/.config/theme/wallpapers/<tema>/`. Quickshell aplica colores y fondo en caliente (con fundido), kitty recarga sus colores sin reiniciarse y Hyprland recarga sus bordes.

- **Selector cover flow** (`SUPER + W`): carátulas de todos los wallpapers al estilo del iPod classic, con el tema, el nombre del wallpaper y la paleta bajo la carátula central. `←→` (o `Ctrl+H` / `Ctrl+S`), rueda o clic para moverse; `Enter` o clic en la central para aplicar; `Esc` cierra.
- Desde la terminal:

```sh
theme                                   # lista los temas (* = activo)
theme gruvbox-dark                      # activa un tema con su primer wallpaper
theme gruvbox-dark gruvbox-dark/x.png   # activa un tema con ese wallpaper
```

**Dolphin** y el resto de apps KDE/Qt también siguen el tema (colores, estilo Breeze e iconos), y se repintan solas al cambiarlo.

Los PDF se abren con **zathura** (desde yazi, Dolphin o el navegador) con los colores del tema; `Ctrl+R` pinta también las páginas con ellos.

Temas incluidos: **Catppuccin Mocha** y **Gruvbox Dark**.

### Terminal (zsh + powerlevel10k)
zsh con el prompt **powerlevel10k** en el estilo que elijas con `p10k configure` (lean, classic, rainbow…), pero con los colores del tema: directorio en el color de acento, git en verde / naranja / azul / rojo (limpio / modificado / sin seguimiento / conflicto), errores en rojo y duración en amarillo. Las sugerencias del historial (`→` para aceptar) y el resaltado de la línea de comandos también siguen el tema. Al cambiar de tema, las terminales abiertas cambian en el siguiente prompt.

- `cat` → **bat** (resaltado y números, colores de la terminal), `n` → **nvim**, `lg` → **lazygit** (revisar, hacer commit y subir; sus colores también siguen al tema).
- **extract** (plugin de oh-my-zsh): `extract archivo` o `x archivo` descomprime zip, tar.gz, tar.xz, zst, 7z, rar… en una carpeta con su nombre (`-r` borra el original).
- **zoxide**: `z <parte del nombre>` salta a la carpeta más visitada que coincida; `zi` la elige de una lista con fzf.

### Editor (Neovim + LazyVim)
- Base **LazyVim** (`n` en la terminal); la primera vez instala solo los plugins, parsers y servidores de lenguaje.
- Colores del tema activo (catppuccin, gruvbox; un tema nuevo sale con su paleta): al cambiar de tema, los nvim abiertos cambian al momento.
- Pantalla de inicio con **NEOVIM** en grande, cada letra de un color del tema (rojo, naranja, amarillo, verde, aqua y azul).
- Portapapeles compartido con el sistema: `y` copia al del escritorio (aparece en el historial de `SUPER + SHIFT + V`) y `p` pega lo copiado en cualquier app.
- **oil.nvim**: `-` (o `nvim <carpeta>`) abre el directorio como un buffer, con los archivos ocultos visibles (`g.` los oculta); renombrar, mover o borrar es editar las líneas y guardar.
- **code-preview.nvim**: con Claude Code en otra terminal, cada edición que propone se abre en nvim como diff antes de aceptarla. Se activa por proyecto con `:CodePreviewInstallClaudeCodeHooks` en su raíz (y reiniciando Claude Code); `<leader>dq` cierra el diff.
- LSP, formateo y resaltado para Lua (Hyprland), QML (Quickshell), bash/zsh, TypeScript, JSON y Markdown.
- Splits como el foco de Hyprland en Dvorak: `Ctrl + H/S/N/T` = izquierda/derecha/arriba/abajo. Guardar: `Ctrl + S` en modo insertar o `:w`.

### Fuente
Una sola fuente para todo el escritorio (hoy **JetBrainsMono Nerd Font**): Quickshell, kitty, apps GTK y Qt/KDE, y la fuente por defecto de fontconfig (sans, serif y mono) que usan el navegador y el resto. Para cambiarla, escribe **`/font`** en el lanzador (`SUPER + A`): salen las fuentes instaladas, cada una con su tipografía; `Enter` la aplica. Desde la terminal: `font` (lista) y `font "<familia>"`. Para crear uno, copia un `.json` de `palettes/`, cambia los hex y crea su carpeta en `wallpapers/`.

## Atajos principales (`SUPER` = mod)

| Atajo | Acción |
|---|---|
| `SUPER + Enter` | Terminal (kitty) |
| `SUPER + A` | Lanzador de aplicaciones |
| `SUPER + SHIFT + V` | Historial del portapapeles |
| `SUPER + W` | Selector de tema y wallpaper |
| `SUPER + ,` | Cerrar todas las notificaciones |
| `Print` / `SHIFT + Print` / `CTRL + Print` | Captura de región / ventana / pantalla completa (también `SUPER + SHIFT + P`: región) |
| `SUPER + E` | Gestor de archivos (yazi en kitty) |
| `SUPER + Q` | Cerrar ventana |
| `SUPER + L` | Bloquear la sesión |
| `SUPER + H / S / N / T` | Foco izquierda / derecha / arriba / abajo |
| `SUPER + 1…0` | Ir al workspace |
| `SUPER + SHIFT + 1…0` | Mover ventana al workspace |
| `SUPER + SHIFT + H / S` | Workspace anterior / siguiente |
| `SUPER + D` | Workspace especial (`SHIFT` para mover la ventana) |
| `SUPER + F` / `P` / `J` | Flotante / pseudo / cambiar split |
| `SUPER + C` / `V` | Copiar / pegar (envía `Ctrl+Shift+C/V`) |
| `SUPER + M` | Salir de Hyprland |
| Teclas de volumen / silencio | Subir / bajar 5 % (tope 100 %), silenciar altavoz o micrófono |
| Teclas de brillo | Subir / bajar el brillo 5 % |

## Instalación

```sh
git clone <repo> ~/dotfiles && cd ~/dotfiles

# Paquetes
sudo pacman -S --needed - < packages.txt
yay -S --needed - < aur.txt

# Enlaces simbólicos (GNU Stow)
mkdir -p ~/.config/zathura      # directorio real: el tema genera ahí sus colores
stow hypr quickshell theme kitty bluetooth zsh lazygit qt yazi zathura
stow --no-folding mpd          # systemd no lee drop-ins enlazados como directorio
systemctl --user enable --now mpd mpd-mpris bt-agent hypridle
chsh -s /usr/bin/zsh           # zsh por defecto; luego, en una terminal nueva: p10k configure
```

- `~/.local/bin` debe estar en el `PATH` para usar el comando `theme`.
- Fuentes usadas: JetBrainsMono, CaskaydiaCove y FiraCode **Nerd Font** (incluidas en `packages.txt`).
- Quickshell lo arranca Hyprland al iniciar (`uwsm app -- quickshell`).
- Quickshell es el servidor de notificaciones: si hay otro instalado (dunst, mako…), desactívalo, p. ej. `systemctl --user mask dunst`.

## Recargar

| Qué | Cómo |
|---|---|
| Hyprland | `hyprctl reload` (errores: `hyprctl configerrors`) |
| Quickshell (QML) | Automático al guardar |
| Quickshell (fuentes nuevas) | `pkill -x quickshell; hyprctl dispatch 'hl.dsp.exec_cmd("uwsm app -- quickshell")'` |
| Lanzador / selector por IPC | `qs ipc call launcher toggle` / `qs ipc call themes toggle` |

Las listas de paquetes se regeneran con `pacman -Qqen > packages.txt` y `pacman -Qqem > aur.txt`.
