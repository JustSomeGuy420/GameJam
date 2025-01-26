extends Node
class_name PointInfo
var is_fall_tile: bool
var is_left_edge: bool
var is_right_edge: bool
var is_left_wall: bool
var is_right_wall: bool
var is_position_point: bool
var point_id: int
var position: Vector2

func _init(id: int = -1, pos: Vector2 = Vector2.ZERO):
	point_id = id
	position = pos
