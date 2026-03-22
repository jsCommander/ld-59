class_name ProduceProgressBar
extends ProgressBar

var _produce_trait: ProduceTrait


func _ready() -> void:
	visible = false
	set_process(false)

	for child: Node in get_parent().get_children():
		if child is ProduceTrait:
			_produce_trait = child
			break

	if not _produce_trait:
		Log.log_warn(name, "No ProduceTrait found among siblings")
		return

	_produce_trait.started.connect(_on_started)
	_produce_trait.stopped.connect(_on_stopped)
	_produce_trait.produced.connect(_on_produced)


func _on_started() -> void:
	visible = true
	set_process(true)


func _on_stopped() -> void:
	visible = false
	value = 0
	set_process(false)


func _on_produced(_product: Product) -> void:
	visible = false
	value = 0
	set_process(false)


func _process(_delta: float) -> void:
	if _produce_trait:
		value = _produce_trait._elapsed / _produce_trait.produce_time * max_value
