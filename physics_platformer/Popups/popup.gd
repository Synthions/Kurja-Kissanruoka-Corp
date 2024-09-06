extends Node2D

var held := false
var last_mouse_pos = Vector2()

func _on_x_button_pressed() -> void:
	queue_free()

func _on_drag_area_button_down() -> void:
	held = true
	
func _on_drag_area_button_up() -> void:
	held = false
	print(position)


func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var mouse_delta = mouse_pos - last_mouse_pos
	last_mouse_pos = mouse_pos
	
	if held:
		position += mouse_delta
