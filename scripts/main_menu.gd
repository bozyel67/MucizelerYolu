extends Control

@onready var label = $PressAnyKeyLabel

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_timer_timeout():
	label.visible = !label.visible

func _input(event):
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			get_tree().change_scene_to_file("res://scenes/main.tscn")
