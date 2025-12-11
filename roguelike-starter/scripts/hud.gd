extends CanvasLayer

@onready var health_bar := $Panel/HBoxContainer/HealthBar
@onready var mana_bar := $Panel/HBoxContainer/ManaBar

func _ready():
	add_to_group("hud")

func update_bars(cur_hp:int, max_hp:int, cur_mana:int, max_mana:int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = cur_hp
	if mana_bar:
		mana_bar.max_value = max_mana
		mana_bar.value = cur_mana
