extends Node

var music_player: AudioStreamPlayer
var is_on_cooldown: bool = false

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

# --- УПРАВЛІННЯ МУЗИКОЮ ---
func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	
	if music_player.stream == stream and music_player.playing:
		return 
	
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()

# --- УПРАВЛІННЯ ЗВУКАМИ (SFX) ---
# Ця функція створює тимчасовий плеєр для кожного звуку. 
# За принципом перший bool рандомізуї звук, другий виставляє cooldown.
func play_sfx(stream: AudioStream, randomize_pitch: bool = false, ignore_cooldown: bool = false) -> void:
	if stream == null:
		return
	
	if not ignore_cooldown and is_on_cooldown:
		return
		
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.bus = "SFX"
	sfx_player.volume_db = 5.0
	
	if randomize_pitch:
		sfx_player.pitch_scale = randf_range(0.85, 1.15) 
		
	add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)
	
	if not ignore_cooldown:
		_start_cooldown()

# --- COOLDOWN ---
func _start_cooldown() -> void:
	is_on_cooldown = true
	await get_tree().create_timer(1.0).timeout 
	is_on_cooldown = false

# --- НАЛАШТУВАННЯ ГУЧНОСТІ ТА MUTE ---
func set_music_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func set_sfx_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func set_music_mute(is_muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), is_muted)

func set_sfx_mute(is_muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), is_muted)
