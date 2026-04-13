class_name UiCeoComment
extends Control

# --- Constants ---

const COMMENT_INTERVAL: float = 5.0

const GOOD_COMMENTS: Array[String] = [
	"Stonks 📈",
	"To the moon!",
	"Amazing velocity!",
	"Ship it!",
	"We're crushing it!",
	"Investors will love this!",
	"10x engineers!",
	"This is the way",
]

const BAD_COMMENTS: Array[String] = [
	"Have you tried working harder?",
	"Let's circle back on this",
	"We need to pivot",
	"Per my last email...",
	"Let's take this offline",
	"Can we 2x the velocity?",
	"Why isn't this done yet?",
	"I'll put it on the agenda",
]

# --- @onready ---

@onready var comment_label: Label = %CommentLabel

# --- State ---

var _flash_tween: Tween
var _comment_timer: float = 0.0
var _last_milestone: String = ""

# --- Lifecycle ---

func _ready() -> void:
	SB.valuation_changed.connect(_on_valuation_changed)
	visible = false


func _process(delta: float) -> void:
	_comment_timer += delta
	if _comment_timer >= COMMENT_INTERVAL:
		_comment_timer -= COMMENT_INTERVAL
		_show_random_comment()

# --- Handlers ---

func _on_valuation_changed() -> void:
	var current_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if PD.valuation >= milestone["valuation"]:
			current_company = milestone["name"]
	if current_company and current_company != _last_milestone:
		_last_milestone = current_company
		_show_comment("Bigger than %s!" % current_company)

# --- Private ---

func _show_random_comment() -> void:
	if not PD._game_active:
		return
	var comments: Array[String] = GOOD_COMMENTS + BAD_COMMENTS
	_show_comment(comments[randi() % comments.size()])


func _show_comment(text: String) -> void:
	comment_label.text = text
	if _flash_tween:
		_flash_tween.kill()
	visible = true
	modulate.a = 0.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate:a", 1.0, 0.15)
	_flash_tween.tween_interval(2.0)
	_flash_tween.tween_property(self, "modulate:a", 0.0, 0.8)
	_flash_tween.tween_callback(func() -> void: visible = false)
