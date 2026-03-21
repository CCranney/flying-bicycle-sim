extends StaticBody3D

var player_node: Node3D

func _ready() -> void:
	player_node = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	var current_pos = global_transform.origin
	var player_pos = player_node.global_transform.origin

	current_pos.x = player_pos.x
	current_pos.z = player_pos.z
	global_transform.origin = current_pos	
