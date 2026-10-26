# dotfiles

Configuración personal de **Arch Linux + Hyprland**, con una shell propia escrita en **Quickshell** (QML) y un sistema de temas (colores + wallpapers) compartido por Hyprland, Quickshell y kitty. Teclado **Dvorak** (`dvorak-intl`).

## Qué incluye

| Paquete | Destino | Contenido |
|---|---|---|
| `hypr/` | `~/.config/hypr` | Hyprland con la **API Lua** (`hyprland.lua` + módulos `keybinds`, `animations`, `theme`) |
| `quickshell/` | `~/.config/quickshell` | Barra superior, cápsula de red, indicadores de volumen y brillo, notificaciones, panel de batería, lanzador, fondo de escritorio y selector de tema |
| `theme/` | `~/.config/theme`, `~/.local/bin` | Paletas de color, wallpapers por tema y script `theme` para cambiarlos |
| `kitty/` | `~/.config/kitty` | `kitty.conf` (incluye los colores del tema activo) |
| `packages.txt` / `aur.txt` | — | Paquetes oficiales y de AUR |

### Barra (Quickshell)
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
- Al pasar el ratón muestra dos sliders, volumen y brillo, que se ajustan con clic, arrastre o la rueda; clic en el icono de volumen para silenciar.

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

Temas incluidos: **Catppuccin Mocha** y **Gruvbox Dark**. Para crear uno, copia un `.json` de `palettes/`, cambia los hex y crea su carpeta en `wallpapers/`.

## Atajos principales (`SUPER` = mod)

| Atajo | Acción |
|---|---|
| `SUPER + Enter` | Terminal (kitty) |
| `SUPER + A` | Lanzador de aplicaciones |
| `SUPER + W` | Selector de tema y wallpaper |
| `SUPER + ,` | Cerrar todas las notificaciones |
| `SUPER + E` | Gestor de archivos (yazi en kitty) |
| `SUPER + Q` | Cerrar ventana |
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
stow hypr quickshell theme kitty
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
