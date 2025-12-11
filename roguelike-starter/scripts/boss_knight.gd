extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

#boss stats
@export var health: int = 100
@export var move_speed: float = 200.0
@export var attack_range: float = 40
@export var attack_damage: int = 10

var is_dead: bool = false
var is_attacking: bool = false
var flash_running: bool = false

var player: Node2D = null

func _ready():
	anim.play("idle")


func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if flash_running:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		velocity = Vector2.ZERO
		move_and_slide()
		anim.play("idle")
		return
	player = players[0]

	if not is_attacking and _player_in_attack_area():
		await _start_attack()
		return

	var dir = player.global_position - global_position
	var distance = dir.length()
	if distance > attack_range:
		dir = dir.normalized()
		velocity = dir * move_speed
		anim.play("walk")
		anim.flip_h = dir.x < 0
	else:
		velocity = Vector2.ZERO
		anim.play("idle")
	move_and_slide()

func _player_in_attack_area() -> bool:
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _start_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("Attack")
	print("Boss attacking!")

	var attack_frames = anim.sprite_frames.get_frame_count("Attack")
	var attack_fps = anim.sprite_frames.get_animation_speed("Attack")
	var attack_time = attack_frames / attack_fps
	await get_tree().create_timer(attack_time).timeout

	_finish_attack()

func _finish_attack():
	is_attacking = false
	anim.play("idle")

#taking damage, death animation + hurt animation
func take_damage(amount: int):
	if is_dead:
		return

	health -= amount
	print("Boss hit! Damage:", amount)

	_flash_red()

	if health <= 0 and not is_dead:
		await _die()

func _flash_red():
	if flash_running:
		return
	flash_running = true
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1, 1, 1)
	flash_running = false

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO

	anim.sprite_frames.set_animation_loop("Death", false)
	anim.play("Death")

	#hardcoded to disappear
	await get_tree().create_timer(13.0 / 3.0).timeout
	queue_free()
