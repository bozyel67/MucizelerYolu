extends CharacterBody3D

var player
var target_house = null
var is_dead = false
var is_placed = false

func _ready():
	player = get_node_or_null("/root/Main/Player")
	add_to_group("child")

func _physics_process(delta):
	if is_dead or is_placed or not player: return
	
	var target_pos = player.global_position if not target_house else target_house
	var dist = global_position.distance_to(target_pos)
	
	if dist > 3.0:
		var dir = (target_pos - global_position).normalized()
		dir.y = 0
		velocity = dir * 4.0
	else:
		velocity = Vector3.ZERO
		if target_house:
			is_placed = true
			get_node("/root/Main").child_placed()
			
	if not is_on_floor():
		velocity.y -= 15.0 * delta
		
	move_and_slide()

func take_damage(amount: int):
	if is_dead: return
	is_dead = true
	rotation.x = deg_to_rad(90)
	get_node("/root/Main").child_sacrificed()
