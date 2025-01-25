extends CharacterBody2D

var pos:Vector2
var speed = 2000
var dir : float
var damage = 15

@onready var timer = $Timer
@export var timeout_duration: float = 2.0

func ready():
	global_position = pos

func _ready():
	timer.wait_time = timeout_duration
	timer.start()
	
func _physics_process(delta: float) -> void:
	velocity = Vector2(dir * speed,0)
	var movement = velocity * delta
	var collision = move_and_collide(movement)
	
	if collision:
		handle_collision(collision)
		
func _on_timer_timeout():
	queue_free()

func handle_collision(collision: KinematicCollision2D):
	#print("Bullet collided with:", collision.get_collider().name)
	queue_free()
