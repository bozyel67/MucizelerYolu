extends CharacterBody3D

var speed = 25.0
var damage = 200
var lifetime = 5.0
var direction = Vector3.FORWARD

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
		
	var collision = move_and_collide(direction * speed * delta)
	if collision:
		var col = collision.get_collider()
		if col.is_in_group("snake"):
			var snake = col if col.has_method("take_damage") else col.get_parent()
			if snake and snake.has_method("take_damage"):
				snake.take_damage(damage)
		elif col.is_in_group("boss"):
			var boss = col if col.has_method("take_damage") else col.get_parent()
			if boss and boss.has_method("take_damage"):
				boss.take_damage(damage)
		queue_free()
