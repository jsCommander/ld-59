extends BaseDialog
class_name UiSelectUpgradeDialog

const item_scene = preload("res://game_kit/ui/components/ui_select_upgrade_dialog/ui_select_upgrade_dialog_item.tscn")

var item_scene_nodes: Array[UiSelectUpgradeDialogItem] = []
var items: Array[UiSelectUpgradeDialogItemResource] = []
var button_text: String = "Pick"

func set_data(data: Variant) -> void:
	items.clear()
	for item in data.items:
		if item is UiSelectUpgradeDialogItemResource:
			items.append(item)

	button_text = data.button_text
	_update()

func _update() -> void:
	for item in items:
		var item_node: UiSelectUpgradeDialogItem = item_scene.instantiate()
		item_node.item = item
		item_node.button_text = button_text
		item_node.clicked.connect(_handle_item_clicked.bind(item))
		self.add_child(item_node)
		item_scene_nodes.append(item_node)

func _handle_item_clicked(item: UiSelectUpgradeDialogItemResource) -> void:
	Log.log_debug(self.name, "Item selected: %s" % item.text)
	finished.emit(item)
