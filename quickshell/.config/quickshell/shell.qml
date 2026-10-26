import Quickshell

ShellRoot {
	Variants {
		model: Quickshell.screens
		delegate: Scope {
			id: perScreen
			required property var modelData

			Wallpaper { modelData: perScreen.modelData }
			Bar { modelData: perScreen.modelData }
			NetworkBar { modelData: perScreen.modelData }
		}
	}

	// Una sola instancia; se muestran en el monitor enfocado
	Launcher {}
	ThemePicker {}
}
