extends Node3D

const TRACKER_NAME = "/vmc/body_tracker"

@export_group("Tracker Visuals")
@export var sphere_radius: float = 0.05
@export var sphere_color: Color = Color(0.0, 1.0, 0.0) # Green

@export_group("Anchoring")
@export var camera: XRCamera3D                            # Drag your XRCamera3D into this slot in the Inspector!
@export var chest_offset: Vector3 = Vector3(0, -0.3, 0)   # 0.3 meters is roughly 1 foot straight down

var _joint_spheres: Dictionary = {}

var _target_joints = {
	XRBodyTracker.JOINT_HIPS: "Hip",
	XRBodyTracker.JOINT_CHEST: "Chest",
	XRBodyTracker.JOINT_LEFT_LOWER_LEG: "Left Knee",
	XRBodyTracker.JOINT_RIGHT_LOWER_LEG: "Right Knee",
	XRBodyTracker.JOINT_LEFT_FOOT: "Left Ankle",
	XRBodyTracker.JOINT_RIGHT_FOOT: "Right Ankle"
}

func _ready():
	var material = StandardMaterial3D.new()
	material.albedo_color = sphere_color
	material.emission_enabled = true
	material.emission = sphere_color
	
	for joint_id in _target_joints:
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = sphere_radius
		sphere_mesh.height = sphere_radius * 2
		sphere_mesh.material = material
		
		var instance = MeshInstance3D.new()
		instance.mesh = sphere_mesh
		instance.name = _target_joints[joint_id]
		
		add_child(instance)
		_joint_spheres[joint_id] = instance

func _process(_delta):
	var tracker: XRBodyTracker = XRServer.get_tracker(TRACKER_NAME)
	if not tracker: return

	# 1. Update the local positions of the joints
	for joint_id in _target_joints:
		if tracker.get_joint_flags(joint_id) & XRBodyTracker.JOINT_FLAG_POSITION_TRACKED:
			# We use local 'transform' instead of 'global_transform' here! 
			# This ensures the VMC skeleton proportions remain intact relative to each other.
			_joint_spheres[joint_id].transform = tracker.get_joint_transform(joint_id)

	# 2. Anchor the whole skeleton to the head
	if camera and _joint_spheres.has(XRBodyTracker.JOINT_CHEST):
		var chest_sphere = _joint_spheres[XRBodyTracker.JOINT_CHEST]
		
		var camera_yaw = camera.global_transform.basis.get_euler().y
		global_rotation.y = camera_yaw
		
		# Calculate exactly where the chest SHOULD be in the world
		var target_chest_pos = camera.global_position + chest_offset
		
		# Shift THIS entire Node3D (which holds all the spheres) by the difference
		global_position += (target_chest_pos - chest_sphere.global_position)
