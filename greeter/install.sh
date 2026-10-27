#!/usr/bin/env bash
# Instala el inicio de sesión de Quickshell para greetd. Re-ejecutable (tras cambiar QML).
#   sudo greeter/install.sh            copia archivos y prepara /var/lib/quickshell-greeter
#   sudo greeter/install.sh --enable   además cambia el gestor: SDDM -> greetd
# Vuelta atrás: sudo systemctl disable greetd && sudo systemctl enable sddm
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "install.sh: ejecútalo con sudo" >&2; exit 1; }
repo="$(cd "$(dirname "$0")/.." && pwd)"
owner="${SUDO_USER:-$(stat -c %U "$repo")}"
home="$(getent passwd "$owner" | cut -d: -f6)"

command -v greetd >/dev/null || { echo "install.sh: falta greetd (pacman -S greetd)" >&2; exit 1; }

# 1. Componentes QML (el greeter no puede leer el home): copia completa de la shell
rm -rf /usr/share/quickshell-greeter
cp -rT "$repo/quickshell/.config/quickshell" /usr/share/quickshell-greeter
chmod -R a+rX /usr/share/quickshell-greeter

# 2. Configuración de greetd y del Hyprland del greeter (respaldo del original una vez)
[[ -f /etc/greetd/config.toml && ! -f /etc/greetd/config.toml.orig ]] && cp /etc/greetd/config.toml /etc/greetd/config.toml.orig
install -Dm644 "$repo/greeter/config.toml" /etc/greetd/config.toml
install -Dm644 "$repo/greeter/hyprland.lua" /etc/greetd/hyprland.lua

# 3. Datos del tema para el greeter (escribibles por el usuario: los actualiza greeter-sync)
install -d -o "$owner" -g "$owner" -m 755 /var/lib/quickshell-greeter
sudo -u "$owner" HOME="$home" USER="$owner" "$repo/theme/.local/bin/greeter-sync"

# 4. Teclado Dvorak también en la consola y para X11/Wayland por defecto
localectl set-x11-keymap us pc105 dvorak-intl
localectl set-keymap dvorak || true

echo "greeter instalado en /usr/share/quickshell-greeter y /etc/greetd"

# 5. Cambiar de gestor solo si se pide
if [[ "${1:-}" == "--enable" ]]; then
    systemctl disable sddm.service 2>/dev/null || true
    systemctl enable greetd.service
    echo "greetd activado: se usará en el próximo arranque (o: sudo systemctl restart display-manager)"
fi
