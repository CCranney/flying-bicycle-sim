extends Node3D

# The name of the tracker defined in your Project Settings/VMC Plugin
const TRACKER_NAME = "/vmc/body_tracker"

# Configuration for the visual spheres
@export var sphere_radius: float = 0.05
@export var sphere_color: Color = Color(0.0, 1.0, 0.0) # Green

# Dictionary to store our sphere instances, keyed by Joint ID
var _joint_spheres: Dictionary = {}

# The specific joints you possess (Hip, Chest, Knees, Ankles)
# We map the XRBodyTracker standard constants to readable names
var _target_joints = {
	XRBodyTracker.JOINT_HIPS: "Hip",
	XRBodyTracker.JOINT_CHEST: "Chest",
	XRBodyTracker.JOINT_LEFT_LOWER_LEG: "Left Knee",   # The joint at the knee moves the lower leg
	XRBodyTracker.JOINT_RIGHT_LOWER_LEG: "Right Knee",
	XRBodyTracker.JOINT_LEFT_FOOT: "Left Ankle",       # The joint at the ankle moves the foot
	XRBodyTracker.JOINT_RIGHT_FOOT: "Right Ankle"
}

func _ready():
	# Create a standard material for the spheres
	var material = StandardMaterial3D.new()
	material.albedo_color = sphere_color
	material.emission_enabled = true
	material.emission = sphere_color
	
	# Create a sphere for each target joint
	for joint_id in _target_joints:
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = sphere_radius
		sphere_mesh.height = sphere_radius * 2
		sphere_mesh.material = material
		
		var instance = MeshInstance3D.new()
		instance.mesh = sphere_mesh
		instance.name = _target_joints[joint_id] # Name it "Left Knee", etc. in the scene tree
		
		add_child(instance)
		_joint_spheres[joint_id] = instance

func _process(_delta):
	# 1. Get the tracker interface from the XRServer
	var tracker: XRBodyTracker = XRServer.get_tracker(TRACKER_NAME)
	
	# If the tracker isn't found (no data received yet), do nothing
	if not tracker:
		return

	# 2. Loop through our specific joints and update their positions
	for joint_id in _target_joints:
		# Check if this specific joint has valid data
		if tracker.get_joint_flags(joint_id) & XRBodyTracker.JOINT_FLAG_POSITION_TRACKED:
			# Get the transform (Position + Rotation)
			var tracker_transform: Transform3D = tracker.get_joint_transform(joint_id)
			
			# Apply to our sphere
			# Note: We apply this as a global transform to ensure it matches the raw data
			# regardless of where this script node is located in the scene.
			_joint_spheres[joint_id].global_transform = tracker_transform
