class_name UiUpgradeChoice
extends BaseDialog

const UPGRADE_CARD: PackedScene = preload("res://components/ui/ui_upgrade_choice/upgrade_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel
@onready var reroll_button: Button = %RerollButton
@onready var take_button: Button = %TakeButton
@onready var player_stats_view: UiPlayerStats = %UiPlayerStats

# --- State ---

var _selected_card: UpgradeCard = null

# --- Lifecycle ---

func _ready() -> void:
	reroll_button.pressed.connect(_on_reroll_pressed)
	take_button.pressed.connect(_on_take_pressed)
	take_button.disabled = true
	_update_reroll_button()

# --- Handlers ---

func _on_card_selected(card: UpgradeCard, _is_selected: bool) -> void:
	if _selected_card == card:
		_confirm(card.upgrade)
		return
	if _selected_card != null:
		_selected_card.set_selected(false)
	_selected_card = card
	card.set_selected(true)
	take_button.disabled = false
	var preview_upgrades: Array[UpgradeData] = PD.global_upgrades.duplicate()
	preview_upgrades.append(card.upgrade)
	player_stats_view.stats_for_diff = Balance.get_player_stats_from_upgrades(preview_upgrades)


func _on_take_pressed() -> void:
	if _selected_card == null:
		return
	_confirm(_selected_card.upgrade)


func _on_reroll_pressed() -> void:
	if PD.rerolls_left <= 0:
		return
	PD.rerolls_left -= 1
	_update_reroll_button()
	var upgrades: Array[UpgradeData] = PD.get_level_up_upgrades()
	_build_cards(upgrades)
	_selected_card = null
	take_button.disabled = true
	player_stats_view.stats_for_diff = null
	Log.log_info(self.name, "Upgrade choices rerolled, %d left" % PD.rerolls_left)

# --- Public ---

func set_data(data: Dictionary) -> void:
	var upgrades: Array[UpgradeData] = PD.get_level_up_upgrades()
	_build_cards(upgrades)
	player_stats_view.stats = PD.player_stats

# --- Private ---

func _build_cards(upgrades: Array[UpgradeData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for upgrade: UpgradeData in upgrades:
		var card: UpgradeCard = UPGRADE_CARD.instantiate()
		card.setup(upgrade)
		card.selected_changed.connect(_on_card_selected)
		card_container.add_child(card)


func _confirm(upgrade: UpgradeData) -> void:
	close_dialog({"upgrade": upgrade})


func _update_reroll_button() -> void:
	reroll_button.text = "Reroll (%d)" % PD.rerolls_left
	reroll_button.disabled = PD.rerolls_left <= 0
