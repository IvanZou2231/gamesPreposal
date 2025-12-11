extends Area2D

#arrow stats
@export var speed: float = 600.0
@export var damage: int = 10
var direction: Vector2 = Vector2.RIGHT

func _ready():
	rotation = direction.angle()

	#auto delete when pass 5 seconds
	await get_tree().create_timer(5.0).timeout
	if is_inside_tree():
		queue_free()

	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	#prevents hitting the player when shooting
	if body.is_in_group("player"):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Arrow hit: ", body.name, " for ", damage, " damage!")

	if is_inside_tree():
		queue_free()
