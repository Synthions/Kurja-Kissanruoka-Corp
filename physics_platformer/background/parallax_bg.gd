extends ParallaxBackground


# Called when the node enters the scene tree for the first time.

	
func _on_player_victory_signal() -> void:
	print("AWOOOOGA")
	$AnimationPlayer.play("GET DOWN!!!")
