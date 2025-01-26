extends Node2D

var enemy_scene : PackedScene = preload("res://scenes/enemy/enemy.tscn")  # Path to your Enemy scene
var spawn_interval = 1.5  # Time between enemy spawns (in seconds)
var spawn_area = Vector2(450, 400)  # Spawn area where enemies will appear
var enemy_count = 1  # Number of enemies to spawn

@onready var timer = Timer.new()

func _ready():
	add_child(timer)
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.connect("timeout", Callable(self, "_on_SpawnTimerTimeout"))
	
	for i in range(enemy_count):
		spawn_enemy()

func _on_SpawnTimerTimeout():
	spawn_enemy()

func spawn_enemy():
	# Choose a random position within the spawn area
	var spawn_pos = Vector2(spawn_area.x, spawn_area.y)
	
	# Create the enemy instance and add it to the scene
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_pos
	get_parent().add_child.call_deferred(enemy)
