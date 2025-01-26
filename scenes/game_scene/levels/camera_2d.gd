extends Camera2D

@onready var _player: Player2D = get_parent().find_child("Player2D")
var camera_offset = 100
var camera_right_boundary = 950
var camera_left_boundary = 325

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position.x = _player.position.x


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if position.x > _player.position.x + camera_offset:
		position.x = _player.position.x + camera_offset
	elif position.x < _player.position.x - camera_offset:
		position.x = _player.position.x - camera_offset
	
	if position.x > camera_right_boundary:
		position.x = camera_right_boundary
	elif position.x < camera_left_boundary:
		position.x = camera_left_boundary
