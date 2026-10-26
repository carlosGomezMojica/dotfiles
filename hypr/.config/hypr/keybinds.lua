
-------------------
---MIS PROGRAMAS---
-------------------

local terminal = "kitty"
local fileManager = terminal .. " -e yazi" -- yazi es de terminal: necesita abrirse dentro de kitty
local menu = "qs ipc call launcher toggle" -- lanzador propio de Quickshell (Launcher.qml)
local themePicker = "qs ipc call themes toggle" -- selector de tema y wallpaper (ThemePicker.qml)
local dismissNotifications = "qs ipc call notifications dismissAll" -- cerrar notificaciones (Notifications.qml)


------------------
---KEYBINDINGS----
------------------

local mainMod = "SUPER"

local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())-- close windows

hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")) -- kill hyprland

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(themePicker))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(dismissNotifications))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))


hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle"}))
hl.bind(mainMod .. " + P",hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Movefocus with mainMod + htns=dvorak
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left"}))
hl.bind(mainMod .. " + S", hl.dsp.focus({ direction = "right"}))
hl.bind(mainMod .. " + N", hl.dsp.focus({ direction = "up"}))
hl.bind(mainMod .. " + T", hl.dsp.focus({ direction = "down"}))

-- switch workspaces with moinMod + [0-9]
--
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT +" .. key, hl.dsp.window.move({ workspace = i}))
end

-- Special workspace
hl.bind(mainMod .. " + D", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.window.move({workspace = "special:magic"}))

-- atajos para cambiar el workspace con Super + rueda mouse(raton)
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1"}))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1"}))

-- atajos para cambiar el workspace con Super + Shift + H/S (izq/der en dvorak)
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.focus({ workspace = "e-1"}))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.focus({ workspace = "e+1"}))

-- copiar / pegar con Super + C/V (envia Ctrl + Shift + C/V a la ventana activa)
hl.bind(mainMod .. " + C", hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "C"}))
hl.bind(mainMod .. " + V", hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "V"}))

-- Move / resize con click de mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),{mouse = true})
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(),{mouse = true})

-- Teclas multimedia del portátil: volumen y micrófono (wpctl, de wireplumber).
-- locked: funcionan con la pantalla bloqueada; repeating: mantener pulsado repite.
-- El subir tiene tope en 100% (-l 1).
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })

-- Brillo de pantalla (brightnessctl, vía systemd-logind: sin sudo ni grupo video).
-- -e4: escala exponencial, más natural al ojo con poco brillo; -n2: mínimo para no apagar la pantalla.
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
--hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
--hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
--hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
--hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


