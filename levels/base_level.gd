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
	boost_help.visible = false
	SB.boost_help_show_requested.connect(_on_boost_help_show_requested)
	SB.boost_help_hide_requested.connect(_on_boost_help_hide_requested)
	PD.start_game([
		dev_center_mid, dev_left_mid, dev_right_mid,
		dev_center_bot, dev_left_bot, dev_right_bot,
		dev_center_top, dev_left_top, dev_right_top,
	])

# --- Handlers ---

func _on_boost_help_show_requested() -> void:
	if boost_help.visible:
		return
	boost_help.visible = true


func _on_boost_help_hide_requested() -> void:
	if not boost_help.visible:
		return
	var tween: Tween = create_tween()
	tween.tween_property(boost_help, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		boost_help.visible = false
		boost_help.modulate.a = 1.0)
