extends Node2D

var enemy_scene : PackedScene = preload("res://scenes/enemy/enemy.tscn")  # Path to your Enemy scene
var spawn_interval = 0.5  # Time between enemy spawns (in seconds)
var spawn_point
var spawn_count = 10
var rng = RandomNumberGenerator.new()

@onready var timer = Timer.new()

func _ready():
	spawn_point = position  # Spawn area where enemies will appear
	add_child(timer)
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.connect("timeout", Callable(self, "_on_SpawnTimerTimeout"))
	

func _on_SpawnTimerTimeout():
	spawn_enemy()

func spawn_enemy():
	# Create the enemy instance and add it to the scene
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_point
	get_parent().add_child.call_deferred(enemy)

func spawn_wave(wave_number):
	var enemy_strength = rng.randf_range(0, wave_number + 0.25)
	
	for i in range(spawn_count):
		spawn_enemy()
