extends Node3D

@export var chunk_size: float = 1000.0
@export var water_y_level: float = -80.0
@export var islands_per_chunk: int = 8
@export var min_island_size: float = 50.0
@export var max_island_size: float = 250.0
@export var base_material_color:= Color(0.2, 0.6, 0.2) 

var player: CharacterBody3D
var generated_chunks: Dictionary = {}
var current_chunk := Vector2.INF

var base_mesh: SphereMesh
var base_material: StandardMaterial3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	# Create the base sphere and material that all islands will share
	base_mesh = SphereMesh.new()
	base_material = StandardMaterial3D.new()
	base_material.albedo_color = base_material_color
	base_mesh.material = base_material

func _process(_delta: float) -> void:
	if not player:
		return
		
	var player_pos = player.global_position
	
	# Calculate which 1k chunk the player is currently flying over
	var chunk_x = floor(player_pos.x / chunk_size)
	var chunk_z = floor(player_pos.z / chunk_size)
	var new_chunk = Vector2(chunk_x, chunk_z)
	
	# If the player crossed a 1k threshold, update the world
	if new_chunk != current_chunk:
		current_chunk = new_chunk
		_update_chunks()

func _update_chunks() -> void:
	# Generate chunks in a 3x3 grid around the player so they appear in the distance
	for x in range(-1, 2):
		for z in range(-1, 2):
			var chunk_coord = current_chunk + Vector2(x, z)
			
			# Only generate if we haven't visited this chunk yet
			if not generated_chunks.has(chunk_coord):
				_generate_chunk(chunk_coord)

func _generate_chunk(chunk_coord: Vector2) -> void:
	# Mark as generated immediately
	generated_chunks[chunk_coord] = true
	
	var multi_mesh_instance = MultiMeshInstance3D.new()
	var multi_mesh = MultiMesh.new()
	
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = base_mesh
	
	# Use a deterministic random number generator. 
	# Hashing the coordinate means if you cross back over a chunk, 
	# the islands would generate in the exact same spot (useful if you ever decide to delete old chunks).
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord) 
	
	# Vary the number of islands slightly per chunk
	var count = rng.randi_range(islands_per_chunk / 2, islands_per_chunk)
	multi_mesh.instance_count = count
	
	for i in range(count):
		# Pick a random X and Z within the boundaries of this specific chunk
		var offset_x = rng.randf_range(0, chunk_size)
		var offset_z = rng.randf_range(0, chunk_size)
		var pos_x = (chunk_coord.x * chunk_size) + offset_x
		var pos_z = (chunk_coord.y * chunk_size) + offset_z
		
		var size = rng.randf_range(min_island_size, max_island_size)
		
		# Sink the sphere slightly into the water so it looks like a dome jutting out
		var pos_y = water_y_level - (size * 0.15) 
		
		# Apply the scale and position to this specific island
		var transform = Transform3D()
		transform = transform.scaled(Vector3(size, size, size))
		transform.origin = Vector3(pos_x, pos_y, pos_z)
		
		multi_mesh.set_instance_transform(i, transform)
		
	multi_mesh_instance.multimesh = multi_mesh
	add_child(multi_mesh_instance)
