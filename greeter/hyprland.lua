-- Hyprland mínimo para el inicio de sesión (greetd lo lanza como el usuario "greeter").
-- Solo muestra el greeter de Quickshell; al iniciar sesión, quickshell termina y este
-- Hyprland se cierra para que greetd arranque la sesión elegida.

hl.env("QS_THEME_DIR", "/var/lib/quickshell-greeter/theme")
hl.env("XCURSOR_SIZE", "24")

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "dvorak-intl",
        touchpad   = { natural_scroll = false },
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
    },
    animations = { enabled = false },
})

hl.on("hyprland.start", function ()
    hl.exec_cmd([[sh -c 'quickshell -p /usr/share/quickshell-greeter/greeter.qml; hyprctl dispatch "hl.dsp.exit()"']])
end)
