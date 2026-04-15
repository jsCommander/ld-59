class_name UiCeoComment
extends Control

# --- Constants ---

const COMMENT_INTERVAL: float = 5.0
const SLOW_SPRINT_THRESHOLD: float = 30.0

const MILESTONE_COMMENTS: Array[String] = [
	"Bigger than %s!",
	"We just passed %s!",
	"Take that, %s!",
	"%s is in our rearview mirror!",
]

const SLOW_SPRINT_COMMENTS: Array[String] = [
	"This sprint is taking forever...",
	"Can we 2x the velocity?",
	"Why isn't this sprint done yet?",
	"Have you tried working harder?",
	"Let's circle back on this sprint",
	"We need to ship faster!",
	"Investors are watching...",
	"Per my last email... ship it",
]

const VALUATION_COMMENTS: Array[String] = [
	"Stonks 📈",
	"To the moon!",
	"Investors will love this!",
	"We're crushing it!",
	"This is the way",
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
		_show_periodic_comment()

# --- Handlers ---

func _on_valuation_changed() -> void:
	var current_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if PD.valuation >= milestone["valuation"]:
			current_company = milestone["name"]
	if current_company and current_company != _last_milestone:
		_last_milestone = current_company
		var template: String = MILESTONE_COMMENTS[randi() % MILESTONE_COMMENTS.size()]
		_show_comment(template % current_company)

# --- Private ---

func _show_periodic_comment() -> void:
	if not PD._game_active:
		return
	if PD.sprint_time >= SLOW_SPRINT_THRESHOLD:
		_show_comment(SLOW_SPRINT_COMMENTS[randi() % SLOW_SPRINT_COMMENTS.size()])
	else:
		_show_comment(VALUATION_COMMENTS[randi() % VALUATION_COMMENTS.size()])


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
