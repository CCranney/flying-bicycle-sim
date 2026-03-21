extends CharacterBody3D

const TRACKER_NAME = "/vmc/body_tracker"

@export_group("Bike Dynamics")
@export var pedaling_threshold: float = 0.5   
@export var pedaling_multiplier: float = 40.0 # BUMPED UP significantly to give you power
@export var max_speed: float = 35.0
@export var decay: float = 12.0

@export_group("Steering")
@export var tilt_deadzone_degrees: float = 15.0 # How far the head must turn before the bike drifts
@export var turn_speed: float = 2.0             # How fast the bike turns when drifting

@onready var camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var xr_origin: XROrigin3D = $XROrigin3D

var forward_speed: float = 0.0
var last_left_knee_y: float = 0.0
var last_right_knee_y: float = 0.0
var has_initial_knee_pos: bool = false

func _ready() -> void:
	floor_snap_length = 2.0

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
# 2. Pedaling Logic (Knee Tracking)
	var tracker: XRBodyTracker = XRServer.get_tracker(TRACKER_NAME)
	
	if tracker:
		var left_flags = tracker.get_joint_flags(XRBodyTracker.JOINT_LEFT_LOWER_LEG)
		var right_flags = tracker.get_joint_flags(XRBodyTracker.JOINT_RIGHT_LOWER_LEG)
		
		var left_tracked = left_flags & XRBodyTracker.JOINT_FLAG_POSITION_TRACKED
		var right_tracked = right_flags & XRBodyTracker.JOINT_FLAG_POSITION_TRACKED
		
		if left_tracked and right_tracked:
			var current_left_y = tracker.get_joint_transform(XRBodyTracker.JOINT_LEFT_LOWER_LEG).origin.y
			var current_right_y = tracker.get_joint_transform(XRBodyTracker.JOINT_RIGHT_LOWER_LEG).origin.y
			
			if has_initial_knee_pos:
				var left_delta = abs(current_left_y - last_left_knee_y)
				var right_delta = abs(current_right_y - last_right_knee_y)
				
				# Effort = Speed of knees in meters per second
				var pedal_effort = (left_delta + right_delta) / delta
				
				# Temporary print just to see how fast your knees are actually moving!
				print("DEBUG: Pedal Effort: ", pedal_effort) 
				
				if pedal_effort > pedaling_threshold:
					# Apply acceleration
					forward_speed += (pedal_effort * pedaling_multiplier * delta)
					forward_speed = min(forward_speed, max_speed)
			
			last_left_knee_y = current_left_y
			last_right_knee_y = current_right_y
			has_initial_knee_pos = true

	# 3. Apply Friction / Decay
	# By moving this down here with a smaller decay value, you will gradually coast to a stop
	forward_speed = move_toward(forward_speed, 0.0, decay * delta)
	
# 4. Steering Logic (Head Roll / Tilt)
	if camera:
		# Get the camera's local Z rotation (roll)
		var head_roll = camera.transform.basis.get_euler().z
		var deadzone_rad = deg_to_rad(tilt_deadzone_degrees)
		
		# If the user tilts further left or right than the deadzone
		if abs(head_roll) > deadzone_rad:
			# Calculate how far past the deadzone they are leaning
			var excess_roll = (abs(head_roll) - deadzone_rad) * sign(head_roll)
			
			# Rotate the entire CharacterBody3D (steer the bike) based on the head tilt
			# NOTE: If leaning left turns you right, simply change `excess_roll` to `-excess_roll` below!
			rotate_y(excess_roll * turn_speed * delta)
			
	# 5. Apply Movement Vectors
	# Bike always moves "forward" relative to where the CharacterBody3D is currently facing
	var forward_dir = -global_transform.basis.z

	if is_on_floor():
		forward_dir = forward_dir.slide(get_floor_normal()).normalized()
	else:
		forward_dir.y = 0
		forward_dir = forward_dir.normalized()

	velocity.x = forward_dir.x * forward_speed
	velocity.z = forward_dir.z * forward_speed

	# Stick to floor slightly to prevent bouncing on slopes
	if is_on_floor():
		velocity += -get_floor_normal() * 2.0 * delta 

	move_and_slide()
