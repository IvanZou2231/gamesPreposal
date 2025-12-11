extends CharacterBody2D

#player stats
@export 
var speed: float = 200.0
var base_max_health: int = 100
var max_health: int
var health: int
var max_mana: int = 50
var mana: int
var base_attack: int = 5
var attack_power: int


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

#Arrow
@onready var bow_pos: Marker2D = $AnimatedSprite2D/BowPosition
const ArrowScene = preload("res://scenes/arrow.tscn")

#sword attack cooldown
var attack_cooldown: float = 0.5
var attack_timer: float = 0.0
var is_attacking: bool = false

#shooting cooldown
var can_shoot: bool = true
@export var shoot_cooldown: float = 0.5
var shoot_timer: float = 0.0
var is_shooting: bool = false

#flipping player
var target_scale_x: float = 1.0
@export var flip_speed: float = 10.0

#ready
func _ready():
	max_health = base_max_health
	health = max_health
	mana = max_mana
	attack_power = base_attack
	add_to_group("hud")
	add_to_group("player")

	if not anim.is_connected("frame_changed", Callable(self, "_on_anim_frame_changed")):
		anim.connect("frame_changed", Callable(self, "_on_anim_frame_changed"))

#movement
func _physics_process(delta):
	handle_movement(delta)
	
	var mouse_dir = get_global_mouse_position().x - global_position.x
	target_scale_x = 1 if mouse_dir > 0 else -1
	
	#timers
	attack_timer = max(0.0, attack_timer - delta)
	if not can_shoot:
		shoot_timer = max(0.0, shoot_timer - delta)
		if shoot_timer <= 0:
			can_shoot = true

	#sword attack toggle
	if Input.is_action_just_pressed("attack"):
		attack()

	#shoot arrow toggle
	if Input.is_action_just_pressed("shoot") and can_shoot and not is_shooting:
		shoot_arrow()

	#flip
	anim.scale.x = lerp(anim.scale.x, target_scale_x, flip_speed * delta)
	anim.scale.y = 1
	var bow_target_x: float = abs(bow_pos.position.x) * target_scale_x
	bow_pos.position.x = lerp(bow_pos.position.x, bow_target_x, flip_speed * delta)

func handle_movement(delta):
	if is_attacking or is_shooting:
		velocity = Vector2.ZERO
	else:
		var input_vector := Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
		if input_vector.length() > 0:
			input_vector = input_vector.normalized()
			velocity = input_vector * speed

			if input_vector.x != 0:
				target_scale_x = 1.0 if input_vector.x > 0 else -1.0
		else:
			velocity = Vector2.ZERO
	
	move_and_slide()

#sword attacks
func attack():
	if attack_timer > 0 or is_attacking:
		return

	attack_timer = attack_cooldown
	is_attacking = true
	velocity = Vector2.ZERO

	anim.sprite_frames.set_animation_loop("Sword attack", false)
	anim.play("Sword attack")

	$AttackArea.monitoring = true

#sword and bow shooting frames
func _on_anim_frame_changed():
	# slashes
	if anim.animation == "Sword attack":
		if anim.frame == anim.sprite_frames.get_frame_count("Sword attack") - 1:
			is_attacking = false
			$AttackArea.monitoring = false

	# shooting
	if anim.animation == "shoot":
		if anim.frame == 8 and is_shooting:
			spawn_arrow()
			print("Arrow spawned at ", bow_pos.global_position)

		if anim.frame == anim.sprite_frames.get_frame_count("shoot") - 1:
			is_shooting = false
			shoot_timer = shoot_cooldown
			can_shoot = true


func _on_AttackArea_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(attack_power)

#shooting the arrow
func shoot_arrow():
	if ArrowScene == null:
		push_error("Arrow scene failed to load!")
		return

	if is_shooting:
		return  #stops from spamming

	is_shooting = true
	can_shoot = false

	anim.sprite_frames.set_animation_loop("shoot", false)
	anim.play("shoot")

func spawn_arrow():
	var arrow = ArrowScene.instantiate()

	var dir = (get_global_mouse_position() - bow_pos.global_position).normalized()
	arrow.direction = dir
	arrow.rotation = dir.angle()
	arrow.global_position = bow_pos.global_position
	get_tree().current_scene.add_child(arrow)
	print("Arrow position: ", arrow.global_position, " direction: ", dir)

#unfinished hud
func _update_hud():
	if get_tree().get_root().has_node("Main/HUD"):
		var hud = get_tree().get_root().get_node("Main/HUD")
		if hud and hud.has_method("update_bars"):
			hud.update_bars(health, max_health, mana, max_mana)

	get_tree().call_group(
		"hud",
		"update_bars",
		health, max_health, mana, max_mana
	)
