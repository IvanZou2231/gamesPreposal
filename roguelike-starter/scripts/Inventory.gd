extends Node

# storing items
var items := []

# adding an item
func add_item(item_id: String, count: int) -> bool:
	items.append({"id": item_id, "count": count})
	return true

func get_item_data(item_id: String) -> Dictionary:
	for item in items:
		if item.id == item_id:
			return item
	return {}
