extends Node3D

@onready var ui_dialogue = $CanvasLayer/Control/DialogueLabel
@onready var ui_apples = $CanvasLayer/Control/ApplesLabel
@onready var player = $Player
@onready var env_node = $Environment

var apples_collected = 0
var apples_handed = 0
var has_key = false
var has_plank = false
var total_apples = 5
var dialogue_timer = 0.0
var active_dialogue_queue = []

func _ready():
	_build_stage_2()
	_setup_inputs()
	_build_world()
	
	ui_apples.text = "Elma: 0 / 5"
	ui_dialogue.text = ""
	
	queue_dialogue("Ne? Ne oluyor?", 3.0)
	queue_dialogue("Neredeyim ben?", 3.0)
	queue_dialogue("Ben kimim?", 3.0)

func _process(delta):
	if active_dialogue_queue.size() > 0:
		dialogue_timer -= delta
		if dialogue_timer <= 0:
			show_next_dialogue()
	else:
		if dialogue_timer > 0:
			dialogue_timer -= delta
			if dialogue_timer <= 0:
				ui_dialogue.text = ""

func queue_dialogue(text: String, duration: float = 3.0):
	active_dialogue_queue.append({"text": text, "duration": duration})
	if active_dialogue_queue.size() == 1 and dialogue_timer <= 0:
		show_next_dialogue()

func show_next_dialogue():
	if active_dialogue_queue.size() > 0:
		var item = active_dialogue_queue.pop_front()
		ui_dialogue.text = item["text"]
		dialogue_timer = item["duration"]

func collect_apple():
	apples_collected += 1
	ui_apples.text = "Elma: " + str(apples_collected) + " / " + str(total_apples)
	if apples_collected == total_apples:
		queue_dialogue("Harika, 5 elmayı da topladım. Dayıya geri döneyim.")

func interact_with_npc():
	if apples_collected < total_apples:
		if apples_handed == 0:
			queue_dialogue("Cennetin krallığına hoşgeldin yavrum.", 4.0)
			queue_dialogue("Sen ilk peygambersin.", 4.0)
			queue_dialogue("Seni yaratanla tanışmak için kapıdan içeri gir.", 4.0)
			queue_dialogue("Ama önce... Bana şu etraftaki 5 elmayı topla.", 5.0)
		else:
			queue_dialogue("Kalan elmaları topla.", 2.0)
	elif apples_handed < total_apples:
		apples_handed += 1
		ui_apples.text = "Teslim Edilen: " + str(apples_handed) + " / " + str(total_apples)
		queue_dialogue("Teşekkürler evlat... (" + str(apples_handed) + "/5)", 1.5)
		if apples_handed == total_apples:
			queue_dialogue("İşte sana cennetin kapısının anahtarı.", 4.0)
			queue_dialogue("Kapıya git ve E tuşuyla kullan.", 3.0)
			has_key = true
	else:
		queue_dialogue("Daha ne bekliyorsun? Kapıya git ve anahtarı kullan.", 3.0)

func interact_with_door():
	if has_key:
		queue_dialogue("Anahtar kabul edildi. Kapı açılıyor...", 3.0)
		var door_wall = env_node.get_node_or_null("Archway")
		if door_wall:
			var tw = create_tween()
			tw.tween_property(door_wall, "position:y", door_wall.position.y + 10, 3.0)
		queue_dialogue("BÖLÜM 2'ye (Hz. Nuh) YÜKLENİYOR...", 5.0)
		# Transition to Stage 2 handled by player walking through corridor
	else:
		queue_dialogue("Kapı kilitli. İhtiyar dayıyla konuşmalıyım.", 3.0)

func pickup_plank(node: Node):
	has_plank = true
	node.queue_free()
	queue_dialogue("Uzun bir tahta parçası aldın. Uzaktaki platformlara ulaşmak için köprü yapabilirsin.", 4.0)

func place_plank(node: Node):
	if has_plank:
		has_plank = false
		queue_dialogue("Tahtayı yerleştirdin!", 2.0)
		
		# Görünmez tahtayı gerçek ve çarpışmalı bir tahtaya çevir
		node.remove_from_group("plank_place")
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.25, 0.1) # Kahverengi tahta rengi
		node.material = mat
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = node.size
		col.shape = shape
		
		var body = StaticBody3D.new()
		body.add_child(col)
		node.add_child(body)
	else:
		queue_dialogue("Buradaki boşluk çok büyük. Karşıya geçmek için uzun bir tahta lazım.", 3.0)

func _build_world():
	# Seramik Zemin Materyali (Yansımalı ve Dokulu)
	var ceramic_mat = StandardMaterial3D.new()
	var ceramic_tex = load("res://ceramic_diffuse.png")
	if ceramic_tex:
		ceramic_mat.albedo_texture = ceramic_tex
		ceramic_mat.uv1_scale = Vector3(10, 10, 10) # Döşeme tekrarı
	else:
		ceramic_mat.albedo_color = Color(0.95, 0.95, 0.97)
	ceramic_mat.roughness = 0.05
	ceramic_mat.metallic = 0.1
	
	# Beyaz Mermer/Duvar Materyali (Sütunlar ve Mimari için)
	var marble_mat = StandardMaterial3D.new()
	var marble_tex = load("res://marble_diffuse.png")
	if marble_tex:
		marble_mat.albedo_texture = marble_tex
		marble_mat.uv1_scale = Vector3(2, 2, 2)
	else:
		marble_mat.albedo_color = Color(1, 1, 1)
	marble_mat.roughness = 0.3
	
	# Ana Zemin
	var ground = CSGBox3D.new()
	ground.size = Vector3(30, 1, 30)
	ground.position = Vector3(0, -0.5, 0)
	ground.use_collision = true
	ground.material = ceramic_mat
	env_node.add_child(ground)
	
	# Merdivenleri oluştur
	for i in range(25):
		var step = CSGBox3D.new()
		step.size = Vector3(8, 0.5, 1.2)
		step.position = Vector3(0, i * 0.5, -15 - (i * 1.0))
		step.use_collision = true
		step.material = ceramic_mat
		env_node.add_child(step)
	
	# Kapı ve Dayı platformu (Merdivenin sonunda)
	var top_platform = CSGBox3D.new()
	top_platform.size = Vector3(20, 1, 20)
	top_platform.position = Vector3(0, 12, -49)
	top_platform.use_collision = true
	top_platform.material = ceramic_mat
	env_node.add_child(top_platform)
	
	# Bahçe / Yeşillikler (Simetrik Otlar/Çalılar)
	_build_garden()
	
	# Antik Yunan Sütunları
	_build_colonnade(marble_mat)
	
	# Gezegenleri gökyüzüne yerleştir
	_build_planets()
	
	# Bulutlar (FogVolumes)
	_build_clouds()
	
	# Cennetin Kapısı (Kemerli Tasarım)
	_build_archway(marble_mat)
	
	# İhtiyar Dayı (NPC)
	var npc = CSGCylinder3D.new()
	npc.name = "NPC"
	npc.radius = 0.5
	npc.height = 1.9
	npc.position = Vector3(0, 13.5, -45)
	npc.use_collision = true
	var npc_body = StaticBody3D.new()
	npc_body.add_to_group("npc")
	npc.add_child(npc_body)
	var npc_col = CollisionShape3D.new()
	var npc_shape = CylinderShape3D.new()
	npc_shape.radius = 0.6
	npc_shape.height = 2.0
	npc_col.shape = npc_shape
	npc_body.add_child(npc_col)
	
	var npc_mat = StandardMaterial3D.new()
	npc_mat.albedo_color = Color(1, 1, 1)
	npc_mat.emission_enabled = true
	npc_mat.emission = Color(1, 1, 1)
	npc_mat.emission_energy_multiplier = 0.3
	npc.material = npc_mat
	env_node.add_child(npc)
	
	# Gerçekçi Elma Materyali ve Yüklemesi
	var apple_mesh_resource = load("res://apple.obj")
	var a_mat = StandardMaterial3D.new()
	a_mat.albedo_color = Color(0.85, 0.1, 0.1) # Parlak Kırmızı
	a_mat.roughness = 0.15 
	
	# Platformlar ve Elmalar (İlk 4'ü merdivenlerin sağ ve solunda zıplanabilir mesafede)
	# (Merdivenler X: 0, Z: -15 ile -39 arası, Y: 0 ile 12 arası)
	var apple_positions = [
		Vector3(7, 2, -18),    # Sağ platform
		Vector3(-7, 4, -22),   # Sol platform
		Vector3(7, 6, -26),    # Sağ platform
		Vector3(-7, 8, -30),   # Sol platform
		Vector3(25, 6, -26)    # ÇOK UZAKTAKİ ELMA (Köprü gerektirir)
	]
	
	for i in range(apple_positions.size()):
		var pos = apple_positions[i]
		var plat = CSGCylinder3D.new()
		plat.radius = 2.0
		plat.height = 0.5
		plat.position = pos - Vector3(0, 1, 0)
		plat.use_collision = true
		plat.material = marble_mat
		env_node.add_child(plat)
		
		var apple_node = Node3D.new()
		apple_node.position = pos
		if apple_mesh_resource:
			var mesh_inst = MeshInstance3D.new()
			mesh_inst.mesh = apple_mesh_resource
			mesh_inst.material_override = a_mat
			mesh_inst.scale = Vector3(0.6, 0.6, 0.6)
			apple_node.add_child(mesh_inst)
		else:
			var fallback_apple = CSGSphere3D.new()
			fallback_apple.radius = 0.3
			fallback_apple.material = a_mat
			apple_node.add_child(fallback_apple)
			
		var a_body = StaticBody3D.new()
		a_body.add_to_group("apple")
		apple_node.add_child(a_body)
		var a_col = CollisionShape3D.new()
		var a_shape = SphereShape3D.new()
		a_shape.radius = 0.6
		a_col.shape = a_shape
		a_body.add_child(a_col)
		env_node.add_child(apple_node)

	# Tahta (Alınacak Obje) Yeşilliklerin yanında
	var plank_pickup = CSGBox3D.new()
	plank_pickup.size = Vector3(0.5, 0.2, 4)
	plank_pickup.position = Vector3(-6, 0.5, -8) # Sol bahçede yerde
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.4, 0.25, 0.1)
	plank_pickup.material = wood_mat
	# Etkileşim için alan
	var plank_body = StaticBody3D.new()
	plank_body.add_to_group("plank_pickup")
	var plank_col = CollisionShape3D.new()
	var p_shape = BoxShape3D.new()
	p_shape.size = plank_pickup.size
	plank_col.shape = p_shape
	plank_body.add_child(plank_col)
	plank_pickup.add_child(plank_body)
	env_node.add_child(plank_pickup)
	
	# Tahtanın koyulacağı görünmez / yarı saydam köprü tetikleyicisi
	var plank_place = CSGBox3D.new()
	plank_place.size = Vector3(18, 0.2, 2)
	# 3. Elma (X=7, Z=-26, Y=6) ile 5. Elma (X=25, Z=-26, Y=6) arasında uzanacak
	plank_place.position = Vector3(16, 5.0, -26) 
	var ghost_mat = StandardMaterial3D.new()
	ghost_mat.albedo_color = Color(1, 1, 1, 0.2) # Yarı saydam
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plank_place.material = ghost_mat
	
	var place_body = StaticBody3D.new()
	place_body.add_to_group("plank_place")
	var place_col = CollisionShape3D.new()
	var p_shape2 = BoxShape3D.new()
	p_shape2.size = plank_place.size
	place_col.shape = p_shape2
	place_body.add_child(place_col)
	plank_place.add_child(place_body)
	env_node.add_child(plank_place)

func _build_garden():
	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.2, 0.6, 0.2)
	grass_mat.roughness = 0.9
	
	# Simetrik çalılar / bitki yatakları (Z: 0'dan kapıya kadar)
	var z_positions = [0, -4, -8, -12, -45, -48, -52]
	var x_offset = 8.0 # Yola daha yakın
	
	for z in z_positions:
		var y_base = 0.0 if z > -15 else 12.5
		
		# Sol ve sağ tarafa çalı ekle
		for x in [-x_offset, x_offset]:
			# Çalı tabanı (Kare saksı veya bitki yatağı)
			var base = CSGBox3D.new()
			base.size = Vector3(3, 0.2, 3)
			base.position = Vector3(x, y_base, z)
			base.material = grass_mat
			env_node.add_child(base)
			
			# Çalının kendisi (Birleşik küreler)
			var bush = CSGSphere3D.new()
			bush.radius = 1.2
			bush.position = Vector3(x, y_base + 0.6, z)
			bush.material = grass_mat
			env_node.add_child(bush)
			
			var bush2 = CSGSphere3D.new()
			bush2.radius = 0.8
			bush2.position = Vector3(x + 1.0, y_base + 0.4, z + 0.5)
			bush2.material = grass_mat
			env_node.add_child(bush2)
			
			var bush3 = CSGSphere3D.new()
			bush3.radius = 0.8
			bush3.position = Vector3(x - 1.0, y_base + 0.4, z - 0.5)
			bush3.material = grass_mat
			env_node.add_child(bush3)

func _build_colonnade(mat: StandardMaterial3D):
	# Zemin ve üst platform etrafında sütunlar
	var z_positions = [0, -5, -10, -42, -47, -52]
	var x_offset = 13.0
	
	for z in z_positions:
		var y_base = 0.0 if z > -15 else 12.5
		for x in [-x_offset, x_offset]:
			_create_column(Vector3(x, y_base, z), mat)
			
func _create_column(pos: Vector3, mat: StandardMaterial3D):
	var col_node = Node3D.new()
	col_node.position = pos
	
	var base = CSGBox3D.new()
	base.size = Vector3(1.5, 0.5, 1.5)
	base.position.y = 0.25
	base.material = mat
	col_node.add_child(base)
	
	var pillar = CSGCylinder3D.new()
	pillar.radius = 0.5
	pillar.height = 8.0
	pillar.position.y = 4.5
	pillar.material = mat
	col_node.add_child(pillar)
	
	var top = CSGBox3D.new()
	top.size = Vector3(1.5, 0.5, 1.5)
	top.position.y = 8.75
	top.material = mat
	col_node.add_child(top)
	
	env_node.add_child(col_node)

func _build_archway(mat: StandardMaterial3D):
	var combiner = CSGCombiner3D.new()
	combiner.name = "Archway"
	combiner.position = Vector3(0, 12.5, -55)
	combiner.use_collision = true
	
	# Ana duvar/blok
	var wall = CSGBox3D.new()
	wall.size = Vector3(14, 16, 2)
	wall.position.y = 8
	wall.material = mat
	combiner.add_child(wall)
	
	# Etkileşim için StaticBody (Raycast'in 'door' olarak algılaması için)
	var door_body = StaticBody3D.new()
	door_body.add_to_group("door")
	wall.add_child(door_body)
	var door_col = CollisionShape3D.new()
	var d_shape = BoxShape3D.new()
	d_shape.size = wall.size
	door_col.shape = d_shape
	door_body.add_child(door_col)
	
	# Kemer boşluğu (çıkarma)
	var hole = CSGBox3D.new()
	hole.size = Vector3(6, 10, 4)
	hole.position.y = 5
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	combiner.add_child(hole)
	
	var arch = CSGCylinder3D.new()
	arch.radius = 3.0
	arch.height = 4.0
	arch.position.y = 10
	arch.rotation.x = deg_to_rad(90)
	arch.operation = CSGShape3D.OPERATION_SUBTRACTION
	combiner.add_child(arch)
	
	env_node.add_child(combiner)
	
	# Kemerin içinden gelen ışık (İlahi ışık)
	var gate_light = OmniLight3D.new()
	gate_light.position = Vector3(0, 18, -58)
	gate_light.light_energy = 8.0
	gate_light.light_size = 5.0
	gate_light.light_color = Color(1.0, 0.95, 0.8)
	gate_light.omni_range = 30.0
	env_node.add_child(gate_light)

func _build_clouds():
	# Alt taraflara ve kenarlara büyük bulut hacimleri (FogVolume)
	var cloud_mat = FogMaterial.new()
	cloud_mat.density = 2.0
	cloud_mat.albedo = Color(1, 1, 1)
	cloud_mat.emission = Color(0.5, 0.5, 0.5)
	
	var cloud_positions = [
		Vector3(-20, -5, -10), Vector3(20, -5, -20),
		Vector3(-30, 2, -30), Vector3(30, 5, -40),
		Vector3(0, -10, -30), Vector3(-15, 8, -60),
		Vector3(15, 8, -60)
	]
	
	for pos in cloud_positions:
		var fog = FogVolume.new()
		fog.position = pos
		fog.size = Vector3(20, 10, 20)
		fog.shape = 1 # Ellipsoid
		fog.material = cloud_mat
		env_node.add_child(fog)

func _build_planets():
	# 5 Farklı gezegen texture'ını yükle
	var planet_textures = []
	for i in range(1, 6):
		var tex = load("res://planet_" + str(i) + ".png")
		if tex:
			planet_textures.append(tex)
			
	if planet_textures.size() == 0: return
	
	var symmetrical_positions = [
		Vector3(0, 250, -800),     # Merkez (Kapının arkasında/üstünde, çok daha geride)
		Vector3(-600, 300, -600),  # Sol Orta (Daha ayrık)
		Vector3(600, 300, -600),   # Sağ Orta (Daha ayrık)
		Vector3(-1000, 400, -350), # En Sol Yüksek (Çok ayrık)
		Vector3(1000, 400, -350)   # En Sağ Yüksek (Çok ayrık)
	]
	
	# Merkez gezegeni normalin 2 katı (140), Sağ Orta olan gezegeni normalin yarısı (25)
	var symmetrical_scales = [140.0, 50.0, 25.0, 40.0, 40.0]
	
	for i in range(5):
		var planet_sprite = Sprite3D.new()
		planet_sprite.texture = planet_textures[i % planet_textures.size()]
		
		# Simetrik ölçeklendirme ve pozisyon
		var scale_factor = symmetrical_scales[i]
		planet_sprite.scale = Vector3(scale_factor, scale_factor, scale_factor)
		planet_sprite.position = symmetrical_positions[i]
		
		planet_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		planet_sprite.transparent = true
		planet_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		planet_sprite.alpha_scissor_threshold = 0.0
		
		env_node.add_child(planet_sprite)

func _setup_inputs():
	for action in ["move_forward", "move_backward", "move_left", "move_right", "jump", "interact", "punch"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var ev_w = InputEventKey.new(); ev_w.physical_keycode = KEY_W; InputMap.action_add_event("move_forward", ev_w)
	var ev_s = InputEventKey.new(); ev_s.physical_keycode = KEY_S; InputMap.action_add_event("move_backward", ev_s)
	var ev_a = InputEventKey.new(); ev_a.physical_keycode = KEY_A; InputMap.action_add_event("move_left", ev_a)
	var ev_d = InputEventKey.new(); ev_d.physical_keycode = KEY_D; InputMap.action_add_event("move_right", ev_d)
	var ev_space = InputEventKey.new(); ev_space.physical_keycode = KEY_SPACE; InputMap.action_add_event("jump", ev_space)
	var ev_e = InputEventKey.new(); ev_e.physical_keycode = KEY_E; InputMap.action_add_event("interact", ev_e)
	var ev_q = InputEventKey.new(); ev_q.physical_keycode = KEY_Q; InputMap.action_add_event("punch", ev_q)

func _build_stage_2():
	var marble_mat = StandardMaterial3D.new()
	var marble_tex = load("res://marble_diffuse.png")
	if marble_tex: marble_mat.albedo_texture = marble_tex
	
	var ceramic_mat = StandardMaterial3D.new()
	var ceramic_tex = load("res://ceramic_diffuse.png")
	if ceramic_tex: ceramic_mat.albedo_texture = ceramic_tex
	
	# Corridor 1 (Z: -60 to -255)
	# Platforming gaps (boşluklar). Let's make blocks of length 20, gap 5
	for z in range(-60, -255, -24):
		var floor_block = CSGBox3D.new()
		floor_block.size = Vector3(6, 1, 19)
		floor_block.position = Vector3(0, 12.0, z - 9.5)
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
	for x in range(5, 100, 24):
		var floor_block = CSGBox3D.new()
		floor_block.size = Vector3(19, 1, 6)
		floor_block.position = Vector3(x + 9.5, 12.0, -255)
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
	snake.name = "Snake"
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
