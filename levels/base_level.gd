extends Node2D

# --- @onready ---

@onready var boost_help: Control = %BoostArrows
@onready var dev_center_mid: Developer = %DevCenterMid
@onready var dev_left_mid: Developer = %DevLeftMid
@onready var dev_right_mid: Developer = %DevRightMid
@onready var dev_center_bot: Developer = %DevCenterBot
@onready var dev_left_bot: Developer = %DevLeftBot
@onready var dev_right_bot: Developer = %DevRightBot
@onready var dev_center_top: Developer = %DevCenterTop
@onready var dev_left_top: Developer = %DevLeftTop
@onready var dev_right_top: Developer = %DevRightTop

# --- Lifecycle ---

func _ready() -> void:
	add_to_group("level")
	AM.play_playlist([Constants.Music.SPB])
	SB.player_boost_applied.connect(_on_player_boost_applied)
	SB.developer_chosen.connect(_on_developer_chosen_for_help)
	PD.start_game([
		dev_center_mid, dev_left_mid, dev_right_mid,
		dev_center_bot, dev_left_bot, dev_right_bot,
		dev_center_top, dev_left_top, dev_right_top,
	])

# --- Handlers ---

func _on_developer_chosen_for_help(_dev_data: DeveloperData) -> void:
	if PD.is_boost_help_showed or boost_help.visible:
		return
	boost_help.visible = true


func _on_player_boost_applied(_developer: Developer) -> void:
	if not boost_help.visible:
		return
	if PD.is_boost_help_showed:
		var tween: Tween = create_tween()
		tween.tween_property(boost_help, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func() -> void: boost_help.visible = false)
