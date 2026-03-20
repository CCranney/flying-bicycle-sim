extends Node

func _ready():
	var interface = XRServer.find_interface("OpenXR")
	if interface and interface.initialize():
		print("OpenXR initialized")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		var vp = get_viewport()
		vp.use_xr = true
		vp.vrs_mode = Viewport.VRS_XR
	else:
		print("OpenXR not initialized")
