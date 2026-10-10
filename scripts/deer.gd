extends CharacterBody3D

var hp = 100
var is_dead = false
var speed = 6.0
var player

func _ready():
	player = get_node_or_null("/root/Main/Player")
	add_to_group("deer")
	# Head hurtbox setup is in Main script when spawning

func _physics_process(delta):
	if is_dead or not player: return
	
	# Run away if player is near
	var dist = global_position.distance_to(player.global_position)
	if dist < 15.0:
		var dir = (global_position - player.global_position).normalized()
		dir.y = 0
		velocity = dir * speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity = Vector3.ZERO
		
	if not is_on_floor():
		velocity.y -= 15.0 * delta
		
	move_and_slide()

func take_damage(amount: int, is_headshot: bool = false):
	if is_dead: return
	if is_headshot:
		hp -= 100
		get_node("/root/Main").queue_dialogue("Kafadan vuruş!", 2.0)
	else:
		hp -= amount
	
	if hp <= 0:
		is_dead = true
		velocity = Vector3.ZERO
		rotation.x = deg_to_rad(90) # fall over
		get_node("/root/Main").deer_killed(self)
