extends Control

#inventory ui

@export var slot_count: int = 20
@onready var grid: GridContainer = $Panel/GridContainer
var slot_buttons: Array = []

func _ready():
	#force hide
	visible = false
	_refresh()
	if not Engine.has_singleton("Inventory"):
		push_error("ERROR: Inventory is NOT autoloaded. Fix it in Project → Project Settings → Autoload!")
		return

	if not Inventory.has_method("get_item_data") or not ("slots" in Inventory):
		push_error("ERROR: Inventory is missing required properties (slots, get_item_data).")
		return

	if grid == null:
		push_error("ERROR: $Panel/GridContainer not found.")
		return

	grid.columns = 5   # number of columns

	for i in range(slot_count):
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(48, 48)

		btn.pressed.connect(_on_slot_pressed.bind(i))

		grid.add_child(btn)
		slot_buttons.append(btn)

	if Inventory.has_signal("inventory_updated"):
		Inventory.inventory_updated.connect(_refresh)
	else:
		push_error("ERROR: Inventory missing 'inventory_updated' signal.")

	visible = false
	_refresh()

func _process(delta):
	if Input.is_action_just_pressed("inventory_toggle"):
		visible = not visible

func _refresh():
	if not Engine.has_singleton("Inventory"):
		return

	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]

		var slot = null
		if i < Inventory.slots.size():
			slot = Inventory.slots[i]
		if slot:
			var data = Inventory.get_item_data(slot["id"])

			var icon_path = data.get("icon", "")
			if icon_path != "":
				var tex = load(icon_path)
				btn.texture_normal = tex if tex is Texture2D else null
			else:
				btn.texture_normal = null

			btn.hint_tooltip = "%s x%d" % [
				data.get("name", "?"),
				slot.get("count", 1)
			]

		else:
			btn.texture_normal = null
			btn.hint_tooltip = ""



func _on_slot_pressed(index: int):
	if index >= Inventory.slots.size():
		return

	var slot = Inventory.slots[index]
	if slot == null:
		return

	var data = Inventory.get_item_data(slot["id"])
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]

	if data.has("slot"):
		var slot_name = data["slot"]
		var current = player.equipment.get(slot_name)

		if current:
			Inventory.add_item(current["id"], 1)

		player.equipment[slot_name] = data
		player.update_stats_from_equipment()
		Inventory.remove_from_slot(index, 1)
		return
