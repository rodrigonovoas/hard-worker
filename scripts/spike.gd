extends StaticBody2D


func _physics_process(_delta: float) -> void:
	for body in $Area2D.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(1)
