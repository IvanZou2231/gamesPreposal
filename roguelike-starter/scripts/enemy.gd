extends CharacterBody2D

@export var attack_power:int = 10
@export var speed:float = 80.0
var target = null

func _ready():
	# try to find player
	for n in get_tree().get_nodes_in_group("player"):
		target = n
		break

func _physics_process(delta):
	if target:
		var dir = (target.global_position - global_position)
		if dir.length() > 8:
			velocity = dir.normalized() * speed
			move_and_slide()

func take_damage(amount:int):
	print("Enemy took %d damage" % amount)
	queue_free()

func _on_body_entered(body):
	# if touches player, damage them
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(attack_power)
