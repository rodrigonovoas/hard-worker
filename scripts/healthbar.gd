extends ProgressBar


func _ready() -> void:
	# Style the healthbar
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.9, 0.2, 0.2, 1.0)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	
	add_theme_stylebox_override("background", bg_style)
	add_theme_stylebox_override("fill", fill_style)
	
	# Find player and connect to health signal
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		# Fallback: search by name
		var root := get_tree().current_scene
		if root:
			player = root.find_child("Player", true, false)
	
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
		value = player.current_health
	else:
		push_warning("Healthbar: Could not find Player with health_changed signal")


func _on_health_changed(new_health: int) -> void:
	value = new_health
