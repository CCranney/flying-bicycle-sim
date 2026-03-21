extends Node

var xr_interface: XRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.initialize():
		print("OpenXR initialized successfully.")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		_setup_vr_viewport()
		return 

	xr_interface = XRServer.find_interface("visionOS")
	if xr_interface and xr_interface.initialize():
		print("visionOS initialized successfully.")
		_setup_vr_viewport()
		return 
		
	printerr("Failed to initialize any XR interface. Running in standard 2D mode.")

func _setup_vr_viewport():
	var vp : Viewport = get_viewport()
	vp.use_xr = true
	vp.vrs_mode = Viewport.VRS_XR
