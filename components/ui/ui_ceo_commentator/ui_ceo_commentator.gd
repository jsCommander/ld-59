class_name UiCeoCommentator
extends Control

# --- Enums ---

enum Mood {NEUTRAL, HAPPY, SAD}

# --- Constants ---

const SLOW_SPRINT_THRESHOLD: float = 30.0

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

const SPRINT_DONE_COMMENTS: Array[String] = [
	"Sprint shipped! Great work team!",
	"Another sprint in the bag!",
	"Delivered! Investors happy!",
	"Ship it! Next sprint!",
	"That's what I like to see!",
]

const MILESTONE_COMMENTS: Array[String] = [
	"We're bigger than \"%s!\"",
	# "Take that, %s!",
]

# --- @onready ---

@onready var comments_label: Label = %Comments
@onready var _mouth_good: Sprite2D = %MouthGood
@onready var _mouth_bad: Sprite2D = %MouthBad
@onready var _dollars: Sprite2D = %Dollars

# --- State ---

var _last_milestone: String = ""
var _is_slow: bool = false

# --- Lifecycle ---

func _ready() -> void:
	comments_label.text = ""
	_set_mood(Mood.NEUTRAL)
	SB.level_up.connect(_on_sprint_completed)
	SB.valuation_changed.connect(_on_valuation_changed)

func _process(_delta: float) -> void:
	if not PD._game_active:
		return
	var slow_now: bool = PD.sprint_time >= SLOW_SPRINT_THRESHOLD
	if slow_now and not _is_slow:
		_is_slow = true
		_set_comment(SLOW_SPRINT_COMMENTS[randi() % SLOW_SPRINT_COMMENTS.size()], Mood.SAD)
	elif not slow_now:
		_is_slow = false

# --- Handlers ---

func _on_sprint_completed(_level: int) -> void:
	pass
	#_set_comment(SPRINT_DONE_COMMENTS[randi() % SPRINT_DONE_COMMENTS.size()])

func _on_valuation_changed() -> void:
	var current_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if PD.valuation >= milestone["valuation"]:
			current_company = milestone["name"]
	if current_company != "" and current_company != _last_milestone:
		_last_milestone = current_company
		var template: String = MILESTONE_COMMENTS[randi() % MILESTONE_COMMENTS.size()]
		_set_comment(template % current_company, Mood.HAPPY)

# --- Private ---

func _set_comment(text: String, mood: Mood = Mood.NEUTRAL) -> void:
	comments_label.text = text
	_set_mood(mood)


func _set_mood(mood: Mood) -> void:
	_mouth_good.visible = mood != Mood.SAD
	_dollars.visible = mood == Mood.HAPPY
	_mouth_bad.visible = mood == Mood.SAD
