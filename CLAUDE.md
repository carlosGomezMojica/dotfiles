# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Idioma

Todo el contexto de este repositorio es en español: responde, comenta el código y escribe los mensajes de commit en español (los commits siguen Conventional Commits, p. ej. `feat(hypr): ...`, `chore: ...`).

## Qué es este repositorio

Dotfiles personales para **Arch Linux + Hyprland**, con **Quickshell** como barra/shell y un paquete `theme` con las paletas de color compartidas. No hay build, lint ni tests: los "cambios" se validan recargando los programas en vivo.

## Estructura: paquetes de GNU Stow

Cada directorio de primer nivel es un paquete de `stow` que replica la ruta relativa a `$HOME`:

- `hypr/.config/hypr/` → `~/.config/hypr`
- `quickshell/.config/quickshell/` → `~/.config/quickshell`
- `theme/.config/theme/` → `~/.config/theme` y `theme/.local/bin/` → `~/.local/bin`

`~/.config/hypr` y `~/.config/quickshell` son symlinks a este repo, así que editar aquí aplica directamente en el sistema. Para añadir una nueva herramienta, crea `<herramienta>/.config/<herramienta>/...` y enlázala:

```sh
cd ~/dotfiles && stow <paquete>        # crear symlinks
stow -R <paquete>                      # re-enlazar tras mover archivos
stow -D <paquete>                      # quitar symlinks
```

`packages.txt` (pacman) y `aur.txt` (AUR, vía `yay`) no se actualizan solas; se regeneran desde lo instalado con `pacman -Qqen > packages.txt` (paquetes oficiales instalados explícitamente) y `pacman -Qqem > aur.txt` (AUR). No mezclar paquetes AUR en `packages.txt`, o el `pacman -S` falla. Reinstalación: `sudo pacman -S --needed - < packages.txt` y `yay -S --needed - < aur.txt`.

## Hyprland (configuración en Lua)

La config usa la **API Lua de Hyprland** (`hyprland.lua`, objeto global `hl`: `hl.config`, `hl.bind`, `hl.dsp.*`, `hl.window_rule`, `hl.curve`, `hl.animation`...), no el formato clásico `hyprland.conf`. No mezcles sintaxis `.conf` ni inventes funciones: consulta https://wiki.hypr.land.

- `hyprland.lua` es el punto de entrada y carga módulos con `require("keybinds")` y `require("animations")`. Las nuevas secciones grandes deben ir en su propio módulo `.lua` y requerirse desde ahí.
- `keybinds.lua` define los programas (`terminal`, `fileManager`, `menu`) y todos los atajos con `mainMod = "SUPER"`.
- **El teclado es Dvorak** (`kb_variant = "dvorak-intl"`): el foco se mueve con `H/S/N/T` (izq/der/arriba/abajo), no con HJKL. Tenlo en cuenta al proponer atajos y evita colisiones con los existentes.
- Recargar: `hyprctl reload`. Errores de config: `hyprctl configerrors`.

## Quickshell (QML)

- `shell.qml` es la raíz (`ShellRoot`) e instancia una `Bar` por monitor mediante `Variants { model: Quickshell.screens }`.
- `Bar.qml` es un `PanelWindow` superior en forma de cápsula que se auto-oculta: colapsada muestra `WorkspaceStrip` (barritas finas) y al pasar el ratón se expande mostrando `Workspaces` (puntos clicables). Usa `mask: Region { item: hotspot }` para que solo la zona de hover capture el ratón y el resto deje pasar clics; las animaciones van en `pill`, nunca en `hotspot` (debe mantenerse estable).
- Ambos componentes de workspaces leen el estado de `Quickshell.Hyprland` (`focusedWorkspace`, `workspaces`) y muestran 9 workspaces. Al despachar a Hyprland desde QML se usa sintaxis Lua: `Hyprland.dispatch("hl.dsp.focus({workspace = N})")`.
- Batería: `BatteryStrip` (colapsada, 10 segmentos) y `Battery` (expandida, pila + %). Al pulsar `Battery` se abre `BatteryPanel` (`PopupWindow` con `grabFocus`, se cierra al hacer clic fuera) que contiene `BatteryCard`: nivel con `DotRing`, salud/ciclos/consumo y selector de perfil vía `PowerProfiles` (power-profiles-daemon). Mientras el panel está abierto la barra se mantiene expandida (`bar.expanded`). La salud se lee del dispositivo de batería física (`UPower.devices`), no de `displayDevice`; los ciclos, de `/sys/class/power_supply/BAT0/cycle_count`.
- Lanzador: `Launcher.qml` (una sola instancia en `shell.qml`, en el monitor enfocado), `PanelWindow` en capa Overlay con foco de teclado exclusivo mientras está abierto. Lista `DesktopEntries.applications` con búsqueda propia (sin acentos; nombre > palabras > descripción/keywords > difusa). Se controla por IPC: `qs ipc call launcher toggle|open|close`; `SUPER + A` ejecuta el `toggle` (variable `menu` en `keybinds.lua`). Teclas: ↑↓ / Ctrl+T (abajo) y Ctrl+N (arriba), como el foco Dvorak (también Ctrl+J/K), Enter o Tab abre, Esc cierra.
- Componentes reutilizables para paneles: `DotRing` (anillo de puntos con nivel) y `StatusPill` (píldora con borde y punto de estado).
- Fuente de los paneles: `Theme.font` (JetBrainsMono Nerd Font; los iconos son glifos Nerd Font, `String.fromCodePoint(0xF...)`).
- Los colores salen del singleton `Theme.qml` (`Theme.accent`, `Theme.surface`...); nunca escribas hex directos en los componentes. Ver "Temas".

## Temas (paletas de color)

Paquete stow `theme/`: una sola fuente de colores compartida por Hyprland y Quickshell.

- `theme/.config/theme/palettes/<nombre>.json`: JSON **plano** `"token": "#rrggbb"` (sin anidar: Lua lo parsea con un `gmatch`).
- `theme/.config/theme/current`: nombre del tema activo (hoy `catppuccin-mocha`).
- Tokens semánticos: `bg`, `border` (cápsula), `accent` (activo), `muted` (ocupado), `surface` (vacío), `text`, `success`, `error`, `warning`, `highlight` (selección en el lanzador), `panel_border` (borde de las tarjetas de paneles, cuyo fondo es `bg`; en QML `Theme.panelBorder`), `border_active_2`, `border_inactive`, `shadow` (bordes y sombra de ventanas).
- Quickshell: `Theme.qml` lee los archivos con `FileView` + `JsonAdapter` y se actualiza en caliente al cambiar.
- Hyprland: `local theme = require("theme")` y `theme.rgba(theme.accent, "ee")` → `"rgba(cba6f7ee)"`.
- Los valores por defecto (Mocha) están repetidos en `Theme.qml` y `theme.lua` como respaldo; un token nuevo hay que añadirlo en el JSON, en ambos archivos y en todas las paletas.
- Añadir un tema: copiar un `.json` de `palettes/` y cambiar los hex. Cambiar de tema: `theme <nombre>` (`theme` sin argumentos lista los temas); el script está en `~/.local/bin`.
- Probar: `quickshell` (o `qs`) en una terminal muestra errores de QML y recarga en caliente al guardar.
