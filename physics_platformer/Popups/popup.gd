extends Node2D

var held := false
var last_mouse_pos = Vector2()

@export var popup_sounds: Array[AudioStream] = []

func _ready() -> void:
	var audio_player = $AudioStreamPlayer2D
	#await get_tree().create_timer(1.5).timeout
	audio_player.stream = popup_sounds[randi() % popup_sounds.size()]
	audio_player.seek(0)
	audio_player.play()
	audio_player.volume_db = 0
	print("MAU!", audio_player.stream)
	
	
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
	#This whole function is useless. It does nothing since text lines were removed.
	var field := $"Popup holder/Popup border/LineEdit"

	field.text = "WRONG"
	field.editable = false
	await get_tree().create_timer(1.5).timeout
	field.clear()
	field.editable = true


func _on_audio_stream_player_2d_finished() -> void:
	print("sound has completed WTFFF")
