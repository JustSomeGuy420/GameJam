extends CharacterBody2D

var pos:Vector2
var speed = 1000
var dir : float
var damage = 10

@onready var timer = $Timer
@export var timeout_duration: float = 2.0

func ready():
	global_position = pos
	randomize()

func _ready():
	timer.wait_time = timeout_duration
	timer.start()
	
func _physics_process(delta: float) -> void:
	velocity = Vector2(dir * speed,0)
	var movement = velocity * delta
	var collision = move_and_collide(movement)
	
	if collision:
		handle_collision(collision.get_collider())
		
func _on_timer_timeout():
	queue_free()

func handle_collision(collider: Node):
	
	if collider.is_in_group("enemy"):  # Check if the collider is an enemy
		collider.take_damage(randi() % 15 + damage)
	queue_free()
