extends Node

signal level_won
signal level_lost

var level_state : LevelState
@onready var _spawn_point: Node2D = $SpawnPoint
@onready var _player: Player2D = $Player2D
@onready var _enemy_spawner = $EnemySpawner
@onready var _enemy_spawner2 = $EnemySpawner2

@export var start_wave: int = 1
var current_wave

func _ready():
	level_state = GameState.get_level_state(scene_file_path)
	_player.position = _spawn_point.position
	current_wave = start_wave
	next_wave()


func _on_wave_timer_timeout() -> void:
	current_wave += 1
	next_wave()
	

func next_wave():
	_enemy_spawner.spawn_wave(current_wave)
	_enemy_spawner2.spawn_wave(current_wave)
