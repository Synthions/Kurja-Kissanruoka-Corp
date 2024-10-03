extends Node


# References to the nodes in our scene
@onready var _anim_player := $AnimationPlayer
@onready var _track_1 := $Track1
@onready var _track_2 := $Track2

var playing = 0

@export var library: Array[AudioStream] = []

func _ready() -> void:
	crossfade_to(library[0]) #start playing overworld automatically

func _process(delta: float) -> void:
	
	var musicbutton := Input.is_action_just_pressed(&"debug_music")
	var musicbutton2 := Input.is_action_just_pressed(&"insta_music")
	
	if musicbutton: # change song on M
		autofade()
		
	if musicbutton2: # change song on N
		autofade(1)
		print("jojo")

func autofade(type: int = 0):
	if type == 0:
		crossfade_to(library[playing])
	else:
		swap_to(library[playing])
	playing = (playing + 1) % library.size()

# crossfades to a new audio stream
func crossfade_to(audio_stream: AudioStream) -> void:
	# If both tracks are playing, we're calling the function in the middle of a fade.
	# We return early to avoid jumps in the sound.
	if _track_1.playing and _track_2.playing:
		return

	# The `playing` property of the stream players tells us which track is active. 
	# If it's track two, we fade to track one, and vice-versa.
	if _track_2.playing:
		_track_1.stream = audio_stream
		_track_1.seek(0)
		_track_1.play()
		_anim_player.play("Fade2")
	else:
		_track_2.stream = audio_stream
		_track_2.seek(0)
		_track_2.play()
		_anim_player.play("Fade1")

func swap_to(audio_stream: AudioStream) -> void:
	# If both tracks are playing, we're calling the function in the middle of a fade.
	# We return early to avoid jumps in the sound.
	if _track_1.playing and _track_2.playing:
		return

	# The `playing` property of the stream players tells us which track is active. 
	# If it's track two, we fade to track one, and vice-versa.
	if _track_2.playing:
		_track_1.stream = audio_stream
		_track_1.seek(0)
		_track_1.play()
		_track_1.volume_db = 0
		_track_2.volume_db = -80
		_track_2.playing = false
	else:
		_track_2.stream = audio_stream
		_track_2.seek(0)
		_track_2.play()
		_track_1.volume_db = -80
		_track_2.volume_db = 0
		_track_1.playing = false


func _on_boss_door_intruder() -> void:
	crossfade_to(library[1])
	


func _on_player_victory_signal() -> void:
	swap_to(library[3])
