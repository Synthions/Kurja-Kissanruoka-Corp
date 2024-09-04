extends Node2D

@onready var animation_player := $AnimationPlayer as AnimationPlayer

var anim := ""
var pickedup := false

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("area_entered", Callable(self, "_on_area_entered"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var new_anim := anim
	if pickedup == false:
		new_anim = "hover"
#	else:
#		new_anim = "dissapear"
	
	if anim != new_anim:
		anim = new_anim
		($AnimationPlayer as AnimationPlayer).play(anim)

#func _on_area_entered(body: Node) -> void:
#	if body is Player:
#		dothething()
#
#func dothething():
#	pickedup = true
#	print("you have done the thing!")
