import Quickshell

ShellRoot {
	Variants {
		model: Quickshell.screens
		delegate: Bar{}
	}

	// Una sola instancia; se muestra en el monitor enfocado
	Launcher {}
}
