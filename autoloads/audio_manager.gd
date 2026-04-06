class_name AudioManager extends BaseAudioManager


func _ready() -> void:
	super._ready()
	_register_music()
	_register_sfx()
	_connect_signals()


func _register_music() -> void:
	register_music(Constants.Music.FR, preload("res://assets/music/fr.mp3"))
	register_music(Constants.Music.FR3, preload("res://assets/music/fr3.mp3"))
	register_music(Constants.Music.SG, preload("res://assets/music/sg.mp3"))
	register_music(Constants.Music.SPB, preload("res://assets/music/spb.mp3"))


func _register_sfx() -> void:
	register_sfx(Constants.Sfx.PICKUP, preload("res://assets/sfx/pickupCoin.wav"))
	register_sfx(Constants.Sfx.HIT_HURT, preload("res://assets/sfx/hitHurt.wav"))


func _connect_signals() -> void:
	SB.task_clicked.connect(_on_task_clicked)
	SB.task_finished.connect(_on_task_finished)


func _on_task_clicked(_task: TaskData) -> void:
	play_sfx(Constants.Sfx.PICKUP, 0.2)


func _on_task_finished(_developer: Developer, _task: TaskData) -> void:
	play_sfx(Constants.Sfx.HIT_HURT, 0.3)
