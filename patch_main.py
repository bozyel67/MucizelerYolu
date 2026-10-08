import sys

with open("scripts/main.gd", "r") as f:
    lines = f.readlines()

new_code = []
in_ready = False
for line in lines:
    if "func _ready():" in line:
        new_code.append(line)
        new_code.append("\t_build_stage_2()\n")
    elif "func interact_with_door():" in line:
        new_code.append(line)
    elif "BÖLÜM 2'ye (Hz. Nuh) YÜKLENİYOR..." in line:
        new_code.append(line)
        new_code.append("\t\t# Transition to Stage 2 handled by player walking through corridor\n")
    else:
        new_code.append(line)

# Now we need to append the new build functions at the end
stage_2_code = """
func _build_stage_2():
	var marble_mat = StandardMaterial3D.new()
	var marble_tex = load("res://marble_diffuse.png")
	if marble_tex: marble_mat.albedo_texture = marble_tex
	
	var ceramic_mat = StandardMaterial3D.new()
	var ceramic_tex = load("res://ceramic_diffuse.png")
	if ceramic_tex: ceramic_mat.albedo_texture = ceramic_tex
	
	# Corridor 1 (Z: -60 to -255)
	# Platforming gaps (boşluklar). Let's make blocks of length 20, gap 5
	for z in range(-60, -255, -25):
		var floor_block = CSGBox3D.new()
		floor_block.size = Vector3(6, 1, 15)
		floor_block.position = Vector3(0, 12.0, z - 7.5)
		floor_block.use_collision = true
		floor_block.material = ceramic_mat
		env_node.add_child(floor_block)
	
	# Corridor walls
	var left_wall = CSGBox3D.new()
	left_wall.size = Vector3(1, 20, 200)
	left_wall.position = Vector3(-3.5, 22.0, -155)
	left_wall.use_collision = true
	left_wall.material = marble_mat
	env_node.add_child(left_wall)
	
	var right_wall = CSGBox3D.new()
	right_wall.size = Vector3(1, 20, 200)
	right_wall.position = Vector3(3.5, 22.0, -155)
	right_wall.use_collision = true
	right_wall.material = marble_mat
	env_node.add_child(right_wall)
	
	# Junction Platform at Z = -255
	var junction = CSGBox3D.new()
	junction.size = Vector3(10, 1, 10)
	junction.position = Vector3(0, 12.0, -255)
	junction.use_collision = true
	junction.material = ceramic_mat
	env_node.add_child(junction)
	
	# Chest at junction
	var chest = CSGBox3D.new()
	chest.size = Vector3(2, 1.5, 1.5)
	chest.position = Vector3(0, 13.25, -258)
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.3, 0.15, 0.05)
	chest.material = wood_mat
	
	var chest_body = StaticBody3D.new()
	chest_body.add_to_group("chest")
	var chest_col = CollisionShape3D.new()
	var chest_shape = BoxShape3D.new()
	chest_shape.size = chest.size
	chest_col.shape = chest_shape
	chest_body.add_child(chest_col)
	chest.add_child(chest_body)
	env_node.add_child(chest)
	
	# Right Corridor (X: 5 to 105)
	# Platform gaps
	for x in range(5, 100, 20):
		var floor_block = CSGBox3D.new()
		floor_block.size = Vector3(14, 1, 6)
		floor_block.position = Vector3(x + 7, 12.0, -255)
		floor_block.use_collision = true
		floor_block.material = ceramic_mat
		env_node.add_child(floor_block)
		
	# Right Corridor Walls
	var r_wall_back = CSGBox3D.new()
	r_wall_back.size = Vector3(100, 20, 1)
	r_wall_back.position = Vector3(50, 22.0, -258.5)
	r_wall_back.use_collision = true
	r_wall_back.material = marble_mat
	env_node.add_child(r_wall_back)
	
	var r_wall_front = CSGBox3D.new()
	r_wall_front.size = Vector3(100, 20, 1)
	r_wall_front.position = Vector3(50, 22.0, -251.5)
	r_wall_front.use_collision = true
	r_wall_front.material = marble_mat
	env_node.add_child(r_wall_front)
	
	# Snake
	var snake = CSGCylinder3D.new()
	snake.radius = 1.0
	snake.height = 3.0
	snake.position = Vector3(95, 13.5, -255)
	var snake_mat = StandardMaterial3D.new()
	snake_mat.albedo_color = Color(0, 0.8, 0)
	snake.material = snake_mat
	
	var snake_body = StaticBody3D.new()
	snake_body.add_to_group("snake")
	var snake_col = CollisionShape3D.new()
	var snake_shape = CylinderShape3D.new()
	snake_shape.radius = 1.0
	snake_shape.height = 3.0
	snake_col.shape = snake_shape
	snake_body.add_child(snake_col)
	snake.add_child(snake_body)
	env_node.add_child(snake)
	
	# Stage 2 Door
	var door2 = CSGBox3D.new()
	door2.name = "Door2"
	door2.size = Vector3(1, 10, 6)
	door2.position = Vector3(102, 17.0, -255)
	var door_mat = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.2, 0.2, 0.2)
	door2.material = door_mat
	
	var d2_body = StaticBody3D.new()
	d2_body.add_to_group("door2")
	var d2_col = CollisionShape3D.new()
	var d2_shape = BoxShape3D.new()
	d2_shape.size = door2.size
	d2_col.shape = d2_shape
	d2_body.add_child(d2_col)
	door2.add_child(d2_body)
	env_node.add_child(door2)
	
	# Open World (Stage 2)
	var ow_ground = CSGBox3D.new()
	ow_ground.size = Vector3(100, 1, 100)
	ow_ground.position = Vector3(155, 12.0, -255)
	ow_ground.use_collision = true
	ow_ground.material = ceramic_mat
	env_node.add_child(ow_ground)
	
	# Castle (200 sqm ~ 14x14)
	var castle = CSGBox3D.new()
	castle.size = Vector3(14, 15, 14)
	castle.position = Vector3(180, 19.5, -255)
	castle.use_collision = true
	castle.material = marble_mat
	env_node.add_child(castle)
	
	for x in [173, 187]:
		for z in [-248, -262]:
			var tower = CSGCylinder3D.new()
			tower.radius = 2.0
			tower.height = 20.0
			tower.position = Vector3(x, 22.0, z)
			tower.material = marble_mat
			env_node.add_child(tower)
			
	# Open world greenery
	for pos in [Vector3(130, 12.5, -230), Vector3(140, 12.5, -280), Vector3(160, 12.5, -220)]:
		var bush = CSGSphere3D.new()
		bush.radius = 2.0
		bush.position = pos
		var g_mat = StandardMaterial3D.new()
		g_mat.albedo_color = Color(0.1, 0.5, 0.1)
		bush.material = g_mat
		env_node.add_child(bush)

func interact_with_chest(chest_node):
	queue_dialogue("Sandıktan bir kılıç aldın! (Sol el - Q tuşu)", 4.0)
	chest_node.queue_free()
	var player = get_node("/root/Main/Player")
	player.equip_sword()

func interact_with_door2(door_node):
	var snake = env_node.get_node_or_null("Snake")
	if snake == null or not snake.is_inside_tree():
		queue_dialogue("Kapı açılıyor... Açık Dünyaya Hoşgeldin!", 4.0)
		var tw = create_tween()
		tw.tween_property(door_node, "position:y", door_node.position.y + 10, 3.0)
		
		# Change sky to nebula
		var env = get_node("/root/Main/WorldEnvironment").environment
		var sky_mat = PanoramaSkyMaterial.new()
		sky_mat.panorama = load("res://nebula.jpg")
		env.sky.sky_material = sky_mat
		
		# Add 3D Clouds over Open World
		var cloud_mat = StandardMaterial3D.new()
		cloud_mat.albedo_color = Color(1, 1, 1, 0.7)
		cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		for i in range(10):
			var cloud = FogVolume.new()
			cloud.shape = 1
			cloud.size = Vector3(30, 10, 30)
			cloud.position = Vector3(randf_range(110, 190), randf_range(30, 60), randf_range(-210, -290))
			cloud.material = cloud_mat
			env_node.add_child(cloud)
	else:
		queue_dialogue("Önce yılanı öldürmelisin!", 3.0)
"""

new_code.append(stage_2_code)

with open("scripts/main.gd", "w") as f:
    f.writelines(new_code)
