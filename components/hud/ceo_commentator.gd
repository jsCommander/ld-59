class_name CeoCommentator
extends Control

@onready var speech_bubble: Label = %SpeechBubble

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

var _comment_timer: float = 0.0
const COMMENT_INTERVAL: float = 5.0


func _ready() -> void:
	SB.sprint_ended.connect(_on_sprint_ended)
	speech_bubble.text = ""


func _process(delta: float) -> void:
	_comment_timer += delta
	if _comment_timer >= COMMENT_INTERVAL:
		_comment_timer -= COMMENT_INTERVAL
		_show_performance_comment()


func _show_performance_comment() -> void:
	if not PD._sprint_active:
		return
	var ratio: float = PD.sprint_timer / PD.sprint_duration
	if ratio > 0.3:
		speech_bubble.text = GOOD_COMMENTS[randi() % GOOD_COMMENTS.size()]
	else:
		speech_bubble.text = BAD_COMMENTS[randi() % BAD_COMMENTS.size()]


func _on_sprint_ended(_sprint_number: int, bonus: int) -> void:
	if bonus > 0:
		speech_bubble.text = "Stonks! +$%d 📈" % bonus
	else:
		speech_bubble.text = "We need to talk..."
