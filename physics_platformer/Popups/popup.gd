extends Node2D

var held := false
var last_mouse_pos = Vector2()

func _on_x_button_pressed() -> void:
	queue_free()

func _on_drag_area_button_down() -> void:
	held = true
	
func _on_drag_area_button_up() -> void:
	held = false
	#print(position)


func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var mouse_delta = mouse_pos - last_mouse_pos
	last_mouse_pos = mouse_pos
	
	if held:
		position += mouse_delta


func _on_line_edit_text_submitted(new_text: String) -> void:
	var field := $"Popup holder/Popup border/LineEdit"

	field.text = "WRONG"
	field.editable = false
	await get_tree().create_timer(1.5).timeout
	field.clear()
	field.editable = true
