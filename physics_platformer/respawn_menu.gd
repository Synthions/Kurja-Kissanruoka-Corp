extends Control


func _on_respawn_pressed():
	get_tree().change_scene_to_file("res://stage.tscn")


func _on_return_to_main_menu_pressed():
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_quit_game_pressed():
	get_tree().quit()
