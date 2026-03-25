extends MeshInstance3D

var player: CharacterBody3D
var last_location := Vector2.INF
const TILE_WORLD_SIZE = 1000.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	global_position.x = player.global_position.x
	global_position.z = player.global_position.z
	var player_pos = Vector2(player.global_position.x, player.global_position.z)
	if player_pos != last_location:
		material_override.set_shader_parameter("player_location", player_pos * (1. / TILE_WORLD_SIZE))
		last_location = player_pos
