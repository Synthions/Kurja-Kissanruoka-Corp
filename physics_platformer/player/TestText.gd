extends Label


var farme = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func update_health(nambu:int):
	self.text="Health: " + str(nambu)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
