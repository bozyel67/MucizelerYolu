extends CharacterBody3D

var speed = 40.0
var damage = 20
var lifetime = 3.0
var direction = Vector3.FORWARD

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
		
	var collision = move_and_collide(direction * speed * delta)
	if collision:
		var col = collision.get_collider()
		if col.is_in_group("deer_head"):
			col.get_parent().take_damage(100, true)
		elif col.is_in_group("deer"):
			col.take_damage(damage, false)
		queue_free()
