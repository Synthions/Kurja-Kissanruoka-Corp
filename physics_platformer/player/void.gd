extends Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var texture_size = texture.get_size()
	offset.x = -texture_size.x / 2
	position.x += texture_size.x * scale.x / 2
