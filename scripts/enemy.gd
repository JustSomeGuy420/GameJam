extends PlatformerController2D

class_name Enemy2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
var direction = 1  # 1 for moving right, -1 for moving left
var health = 200
@onready var health_label = $Health
@onready var _animated_sprite = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	_animated_sprite.play("idle")
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	velocity.x = direction * SPEED
	
	
	move_and_slide()

func _on_screenEdge():
	direction *= -1

func take_damage(amount:int):
	health -= amount
	modulate = Color(1, 0, 0)  # Turn red
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)  # Return to normal color
	
	if health <= 0:
		die()
		
	update_healthBar()	
	
func update_healthBar():
	health_label.text = "Health: ❤️ " + str(health)

func die():
	print("Enemy died!")
	queue_free()
