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
	register_sfx(Constants.Sfx.EXPLOSION, preload("res://assets/sfx/explosion.wav"))
	register_sfx(Constants.Sfx.CLICK, preload("res://assets/sfx/whip_shot_2.mp3"))


func _connect_signals() -> void:
	SB.task_destroyed.connect(_on_task_destroyed)
	SB.player_boost_applied.connect(_on_player_boost_applied)


func _on_task_destroyed(_task: TaskData) -> void:
	play_sfx(Constants.Sfx.EXPLOSION, 0.3)


func _on_player_boost_applied(_developer: Developer) -> void:
	play_sfx(Constants.Sfx.CLICK, 0.15)
