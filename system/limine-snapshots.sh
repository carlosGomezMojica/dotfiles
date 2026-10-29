#!/usr/bin/env bash
# Snapshots de snapper en el menú de arranque de Limine (submenú "Snapshots").
#   system/limine-snapshots.sh          pide confirmación (toca el arranque)
#   system/limine-snapshots.sh --yes    sin preguntar
# Se ejecuta como usuario (yay no admite root); pide sudo. Re-ejecutable.
#
# Pasa las entradas de limine.conf a limine-entry-tool (paquete limine-mkinitcpio-hook):
# a partir de ahí las genera él para cada kernel desde /etc/default/limine (system/limine)
# y /etc/kernel/cmdline, y limine-snapper-sync añade los snapshots de root.
#
# Vuelta atrás (también desde un USB de Arch, montando el ESP en /boot):
#   cp /boot/limine.conf.orig /boot/limine.conf   (y cada <ruta>/limine.conf.orig que se moviera)
#   yay -R limine-snapper-sync limine-mkinitcpio-hook && sudo mkinitcpio -P
set -euo pipefail

[[ $EUID -ne 0 ]] || { echo "limine-snapshots.sh: ejecútalo como usuario, no con sudo" >&2; exit 1; }
repo="$(cd "$(dirname "$0")/.." && pwd)"
esp=/boot
conf="$esp/limine.conf"

skip() { echo "limine-snapshots.sh: $1; no se toca el arranque" >&2; exit 0; }
pacman -Q limine &>/dev/null || skip "limine no está instalado"
[[ "$(findmnt -no FSTYPE "$esp")" == vfat ]] || skip "$esp no es una partición FAT (ESP)"
[[ "$(findmnt -no FSTYPE /)" == btrfs ]] || skip "/ no es btrfs"
command -v yay >/dev/null || { echo "limine-snapshots.sh: falta yay (lo instala install.sh)" >&2; exit 1; }
sudo snapper -c root get-config &>/dev/null || skip "no hay config 'root' de snapper"

if [[ "${1:-}" != "--yes" ]]; then
    echo "Esto cambia cómo se generan las entradas del menú de Limine."
    echo "Ten a mano un USB de Arch por si el equipo no arrancara (vuelta atrás al principio del script)."
    read -rp "¿Continuar? [s/N] " answer
    [[ "$answer" == [sS]* ]] || exit 0
fi

# 1. Red de seguridad: snapshot y copia de cada limine.conf del ESP (solo la primera vez)
sudo snapper -c root create -d "antes de limine-snapshots"
mapfile -t configs < <(sudo find "$esp" -name limine.conf -type f)
had_conf=no
sudo test -f "$conf" && had_conf=yes
for c in "${configs[@]}"; do
    sudo test -f "$c.orig" || sudo cp -p "$c" "$c.orig"
done

# 2. Configuración de limine-entry-tool y limine-snapper-sync
sudo install -Dm644 "$repo/system/limine" /etc/default/limine

# 3. Hook de mkinitcpio para arrancar un snapshot (de solo lectura) con overlayfs encima.
#    Drop-in con HOOKS completo (los .conf.d se leen después de mkinitcpio.conf)
dropin=/etc/mkinitcpio.conf.d/btrfs-overlayfs.conf
read -ra hooks < <(bash -c 'source /etc/mkinitcpio.conf
    for f in /etc/mkinitcpio.conf.d/*.conf; do
        [[ -f $f && $f != '"$dropin"' ]] && source "$f"
    done
    echo "${HOOKS[@]}"')
overlay=btrfs-overlayfs
[[ " ${hooks[*]} " == *" systemd "* ]] && overlay=sd-btrfs-overlayfs
new=()
for h in "${hooks[@]}"; do
    [[ "$h" == *btrfs-overlayfs ]] && continue
    new+=("$h")
    [[ "$h" == filesystems ]] && new+=("$overlay")
done
printf '# Generado por system/limine-snapshots.sh: arrancar snapshots con overlayfs\nHOOKS=(%s)\n' "${new[*]}" \
    | sudo tee "$dropin" >/dev/null

# 4. limine.conf nuevo en $ESP con las opciones globales del actual (lo anterior a la
#    primera entrada "/..."). Las entradas viejas apuntan a /boot/vmlinuz-*, que dejan de
#    actualizarse con limine-mkinitcpio-hook, así que se quitan. Las configs de otras
#    rutas (EFI/BOOT, EFI/limine, limine/) se apartan: Limine las leería antes que $conf.
#    Si ya la gestiona limine-entry-tool (comment: machine-id=...), no se toca.
migrated=no
if ! sudo grep -q "machine-id=" "$conf" 2>/dev/null; then
    migrated=yes
    main=""
    sudo test -f "$conf" && main="$conf"
    [[ -z "$main" && ${#configs[@]} -gt 0 ]] && main="${configs[0]}"
    if [[ -n "$main" ]]; then
        sudo awk '/^[[:space:]]*\// { exit } { print }' "$main" | sudo tee "$conf.new" >/dev/null
    else
        echo "timeout: 5" | sudo tee "$conf.new" >/dev/null
    fi
    sudo mv "$conf.new" "$conf"
    for c in "${configs[@]}"; do
        [[ "$c" == "$conf" ]] || sudo mv "$c" "$c.disabled"
    done
fi

# Si algo falla a partir de aquí (y se acababa de migrar), se recupera el arranque anterior
restore() {
    [[ "$migrated" == yes ]] || return 0
    echo "limine-snapshots.sh: ha fallado; se restaura la configuración anterior de Limine" >&2
    for c in "${configs[@]}"; do
        sudo test -f "$c.orig" && sudo cp -p "$c.orig" "$c"
        sudo rm -f "$c.disabled"
    done
    [[ "$had_conf" == yes ]] || sudo rm -f "$conf"
    echo "Los paquetes limine-* quedan instalados: quítalos con" >&2
    echo "  yay -R limine-snapper-sync limine-mkinitcpio-hook && sudo mkinitcpio -P" >&2
}
trap restore ERR

# 5. Paquetes (al instalarse, el hook de mkinitcpio ya genera las entradas) y regenerar todo
yay -S --needed --noconfirm limine-mkinitcpio-hook limine-snapper-sync
sudo limine-update
sudo grep -q "machine-id=" "$conf" || { echo "limine-snapshots.sh: $conf no tiene entradas de limine-entry-tool" >&2; false; }
sudo limine-snapper-sync
sudo systemctl enable --now limine-snapper-sync.service
trap - ERR

echo "Limine: entradas en $conf y submenú Snapshots activo (copia en $conf.orig)."
echo "Reinicia para comprobarlo. Cuando arranque bien, los kernels viejos de $esp sobran:"
echo "  sudo rm $esp/vmlinuz-* $esp/initramfs-*.img"
