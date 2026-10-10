extends CharacterBody3D

var hp = 300
var is_active = false
var snake_timer = 0.0
var fireball_timer = 0.0
var player: CharacterBody3D

func _ready():
	player = get_node_or_null("/root/Main/Player")
	add_to_group("boss")

func activate():
	is_active = true

func _physics_process(delta):
	if not is_active or not player or hp <= 0: return
	
	snake_timer += delta
	fireball_timer += delta
	
	if snake_timer >= 3.0:
		snake_timer = 0.0
		# Spawn 3 snakes towards player
		for i in range(3):
			get_node("/root/Main").spawn_boss_snake(global_position + Vector3(randf_range(-10, 10), 0, 15))
			
	if fireball_timer >= 10.0:
		fireball_timer = 0.0
		get_node("/root/Main").spawn_boss_fireball(global_position + Vector3(0, 10, 10))

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		get_node("/root/Main").boss_defeated()
		queue_free()
