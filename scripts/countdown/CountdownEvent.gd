class_name CountdownEvent extends Node


signal timeout


@export var time := 30.0



var timer : Timer


func _ready() -> void:
	if !timer:
		timer = Timer.new()
		add_child(timer)
	
	timer.timeout.connect(_on_timeout)
	
	# TODO: create timer label to display time remaining in ui, let an autoload manage it
	

func start() -> void:
	timer.start(time)


func _on_timeout() -> void:
	timeout.emit()
