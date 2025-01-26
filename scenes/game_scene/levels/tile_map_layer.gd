class_name TileMapPathFind
extends TileMapLayer

@export var show_debug_graph: bool = true
@export var jump_distance: int = 5
@export var jump_height: int = 4

const COLLISION_LAYER: int = 0
const CELL_IS_EMPTY: int = -1
const MAX_TILE_FALL_SCAN_DEPTH: int = 500

var _astar_graph: AStar2D = AStar2D.new()
var _used_tiles: Array[Vector2i]
var _graphpoint: PackedScene
var _point_info_list: Array[PointInfo] = []

func _ready():
	_graphpoint = load("res://scenes/graph_point.tscn")
	_used_tiles = get_used_cells()
	build_graph()

func build_graph():
	add_graph_points()
	if not show_debug_graph:
		connect_points()

func get_point_info_at_position(position: Vector2) -> PointInfo:
	var new_info_point = PointInfo.new(-10000, position)
	new_info_point.is_position_point = true
	var tile: Vector2i = local_to_map(position)
	
	if get_cell_source_id(Vector2i(tile.x, tile.y + 1)) != CELL_IS_EMPTY:
		if get_cell_source_id(Vector2i(tile.x - 1, tile.y)) != CELL_IS_EMPTY:
			new_info_point.is_left_wall = true
		if get_cell_source_id(Vector2i(tile.x + 1, tile.y)) != CELL_IS_EMPTY:
			new_info_point.is_right_wall = true
		if get_cell_source_id(Vector2i(tile.x - 1, tile.y + 1)) != CELL_IS_EMPTY:
			new_info_point.is_left_edge = true
		if get_cell_source_id(Vector2i(tile.x + 1, tile.y + 1)) != CELL_IS_EMPTY:
			new_info_point.is_right_edge = true
	return new_info_point

func reverse_path_stack(path_stack: Array) -> Array:
	var new_array = path_stack.duplicate()
	new_array.reverse()
	return new_array

func get_plaform_2d_path(start_pos: Vector2, end_pos: Vector2) -> Array:
	var path_stack: Array = []
	var start_id = _astar_graph.get_closest_point(start_pos)
	var end_id = _astar_graph.get_closest_point(end_pos)
	var id_path = _astar_graph.get_id_path(start_id, end_id)
	
	if id_path.size() <= 0:
		return path_stack
	
	var start_point = get_point_info_at_position(start_pos)
	var end_point = get_point_info_at_position(end_pos)
	var num_points = id_path.size()
	
	for i in num_points:
		var curr_point = get_info_point_by_point_id(id_path[i])
		if num_points == 1:
			continue
		
		if i == 0 and num_points >= 2:
			var second_point = get_info_point_by_point_id(id_path[i + 1])
			if start_point.position.distance_to(second_point.position) < curr_point.position.distance_to(second_point.position):
				path_stack.append(start_point)
				continue
		
		elif i == num_points - 1 and num_points >= 2:
			var penultimate_point = get_info_point_by_point_id(id_path[i - 1])
			if end_point.position.distance_to(penultimate_point.position) < curr_point.position.distance_to(penultimate_point.position):
				continue
			else:
				path_stack.append(curr_point)
				break
		
		path_stack.append(curr_point)
	
	path_stack.append(end_point)
	return reverse_path_stack(path_stack)

func get_info_point_by_point_id(point_id: int) -> PointInfo:
	for p in _point_info_list:
		if p.point_id == point_id:
			return p
	return null

func _draw():
	if show_debug_graph:
		connect_points()

func add_graph_points():
	for tile in _used_tiles:
		add_left_edge_point(tile)
		add_right_edge_point(tile)
		add_left_wall_point(tile)
		add_right_wall_point(tile)
		add_fall_point(tile)

func tile_already_exist_in_graph(tile: Vector2i) -> int:
	var local_pos = map_to_local(tile)
	if _astar_graph.get_point_count() > 0:
		var point_id = _astar_graph.get_closest_point(local_pos)
		if _astar_graph.get_point_position(point_id) == local_pos:
			return point_id
	return -1

func add_visual_point(tile: Vector2i, color: Color = Color.WHITE, scale: float = 1.0):
	if not show_debug_graph:
		return
	var visual_point = _graphpoint.instantiate()
	if color != Color.WHITE:
		visual_point.modulate = color
	if scale != 1.0 and scale > 0.1:
		visual_point.scale = Vector2(scale, scale)
	visual_point.position = map_to_local(tile)
	add_child(visual_point)

func get_point_info(tile: Vector2i) -> PointInfo:
	for p in _point_info_list:
		if p.position == map_to_local(tile):
			return p
	return null

func connect_points():
	for p1 in _point_info_list:
		connect_horizontal_points(p1)
		connect_jump_points(p1)
		connect_fall_point(p1)

func connect_fall_point(p1: PointInfo):
	if p1.is_left_edge or p1.is_right_edge:
		var tile_pos = local_to_map(p1.position)
		tile_pos.y += 1
		var fall_point = find_fall_point(tile_pos)
		if fall_point:
			var point_info = get_point_info(fall_point)
			var p2_map = local_to_map(p1.position)
			var p1_map = local_to_map(point_info.position)
			if p1_map.distance_to(p2_map) <= jump_height:
				_astar_graph.connect_points(p1.point_id, point_info.point_id)
				draw_line(p1.position, point_info.position, Color.GREEN)
			else:
				_astar_graph.connect_points(p1.point_id, point_info.point_id, false)
				draw_line(p1.position, point_info.position, Color.YELLOW)

func connect_jump_points(p1: PointInfo):
	for p2 in _point_info_list:
		connect_horizontal_platform_jumps(p1, p2)
		connect_diagonal_jump_right_edge_to_left_edge(p1, p2)
		connect_diagonal_jump_left_edge_to_right_edge(p1, p2)

func connect_diagonal_jump_right_edge_to_left_edge(p1: PointInfo, p2: PointInfo):
	if p1.is_right_edge and p2.is_left_edge and p2.position.x > p1.position.x and p2.position.y > p1.position.y:
		var p1_map = local_to_map(p1.position)
		var p2_map = local_to_map(p2.position)
		if p2_map.distance_to(p1_map) < jump_distance:
			_astar_graph.connect_points(p1.point_id, p2.point_id)
			draw_line(p1.position, p2.position, Color.GREEN)

func connect_diagonal_jump_left_edge_to_right_edge(p1: PointInfo, p2: PointInfo):
	if p1.is_left_edge and p2.is_right_edge and p2.position.x < p1.position.x and p2.position.y > p1.position.y:
		var p1_map = local_to_map(p1.position)
		var p2_map = local_to_map(p2.position)
		if p2_map.distance_to(p1_map) < jump_distance:
			_astar_graph.connect_points(p1.point_id, p2.point_id)
			draw_line(p1.position, p2.position, Color.GREEN)

func connect_horizontal_platform_jumps(p1: PointInfo, p2: PointInfo):
	if p1.point_id == p2.point_id:
		return
	if p2.position.y == p1.position.y and p1.is_right_edge and p2.is_left_edge and p2.position.x > p1.position.x:
		var p2_map = local_to_map(p2.position)
		var p1_map = local_to_map(p1.position)
		if p2_map.distance_to(p1_map) < jump_distance + 1:
			_astar_graph.connect_points(p1.point_id, p2.point_id)
			draw_line(p1.position, p2.position, Color.GREEN)

func connect_horizontal_points(p1: PointInfo):
	if p1.is_left_edge or p1.is_left_wall or p1.is_fall_tile:
		var closest = null
		for p2 in _point_info_list:
			if p1.point_id == p2.point_id:
				continue
			if (p2.is_right_edge or p2.is_right_wall or p2.is_fall_tile) and p2.position.y == p1.position.y and p2.position.x > p1.position.x:
				if not closest or p2.position.x < closest.position.x:
					closest = p2
		if closest and not horizontal_connection_cannot_be_made(p1.position, closest.position):
			_astar_graph.connect_points(p1.point_id, closest.point_id)
			draw_line(p1.position, closest.position, Color.GREEN)

func horizontal_connection_cannot_be_made(p1: Vector2, p2: Vector2) -> bool:
	var start = local_to_map(p1)
	var end = local_to_map(p2)
	for x in range(start.x, end.x):
		if get_cell_source_id(Vector2i(x, start.y)) != CELL_IS_EMPTY or get_cell_source_id(Vector2i(x, start.y + 1)) == CELL_IS_EMPTY:
			return true
	return false
func get_start_scan_tile_for_fall_point(tile: Vector2i) -> Vector2i:
	var tile_above = Vector2i(tile.x, tile.y - 1)
	var point = get_point_info(tile_above)
	if not point:
		return Vector2i.ZERO
	
	if point.is_left_edge:
		return Vector2i(tile.x - 1, tile.y - 1)
	elif point.is_right_edge:
		return Vector2i(tile.x + 1, tile.y - 1)
	
	return Vector2i.ZERO
	
func find_fall_point(tile: Vector2i):
	var scan = get_start_scan_tile_for_fall_point(tile)
	if not scan:
		return null
	var tile_scan = scan
	for i in MAX_TILE_FALL_SCAN_DEPTH:
		if get_cell_source_id(Vector2i(tile_scan.x, tile_scan.y + 1)) != CELL_IS_EMPTY:
			return tile_scan
		tile_scan.y += 1
	return null

func add_fall_point(tile: Vector2i):
	var fall_tile = find_fall_point(tile)
	if not fall_tile:
		return
	var fall_local = map_to_local(fall_tile)
	var existing_id = tile_already_exist_in_graph(fall_tile)
	if existing_id == -1:
		var point_id = _astar_graph.get_available_point_id()
		var point_info = PointInfo.new(point_id, fall_local)
		point_info.is_fall_tile = true
		_point_info_list.append(point_info)
		_astar_graph.add_point(point_id, fall_local)
		add_visual_point(fall_tile, Color("#ef7d57"), 0.35)
	else:
		var info = _point_info_list.filter(func(p): return p.point_id == existing_id)[0]
		info.is_fall_tile = true
		add_visual_point(fall_tile, Color("#ef7d57"), 0.3)

func add_left_edge_point(tile: Vector2i):
	if tile_above_exist(tile):
		return
	if get_cell_source_id(Vector2i(tile.x - 1, tile.y)) == CELL_IS_EMPTY:
		var tile_above = Vector2i(tile.x, tile.y - 1)
		var existing_id = tile_already_exist_in_graph(tile_above)
		if existing_id == -1:
			var point_id = _astar_graph.get_available_point_id()
			var point_info = PointInfo.new(point_id, map_to_local(tile_above))
			point_info.is_left_edge = true
			_point_info_list.append(point_info)
			_astar_graph.add_point(point_id, map_to_local(tile_above))
			add_visual_point(tile_above)
		else:
			_point_info_list.filter(func(p): return p.point_id == existing_id)[0].is_left_edge = true
			add_visual_point(tile_above, Color("#73eff7"))

func add_right_edge_point(tile: Vector2i):
	if tile_above_exist(tile):
		return
	if get_cell_source_id(Vector2i(tile.x + 1, tile.y)) == CELL_IS_EMPTY:
		var tile_above = Vector2i(tile.x, tile.y - 1)
		var existing_id = tile_already_exist_in_graph(tile_above)
		if existing_id == -1:
			var point_id = _astar_graph.get_available_point_id()
			var point_info = PointInfo.new(point_id, map_to_local(tile_above))
			point_info.is_right_edge = true
			_point_info_list.append(point_info)
			_astar_graph.add_point(point_id, map_to_local(tile_above))
			add_visual_point(tile_above, Color("#94b0c2"))
		else:
			_point_info_list.filter(func(p): return p.point_id == existing_id)[0].is_right_edge = true
			add_visual_point(tile_above, Color("#ffcd75"))

func add_left_wall_point(tile: Vector2i):
	if tile_above_exist(tile):
		return
	if get_cell_source_id(Vector2i(tile.x - 1, tile.y - 1)) != CELL_IS_EMPTY:
		var tile_above = Vector2i(tile.x, tile.y - 1)
		var existing_id = tile_already_exist_in_graph(tile_above)
		if existing_id == -1:
			var point_id = _astar_graph.get_available_point_id()
			var point_info = PointInfo.new(point_id, map_to_local(tile_above))
			point_info.is_left_wall = true
			_point_info_list.append(point_info)
			_astar_graph.add_point(point_id, map_to_local(tile_above))
			add_visual_point(tile_above, Color.BLACK)
		else:
			_point_info_list.filter(func(p): return p.point_id == existing_id)[0].is_left_wall = true
			add_visual_point(tile_above, Color.BLUE, 0.45)

func add_right_wall_point(tile: Vector2i):
	if tile_above_exist(tile):
		return
	if get_cell_source_id(Vector2i(tile.x + 1, tile.y - 1)) != CELL_IS_EMPTY:
		var tile_above = Vector2i(tile.x, tile.y - 1)
		var existing_id = tile_already_exist_in_graph(tile_above)
		if existing_id == -1:
			var point_id = _astar_graph.get_available_point_id()
			var point_info = PointInfo.new(point_id, map_to_local(tile_above))
			point_info.is_right_wall = true
			_point_info_list.append(point_info)
			_astar_graph.add_point(point_id, map_to_local(tile_above))
			add_visual_point(tile_above, Color.BLACK)
		else:
			_point_info_list.filter(func(p): return p.point_id == existing_id)[0].is_right_wall = true
			add_visual_point(tile_above, Color("#566c86"), 0.65)

func tile_above_exist(tile: Vector2i) -> bool:
	return get_cell_source_id(Vector2i(tile.x, tile.y - 1)) != CELL_IS_EMPTY

func _process(delta):
	pass
