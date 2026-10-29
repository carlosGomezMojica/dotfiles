#!/usr/bin/env bash
# Deja un Arch recién instalado como este: paquetes, enlaces de stow, servicios, tema,
# snapshots antes de cada actualización e inicio de sesión. Re-ejecutable.
#   ./install.sh    como usuario (pide sudo cuando hace falta)
set -euo pipefail

[[ $EUID -ne 0 ]] || { echo "install.sh: ejecútalo como usuario, no con sudo" >&2; exit 1; }
[[ -f /etc/arch-release ]] || { echo "install.sh: solo para Arch Linux" >&2; exit 1; }
repo="$(cd "$(dirname "$0")" && pwd)"
cd "$repo"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33minstall.sh: %s\033[0m\n' "$*" >&2; }

sudo -v
btrfs=no
[[ "$(findmnt -no FSTYPE /)" == btrfs ]] && btrfs=yes

# 1. Copia antes de tocar nada (si snapper ya está configurado)
if [[ $btrfs == yes ]] && command -v snapper >/dev/null && sudo snapper -c root get-config &>/dev/null; then
    step "Snapshot de / antes de instalar"
    sudo snapper -c root create -d "antes de install.sh"
fi

# 2. Paquetes oficiales
step "Paquetes oficiales (packages.txt)"
# shellcheck disable=SC2024  # la lista la lee el usuario, no hace falta root
sudo pacman -Syu --needed - < packages.txt

# 3. AUR. Los limine-* los instala system/limine-snapshots.sh: al instalarse ya reescriben
#    el menú de arranque, y antes hay que hacer la copia y escribir /etc/default/limine
step "Paquetes de AUR (aur.txt)"
if ! command -v yay >/dev/null; then
    tmp="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
fi
grep -v -e '-debug$' -e '^limine-' aur.txt | yay -S --needed --noconfirm -

# 4. Copias de seguridad: snapper + snap-pac (snapshot pre/post de / en cada pacman/yay)
step "Snapshots antes de cada actualización (snapper + snap-pac)"
if [[ $btrfs == yes ]]; then
    for pair in root:/ home:/home; do
        name="${pair%%:*}" path="${pair#*:}"
        sudo snapper -c "$name" get-config &>/dev/null && continue
        if sudo btrfs subvolume show "${path%/}/.snapshots" &>/dev/null; then
            warn "${path%/}/.snapshots ya existe sin config '$name' de snapper: créala a mano"
        else
            sudo snapper -c "$name" create-config "$path"
        fi
    done
    sudo install -Dm644 system/snap-pac.ini /etc/snap-pac.ini
    sudo systemctl enable --now snapper-cleanup.timer snapper-timeline.timer
    # Snapshots en el menú de Limine (pide confirmación: toca el arranque)
    system/limine-snapshots.sh
else
    warn "/ no es btrfs: sin snapshots"
fi

# 5. Enlaces con stow. Directorios que deben ser reales (kitty, zathura y herdr guardan ahí
#    archivos generados; systemd ignora un *.service.d enlazado; ~/.local/bin lo comparten
#    theme y scripts)
step "Enlaces (stow)"
mkdir -p ~/.config/{kitty,zathura,herdr,systemd/user,environment.d} ~/.local/bin
packages=()
for d in */; do
    d="${d%/}"
    [[ "$d" == greeter || "$d" == system ]] || packages+=("$d")
done
# Primero en seco: si algún archivo real estorba, no se toca nada
conflicts=no
for p in "${packages[@]}"; do
    flags=(); [[ "$p" == mpd ]] && flags=(--no-folding)
    stow -n -R "${flags[@]}" -t "$HOME" "$p" 2>/dev/null || { warn "conflictos en '$p': stow -n -R -t ~ $p"; conflicts=yes; }
done
[[ $conflicts == no ]] || { warn "mueve o borra esos archivos y vuelve a ejecutar"; exit 1; }
for p in "${packages[@]}"; do
    flags=(); [[ "$p" == mpd ]] && flags=(--no-folding)
    stow -R "${flags[@]}" -t "$HOME" "$p"
done

# 6. Servicios
step "Servicios"
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon
# De usuario: arrancan con la sesión gráfica
systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber \
    hypridle hyprpolkitagent mpd mpd-mpris bt-agent
# Las notificaciones las da Quickshell
systemctl --user mask dunst 2>/dev/null || true

# 7. Usuario
step "Shell, aplicaciones por defecto y herramientas"
[[ "$(getent passwd "$USER" | cut -d: -f7)" == /usr/bin/zsh ]] || chsh -s /usr/bin/zsh
xdg-mime default org.pwmt.zathura-pdf-mupdf.desktop application/pdf
mkdir -p ~/Música ~/Imágenes/Capturas
mise install
rustup toolchain list | grep -q . || rustup default stable
rustup component add rust-analyzer
nvim --headless "+Lazy! restore" +qa

# 8. Tema y fuente: generan lo que no está en el repo (kitty, zathura, KDE, Zen, satty, greeter).
#    Fuera de Hyprland el `hyprctl reload` final falla: se repiten al entrar en la sesión
step "Tema y fuente"
~/.local/bin/theme "$(<~/.config/theme/current)" || warn "theme: vuelve a ejecutarlo dentro de Hyprland"
~/.local/bin/font "$(<~/.config/theme/font)" || warn "font: vuelve a ejecutarlo dentro de Hyprland"

# 9. Inicio de sesión: greetd + Quickshell (y teclado Dvorak en la consola)
step "Inicio de sesión (greetd)"
sudo greeter/install.sh --enable

step "Listo"
echo "Cierra sesión y vuelve a entrar (o reinicia) para cargar la shell, los servicios y el entorno."
