extends CharacterBody3D

var speed = 20.0
var lifetime = 2.0
var direction = Vector3.FORWARD

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
		
	var collision = move_and_collide(direction * speed * delta)
	if collision:
		var col = collision.get_collider()
		if col.is_in_group("kabe_build_area"):
			get_node("/root/Main").build_kabe_roof()
		queue_free()
