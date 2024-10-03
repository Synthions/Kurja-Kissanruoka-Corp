extends Node2D
class_name Boss_door

signal INTRUDER

func drop():
	$Node2D/AnimationPlayer.play("Close")
	
var triggered = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		if !triggered:
			triggered = true
			drop()
			emit_signal("INTRUDER")
