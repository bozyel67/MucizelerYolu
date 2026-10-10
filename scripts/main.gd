extends Node3D

@onready var ui_dialogue = $CanvasLayer/Control/DialogueLabel
@onready var ui_apples = $CanvasLayer/Control/ApplesLabel
@onready var player = $Player
@onready var env_node = $Environment

var apples_collected = 0
var apples_handed = 0
var has_key = false
var has_plank = false
var total_apples = 4

var snakes_killed = 0
var total_snakes_stage2 = 5
var stage2_npc_spawned = false

func snake_killed():
	snakes_killed += 1
	if snakes_killed == total_snakes_stage2:
		queue_dialogue("Tüm yılanları öldürdüm! Dayıya gitmeliyim.", 4.0)

func interact_with_npc2():
	if snakes_killed < total_snakes_stage2:
		queue_dialogue("Şatodaki " + str(total_snakes_stage2) + " yılanı öldürmelisin.", 3.0)
	else:
		queue_dialogue("Aferin oğul, iyi iş çıkardın, gel yanıma bakalım.", 4.0)
		queue_dialogue("Seni tanrı yarattı, sen ilk insansın. Şimdi Tanrın ile tanışma zamanı.", 5.0)
		queue_dialogue("Şu 500 metre ilerideki merdivene tırman.", 4.0)
		_build_stage_3_ladder()

var dialogue_timer = 0.0
var active_dialogue_queue = []
var is_paused = false
var pause_menu: Control
var damage_overlay: ColorRect
var hp_label: Label

func _ready():
	_setup_ui()
	_build_stage_2()
	_setup_inputs()
	_build_world()
	
	ui_apples.text = "Elma: 0 / 5"
	ui_dialogue.text = ""
	
	_start_intro_sequence()

func _process(delta):
	_process_tawaf()
	_animate_planets(delta)
	if player:
		hp_label.text = "HP: " + str(player.hp)
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
		queue_dialogue("Harika, 4 elmayı da topladım. Dayıya geri döneyim.")
		ui_apples.visible = false

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
		get_node("/root/Main/Player").checkpoint_pos = Vector3(0, 12.5, -55)
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
	var env = get_node_or_null("WorldEnvironment")
	if env:
		var sky_mat = PanoramaSkyMaterial.new()
		sky_mat.panorama = load("res://sky_blue_cloudy.jpg")
		env.environment.sky.sky_material = sky_mat
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
		if i == 4:
			a_body.add_to_group("black_apple")
			a_mat.albedo_color = Color(0.1, 0.1, 0.1)
		else:
			a_body.add_to_group("apple")
			a_mat.albedo_color = Color(0.85, 0.1, 0.1)
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
	cloud_mat.emission = Color(1, 1, 1)
	
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

var planet_sprites = []
var planet_time = 0.0
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
		planet_sprites.append(planet_sprite)

func _setup_inputs():
	if not InputMap.has_action("crouch"):
		InputMap.add_action("crouch")
		var ev_ctrl = InputEventKey.new(); ev_ctrl.physical_keycode = KEY_CTRL; InputMap.action_add_event("crouch", ev_ctrl)
	if not InputMap.has_action("ultimate"):
		InputMap.add_action("ultimate")
		var ev_r = InputEventKey.new(); ev_r.physical_keycode = KEY_R; InputMap.action_add_event("ultimate", ev_r)
	if not InputMap.has_action("ice_miracle"):
		InputMap.add_action("ice_miracle")
		var ev_f = InputEventKey.new(); ev_f.physical_keycode = KEY_F; InputMap.action_add_event("ice_miracle", ev_f)
	if not InputMap.has_action("weapon_next"):
		InputMap.add_action("weapon_next")
		var ev_mb_u = InputEventMouseButton.new(); ev_mb_u.button_index = MOUSE_BUTTON_WHEEL_UP; InputMap.action_add_event("weapon_next", ev_mb_u)
	if not InputMap.has_action("weapon_prev"):
		InputMap.add_action("weapon_prev")
		var ev_mb_d = InputEventMouseButton.new(); ev_mb_d.button_index = MOUSE_BUTTON_WHEEL_DOWN; InputMap.action_add_event("weapon_prev", ev_mb_d)

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
	var snake = CharacterBody3D.new()
	snake.name = "Snake"
	snake.position = Vector3(95, 13.5, -255)
	snake.set_script(load("res://scripts/snake.gd"))
	
	var snake_mesh = CSGCylinder3D.new()
	snake_mesh.radius = 1.0
	snake_mesh.height = 3.0
	var snake_mat = StandardMaterial3D.new()
	snake_mat.albedo_color = Color(0, 0.8, 0)
	snake_mesh.material = snake_mat
	snake.add_child(snake_mesh)
	
	var snake_col = CollisionShape3D.new()
	var snake_shape = CylinderShape3D.new()
	snake_shape.radius = 1.0
	snake_shape.height = 3.0
	snake_col.shape = snake_shape
	snake.add_child(snake_col)
	
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
			
	
	for i in range(total_snakes_stage2):
		var s = CharacterBody3D.new()
		s.position = Vector3(180 + randf_range(-5, 5), 14, -255 + randf_range(-5, 5))
		s.set_script(load("res://scripts/snake.gd"))
		var sm = CSGCylinder3D.new()
		sm.radius = 1.0; sm.height = 3.0
		var s_mat = StandardMaterial3D.new()
		s_mat.albedo_color = Color(0, 0.8, 0)
		sm.material = s_mat
		s.add_child(sm)
		var sc = CollisionShape3D.new()
		var ss = CylinderShape3D.new()
		ss.radius = 1.0; ss.height = 3.0
		sc.shape = ss
		s.add_child(sc)
		env_node.add_child(s)

	# Add Old Man at Castle
	var npc2 = CSGCylinder3D.new()
	npc2.name = "NPC2"
	npc2.radius = 0.5
	npc2.height = 1.9
	npc2.position = Vector3(170, 13.5, -255)
	npc2.use_collision = true
	var npc2_body = StaticBody3D.new()
	npc2_body.add_to_group("npc2")
	npc2.add_child(npc2_body)
	var npc2_col = CollisionShape3D.new()
	var npc2_shape = CylinderShape3D.new()
	npc2_shape.radius = 0.6; npc2_shape.height = 2.0
	npc2_col.shape = npc2_shape
	npc2_body.add_child(npc2_col)
	var npc2_mat = StandardMaterial3D.new()
	npc2_mat.albedo_color = Color(1, 1, 1); npc2_mat.emission_enabled = true
	npc2_mat.emission = Color(1, 1, 1); npc2_mat.emission_energy_multiplier = 0.3
	npc2.material = npc2_mat
	env_node.add_child(npc2)

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

func _setup_ui():
	var canvas = $CanvasLayer
	
	damage_overlay = ColorRect.new()
	damage_overlay.color = Color(1, 0, 0, 0)
	damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(damage_overlay)
	
	hp_label = Label.new()
	hp_label.position = Vector2(20, 80)
	hp_label.add_theme_font_size_override("font_size", 24)
	hp_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	canvas.add_child(hp_label)
	
	pause_menu = Control.new()
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.visible = false
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position -= Vector2(100, 100) # center offset roughly
	pause_menu.add_child(vbox)
	
	var title = Label.new()
	title.text = "DURAKLATILDI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	var btn_resume = Button.new()
	btn_resume.text = "Devam Et"
	btn_resume.pressed.connect(toggle_pause)
	vbox.add_child(btn_resume)
	
	var btn_restart = Button.new()
	btn_restart.text = "Yeniden Başlat"
	btn_restart.pressed.connect(func():
		toggle_pause()
		if player: player.die()
	)
	vbox.add_child(btn_restart)
	
	var btn_quit = Button.new()
	btn_quit.text = "Oyundan Çık"
	btn_quit.pressed.connect(func():
		get_tree().paused = false; get_tree().change_scene_to_file("res://scenes/main_menu.tscn") # or change scene to main menu
	)
	vbox.add_child(btn_quit)
	
	canvas.add_child(pause_menu)

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func flash_damage():
	var tw = create_tween()
	damage_overlay.color = Color(1, 0, 0, 0.5)
	tw.tween_property(damage_overlay, "color", Color(1, 0, 0, 0), 0.5)

# --- PHASE 2 ADDITIONS ---
var intro_texts = ["Ne?", "Ne oluyor?", "Burası neresi?", "Ben kimim?"]
var intro_text_index = 0
var intro_label: Label
var startup_sound_player: AudioStreamPlayer

func _start_intro_sequence():
	player.is_frozen = true
	get_tree().create_timer(6.0).timeout.connect(func(): player.is_frozen = false)
	
	startup_sound_player = AudioStreamPlayer.new()
	startup_sound_player.stream = load("res://startup.wav")
	add_child(startup_sound_player)
	
	intro_label = Label.new()
	intro_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_label.add_theme_font_size_override("font_size", 80)
	intro_label.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_label.visible = false
	$CanvasLayer.add_child(intro_label)
	
	startup_sound_player.play()
	var tw = create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(_play_next_intro_text)

func _play_next_intro_text():
	if intro_text_index >= intro_texts.size():
		player.is_frozen = false
		return
		
	intro_label.text = intro_texts[intro_text_index]
	intro_label.visible = true
	
	# Random position offset
	intro_label.position = Vector2(randf_range(-100, 100), randf_range(-50, 50))
	intro_label.scale = Vector2(0.1, 0.1)
	
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(intro_label, "scale", Vector2(1.5, 1.5), 0.5)
	tw.tween_property(intro_label, "modulate:a", 1.0, 0.2)
	tw.set_parallel(false)
	tw.tween_property(intro_label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		intro_label.visible = false
		intro_text_index += 1
		_play_next_intro_text()
	)

func _animate_planets(delta):
	planet_time += delta * 0.5
	for i in range(planet_sprites.size()):
		var sp = planet_sprites[i]
		# slow floaty movement
		var offset_x = sin(planet_time + i) * 2.0
		var offset_y = cos(planet_time * 0.8 + i) * 1.5
		sp.position.x += offset_x * delta
		sp.position.y += offset_y * delta


func _build_stage_3_ladder():
	var marble_mat = StandardMaterial3D.new()
	var marble_tex = load("res://marble_diffuse.png")
	if marble_tex: marble_mat.albedo_texture = marble_tex
	
	# The ladder is 500m ahead (X = 180, Z = -755) and goes 500m high.
	for i in range(250):
		var step = CSGBox3D.new()
		step.size = Vector3(10, 1, 3)
		step.position = Vector3(180, 15 + (i * 2.0), -265 - (i * 2.0))
		step.use_collision = true
		step.material = marble_mat
		env_node.add_child(step)
		
	# Door at the top
	var top_plat = CSGBox3D.new()
	top_plat.size = Vector3(20, 1, 20)
	top_plat.position = Vector3(180, 515, -775)
	top_plat.use_collision = true
	top_plat.material = marble_mat
	env_node.add_child(top_plat)
	
	var door3 = CSGBox3D.new()
	door3.name = "Door3"
	door3.size = Vector3(6, 10, 1)
	door3.position = Vector3(180, 520, -780)
	var door_mat = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.8, 0.8, 0.2)
	door3.material = door_mat
	
	var d3_body = StaticBody3D.new()
	d3_body.add_to_group("door3")
	var d3_col = CollisionShape3D.new()
	var d3_shape = BoxShape3D.new()
	d3_shape.size = door3.size
	d3_col.shape = d3_shape
	d3_body.add_child(d3_col)
	door3.add_child(d3_body)
	env_node.add_child(door3)

func interact_with_door3():
	queue_dialogue("3. Bölüme geçiliyor (Tanrı ve Şeytan)...", 4.0)
	player.checkpoint_pos = Vector3(180, 516, -775)
	_build_stage_3()
	var tw = create_tween()
	var door3 = env_node.get_node_or_null("Door3")
	if door3:
		tw.tween_property(door3, "position:y", door3.position.y + 10, 3.0)

func _build_stage_3():
	# Pink dust clouds area
	var ceramic_mat = StandardMaterial3D.new()
	var ceramic_tex = load("res://ceramic_diffuse.png")
	if ceramic_tex: ceramic_mat.albedo_texture = ceramic_tex
	
	var ground = CSGBox3D.new()
	ground.size = Vector3(100, 1, 100)
	ground.position = Vector3(180, 515, -830)
	ground.use_collision = true
	ground.material = ceramic_mat
	env_node.add_child(ground)
	
	# Pink Fog
	var cloud_mat = FogMaterial.new()
	cloud_mat.density = 3.0
	cloud_mat.albedo = Color(1, 0.6, 0.8)
	cloud_mat.emission = Color(0.8, 0.3, 0.5)
	for i in range(8):
		var fog = FogVolume.new()
		fog.position = Vector3(180 + randf_range(-30, 30), 520 + randf_range(0, 20), -830 + randf_range(-30, 30))
		fog.size = Vector3(40, 20, 40)
		fog.shape = 1
		fog.material = cloud_mat
		env_node.add_child(fog)
		
	# Sparkles/Particles (Using simple small meshes)
	for i in range(50):
		var sp = CSGSphere3D.new()
		sp.radius = 0.2
		sp.position = Vector3(180 + randf_range(-40, 40), 516 + randf_range(0, 10), -830 + randf_range(-40, 40))
		var smat = StandardMaterial3D.new()
		smat.albedo_color = Color(1, 1, 0.5)
		smat.emission_enabled = true
		smat.emission = Color(1, 1, 0)
		smat.emission_energy_multiplier = 5.0
		sp.material = smat
		env_node.add_child(sp)

	# Trigger Cutscene
	queue_dialogue("Şeytan: İnsan mı? Ama o sadece çamur. Beni ateşten yarattın ben daha üstünüm.", 6.0)
	queue_dialogue("Tanrı: Bana karşı mı geliyorsun?", 4.0)
	queue_dialogue("Şeytan: Hey İnsan, gel senle kapışalım senin gücünü test edeyim.", 5.0)
	queue_dialogue("İhtiyar Dayı: Henüz hazır değilsin. 2. Şatodan mucize gücünü almalısın.", 5.0)
	_build_stage_4_door()


func _build_stage_4_door():
	var door4 = CSGBox3D.new()
	door4.name = "Door4"
	door4.size = Vector3(10, 15, 1)
	door4.position = Vector3(250, 522.5, -830)
	var door_mat = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0, 0, 0) # Black/Space
	door4.material = door_mat
	
	var d4_body = StaticBody3D.new()
	d4_body.add_to_group("door4")
	var d4_col = CollisionShape3D.new()
	var d4_shape = BoxShape3D.new()
	d4_shape.size = door4.size
	d4_col.shape = d4_shape
	d4_body.add_child(d4_col)
	door4.add_child(d4_body)
	env_node.add_child(door4)

func interact_with_door4():
	queue_dialogue("4. Bölüme geçiliyor (Modern Şato)...", 4.0)
	player.checkpoint_pos = Vector3(250, 516, -840)
	_build_stage_4()
	var door4 = env_node.get_node_or_null("Door4")
	if door4: door4.queue_free()

func _build_stage_4():
	var marble_mat = StandardMaterial3D.new()
	var marble_tex = load("res://marble_diffuse.png")
	if marble_tex: marble_mat.albedo_texture = marble_tex
	
	# Castle (300sqm -> ~17x17), 3 floors
	var castle = CSGCombiner3D.new()
	castle.position = Vector3(250, 515, -880)
	castle.use_collision = true
	
	for i in range(3):
		var floor_y = i * 6.0
		var level = CSGBox3D.new()
		level.size = Vector3(17, 6, 17)
		level.position.y = floor_y + 3.0
		# Hollow inside
		var hole = CSGBox3D.new()
		hole.size = Vector3(16, 5, 16)
		hole.position.y = floor_y + 3.0
		hole.operation = CSGShape3D.OPERATION_SUBTRACTION
		castle.add_child(level)
		castle.add_child(hole)
		
		# Stairs to next floor
		if i < 2:
			var stairs = CSGBox3D.new()
			stairs.size = Vector3(3, 6, 8)
			stairs.position = Vector3(6, floor_y + 3.0, 4)
			stairs.rotation.x = deg_to_rad(45)
			castle.add_child(stairs)
			
	env_node.add_child(castle)
	
	# Chest at 3rd floor
	var chest = CSGBox3D.new()
	chest.size = Vector3(2, 1.5, 1.5)
	chest.position = Vector3(250, 515 + 12.0 + 0.75, -880)
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.3, 0.15, 0.05)
	chest.material = wood_mat
	
	var chest_body = StaticBody3D.new()
	chest_body.add_to_group("chest_miracle")
	var chest_col = CollisionShape3D.new()
	var chest_shape = BoxShape3D.new()
	chest_shape.size = chest.size
	chest_col.shape = chest_shape
	chest_body.add_child(chest_col)
	chest.add_child(chest_body)
	env_node.add_child(chest)
	
	# Spawn apples inside castle
	var apple_mesh_resource = load("res://apple.obj")
	var a_mat = StandardMaterial3D.new()
	a_mat.albedo_color = Color(0.85, 0.1, 0.1)
	
	for i in range(10):
		var pos = Vector3(250 + randf_range(-7, 7), 515 + (randi() % 3) * 6.0 + 1.0, -880 + randf_range(-7, 7))
		var a = Node3D.new()
		a.position = pos
		var fallback = CSGSphere3D.new()
		fallback.radius = 0.3
		fallback.material = a_mat
		a.add_child(fallback)
		var b = StaticBody3D.new()
		b.add_to_group("apple")
		var c = CollisionShape3D.new()
		c.shape = SphereShape3D.new()
		c.shape.radius = 0.6
		b.add_child(c)
		a.add_child(b)
		env_node.add_child(a)

func interact_with_chest_miracle(chest_node):
	chest_node.queue_free()
	queue_dialogue("Mucize Gücünü aldın! (Ateş Topu - R tuşu)", 4.0)
	player.has_miracle = true
	
	# Flash screen
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 1)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	$CanvasLayer.add_child(flash)
	var tw = create_tween()
	tw.tween_property(flash, "color", Color(1, 1, 1, 0), 2.0)
	tw.tween_callback(flash.queue_free)
	
	queue_dialogue("Şeytan: Hey insan sana meydan okuyorum. Gel dövüşelim!", 4.0)
	queue_dialogue("Şeytanın alemine gitmek için kapıya (E) tıkla.", 4.0)
	_build_boss_portal()

func _build_boss_portal():
	var p = CSGBox3D.new()
	p.size = Vector3(5, 5, 1)
	p.position = Vector3(250, 515 + 1.0 + 2.5, -870) # outside castle
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0)
	p.material = mat
	var body = StaticBody3D.new()
	body.add_to_group("boss_portal")
	p.add_child(body)
	var col = CollisionShape3D.new()
	var s = BoxShape3D.new()
	s.size = p.size
	col.shape = s
	body.add_child(col)
	env_node.add_child(p)

func interact_with_boss_portal():
	queue_dialogue("Boss Arena Yükleniyor...", 3.0)
	player.checkpoint_pos = Vector3(250, 1000, -880)
	player.global_position = player.checkpoint_pos
	_build_boss_arena()

func _build_boss_arena():
	var g = CSGBox3D.new()
	g.size = Vector3(500, 1, 500)
	g.position = Vector3(250, 999, -880)
	g.use_collision = true
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	g.material = mat
	env_node.add_child(g)
	
	# Boss
	var boss = CharacterBody3D.new()
	boss.set_script(load("res://scripts/boss.gd"))
	boss.position = Vector3(250, 1000, -1180) # 300m away
	var bmesh = CSGBox3D.new()
	bmesh.size = Vector3(50, 50, 50)
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(1, 0, 0)
	bmesh.material = bmat
	boss.add_child(bmesh)
	var bc = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(50, 50, 50)
	bc.shape = bs
	boss.add_child(bc)
	env_node.add_child(boss)
	boss.activate()

func spawn_boss_snake(pos):
	var s = CharacterBody3D.new()
	s.set_script(load("res://scripts/snake.gd"))
	s.position = pos
	var sm = CSGCylinder3D.new()
	sm.radius = 1.0; sm.height = 3.0
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0, 0.8, 0)
	sm.material = smat
	s.add_child(sm)
	var sc = CollisionShape3D.new()
	var ss = CylinderShape3D.new()
	ss.radius = 1.0; ss.height = 3.0
	sc.shape = ss
	s.add_child(sc)
	env_node.add_child(s)

func spawn_boss_fireball(pos):
	pass

func _build_woman():
	var woman = CSGCylinder3D.new(); woman.name = "Woman"
	woman.radius = 0.4
	woman.height = 1.7
	woman.position = Vector3(250, 1000, -900)
	woman.use_collision = true
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.8, 0.8)
	woman.material = mat
	
	var b = StaticBody3D.new()
	b.add_to_group("woman")
	var c = CollisionShape3D.new()
	c.shape = CylinderShape3D.new()
	c.shape.radius = 0.5
	c.shape.height = 1.8
	b.add_child(c)
	woman.add_child(b)
	env_node.add_child(woman)

var woman_state = 0 # 0: Needs apple, 1: Needs black apple, 2: Needs wood

func interact_with_woman():
	if woman_state == 0:
		if apples_collected > 0:
			apples_collected -= 1
			ui_apples.text = "Elma: " + str(apples_collected)
			queue_dialogue("Kadın: Aa çok güzelmiş, sonsuza kadar burada kalalım.", 4.0)
			queue_dialogue("Şeytan: İnsan sandığımdan daha eşref-i mahlukmuş...", 4.0)
			queue_dialogue("Şeytan(Yılan): Sonsuza kadar kalmak için sonsuzluk elmasını(siyah elma) ye.", 5.0)
			queue_dialogue("Kadın: Hadi bana o elmayı getir lütfen.", 3.0)
			woman_state = 1
			player.checkpoint_pos = Vector3(250, 1000, -900)
		else:
			queue_dialogue("Kadın: Buralar güzelmiş. Ama çok acıktım bana 1 elma bulabilir misin?", 5.0)
	elif woman_state == 1:
		if has_black_apple:
			queue_dialogue("Kadın: Teşekkürler!", 2.0)
			queue_dialogue("Tanrı: YASAK ELMAYI YEDİNİZ! SÜRGÜN EDİLİYORSUNUZ!", 5.0)
			_build_earth()
		else:
			queue_dialogue("Kadın: Hala siyah elmayı bekliyorum...", 3.0)
	elif woman_state == 2:
		if player.wood_count >= 3:
			player.wood_count -= 3
			player.wall_count += 1
			queue_dialogue("Kadın: 3 odundan 1 Kabe Duvarı ürettim! (Kalan duvarı sol tık ile yerleştir)", 4.0)
		else:
			queue_dialogue("Kadın: Lütfen kılıcınla ağaç kesip bana odun getir. (En az 3 odun lazım)", 4.0)
			queue_dialogue("Burada boş bir alan var, Kabe'yi etrafıma 3x3 olacak şekilde kur.", 4.0)
	elif woman_state == 4:
		if player.deer_meat >= 3:
			queue_dialogue("Kadın: Harika! 3 geyik getirdin.", 3.0)
			queue_dialogue("Kadın: Yeni nesiller üretmek için Kabe'nin etrafında saat yönünün tersine 7 kez dönmelisin.", 5.0)
			woman_state = 5
			tawaf_count = 0
			last_tawaf_angle = atan2(player.global_position.z - kabe_center.z, player.global_position.x - kabe_center.x)
		else:
			queue_dialogue("Kadın: 3 geyik avlamanı bekliyorum.", 3.0)
	elif woman_state == 6:
		var dist_to_kabe = player.global_position.distance_to(kabe_center)
		if dist_to_kabe < 3.0:
			queue_dialogue("Çocuklar doğdu!", 3.0)
			woman_state = 7
			_spawn_children()
		else:
			queue_dialogue("Kabe'nin içine gir!", 2.0)
	elif woman_state == 7:
		if children_sacrificed >= 1:
			queue_dialogue("Kadın: Kalan 4 çocuk için 2 yeni ev (duvar) inşa etmeliyiz.", 4.0)
			queue_dialogue("Yine odun topla ve bana getir.", 3.0)
			total_houses_needed = 2
			walls_placed = 0
			woman_state = 8
		else:
			queue_dialogue("Kadın: Tanrıya bir çocuğu kurban etmelisin.", 3.0)
	elif woman_state == 8:
		if player.wood_count >= 3:
			player.wood_count -= 3
			player.wall_count += 1
			queue_dialogue("Kadın: 1 Duvar ürettim! Evleri inşa et.", 3.0)
		else:
			queue_dialogue("Kadın: Evler için odun lazım.", 3.0)

func _spawn_children():
	for i in range(5):
		var c = CharacterBody3D.new()
		c.set_script(load("res://scripts/child.gd"))
		c.position = kabe_center + Vector3(randf_range(-1,1), 0.5, randf_range(-1,1))
		var cm = CSGSphere3D.new(); cm.radius = 0.4
		var mat = StandardMaterial3D.new(); mat.albedo_color = Color(1, 0.8, 0.8)
		cm.material = mat; c.add_child(cm)
		var cc = CollisionShape3D.new(); cc.shape = SphereShape3D.new(); cc.shape.radius = 0.4
		c.add_child(cc)
		var body = StaticBody3D.new(); body.add_to_group("child")
		var bcol = CollisionShape3D.new(); bcol.shape = SphereShape3D.new(); bcol.shape.radius = 0.5
		body.add_child(bcol); c.add_child(body)
		env_node.add_child(c)

func child_sacrificed():
	children_sacrificed += 1
	queue_dialogue("Çocuğu Tanrı'ya kurban ettin!", 3.0)

func child_placed():
	children_placed += 1

func _end_game():
	var end_bg = ColorRect.new()
	end_bg.color = Color(1, 1, 1, 0)
	end_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	$CanvasLayer.add_child(end_bg)
	
	var label1 = Label.new(); label1.text = "TANRI MEMNUN OLDU"
	label1.set_anchors_preset(Control.PRESET_CENTER)
	label1.position.y -= 50
	label1.add_theme_font_size_override("font_size", 64)
	label1.add_theme_color_override("font_color", Color(0,0,0,1))
	label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_bg.add_child(label1)
	
	var label2 = Label.new(); label2.text = "ÇAĞ ATLADIN"
	label2.set_anchors_preset(Control.PRESET_CENTER)
	label2.position.y += 50
	label2.add_theme_font_size_override("font_size", 64)
	label2.add_theme_color_override("font_color", Color(0,0,0,1))
	label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_bg.add_child(label2)
	
	var tw = create_tween()
	tw.tween_property(end_bg, "color", Color(1, 1, 1, 1), 3.0)
	tw.tween_callback(func(): get_tree().paused = true)

func _build_earth():
	player.checkpoint_pos = Vector3(500, 0, -2000)
	player.global_position = player.checkpoint_pos
	woman_state = 2
	
	# Earth environment
	var g = CSGBox3D.new()
	g.size = Vector3(200, 1, 200)
	g.position = Vector3(500, -0.5, -2000)
	g.use_collision = true
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.1) # Grass
	g.material = mat
	env_node.add_child(g)
	
	# Trees
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.4, 0.2, 0) # Trunk
	var l_mat = StandardMaterial3D.new()
	l_mat.albedo_color = Color(0, 0.5, 0) # Leaves
	
	for i in range(20):
		var tree = StaticBody3D.new()
		tree.add_to_group("tree")
		tree.position = Vector3(500 + randf_range(-80, 80), 0, -2000 + randf_range(-80, 80))
		
		var trunk = CSGCylinder3D.new()
		trunk.radius = 0.5; trunk.height = 5.0; trunk.position.y = 2.5
		trunk.material = t_mat; tree.add_child(trunk)
		var leaves = CSGSphere3D.new()
		leaves.radius = 2.5; leaves.position.y = 6.0
		leaves.material = l_mat; tree.add_child(leaves)
		var col = CollisionShape3D.new()
		var cs = CylinderShape3D.new(); cs.radius = 0.5; cs.height = 5.0
		col.shape = cs; col.position.y = 2.5; tree.add_child(col)
		
		# Add apple at top
		var a = Node3D.new()
		a.position.y = 8.5
		var fb = CSGSphere3D.new(); fb.radius = 0.3
		var am = StandardMaterial3D.new(); am.albedo_color = Color(0.85, 0.1, 0.1)
		fb.material = am; a.add_child(fb)
		var b = StaticBody3D.new(); b.add_to_group("apple")
		var c = CollisionShape3D.new(); c.shape = SphereShape3D.new(); c.shape.radius = 0.6
		b.add_child(c); a.add_child(b); tree.add_child(a)
		
		env_node.add_child(tree)
		
	# Move woman to Earth
	var woman = env_node.get_node_or_null("Woman")
	if woman:
		woman.position = Vector3(505, 0, -2005)


func boss_defeated():
	queue_dialogue("Boss öldü! Tanrı ortaya çıkıyor...", 4.0)
	queue_dialogue("Tanrı: Aferin insan, ödül olarak kadını hak ettin.", 4.0)
	_build_woman()

func _build_woman():

func _build_woman():
	var woman = CSGCylinder3D.new(); woman.name = "Woman"
	woman.radius = 0.4
	woman.height = 1.7
	woman.position = Vector3(250, 1000, -900)
	woman.use_collision = true
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.8, 0.8)
	woman.material = mat
	
	var b = StaticBody3D.new()
	b.add_to_group("woman")
	var c = CollisionShape3D.new()
	c.shape = CylinderShape3D.new()
	c.shape.radius = 0.5
	c.shape.height = 1.8
	b.add_child(c)
	woman.add_child(b)
	env_node.add_child(woman)

var woman_state = 0 # 0: Needs apple, 1: Needs black apple, 2: Needs wood

func interact_with_woman():
	if woman_state == 0:
		if apples_collected > 0:
			apples_collected -= 1
			ui_apples.text = "Elma: " + str(apples_collected)
			queue_dialogue("Kadın: Aa çok güzelmiş, sonsuza kadar burada kalalım.", 4.0)
			queue_dialogue("Şeytan: İnsan sandığımdan daha eşref-i mahlukmuş...", 4.0)
			queue_dialogue("Şeytan(Yılan): Sonsuza kadar kalmak için sonsuzluk elmasını(siyah elma) ye.", 5.0)
			queue_dialogue("Kadın: Hadi bana o elmayı getir lütfen.", 3.0)
			woman_state = 1
			player.checkpoint_pos = Vector3(250, 1000, -900)
		else:
			queue_dialogue("Kadın: Buralar güzelmiş. Ama çok acıktım bana 1 elma bulabilir misin?", 5.0)
	elif woman_state == 1:
		if has_black_apple:
			queue_dialogue("Kadın: Teşekkürler!", 2.0)
			queue_dialogue("Tanrı: YASAK ELMAYI YEDİNİZ! SÜRGÜN EDİLİYORSUNUZ!", 5.0)
			_build_earth()
		else:
			queue_dialogue("Kadın: Hala siyah elmayı bekliyorum...", 3.0)
	elif woman_state == 2:
		if player.wood_count >= 3:
			player.wood_count -= 3
			player.wall_count += 1
			queue_dialogue("Kadın: 3 odundan 1 Kabe Duvarı ürettim! (Kalan duvarı sol tık ile yerleştir)", 4.0)
		else:
			queue_dialogue("Kadın: Lütfen kılıcınla ağaç kesip bana odun getir. (En az 3 odun lazım)", 4.0)
			queue_dialogue("Burada boş bir alan var, Kabe'yi etrafıma 3x3 olacak şekilde kur.", 4.0)
	elif woman_state == 4:
		if player.deer_meat >= 3:
			queue_dialogue("Kadın: Harika! 3 geyik getirdin.", 3.0)
			queue_dialogue("Kadın: Yeni nesiller üretmek için Kabe'nin etrafında saat yönünün tersine 7 kez dönmelisin.", 5.0)
			woman_state = 5
			tawaf_count = 0
			last_tawaf_angle = atan2(player.global_position.z - kabe_center.z, player.global_position.x - kabe_center.x)
		else:
			queue_dialogue("Kadın: 3 geyik avlamanı bekliyorum.", 3.0)
	elif woman_state == 6:
		var dist_to_kabe = player.global_position.distance_to(kabe_center)
		if dist_to_kabe < 3.0:
			queue_dialogue("Çocuklar doğdu!", 3.0)
			woman_state = 7
			_spawn_children()
		else:
			queue_dialogue("Kabe'nin içine gir!", 2.0)
	elif woman_state == 7:
		if children_sacrificed >= 1:
			queue_dialogue("Kadın: Kalan 4 çocuk için 2 yeni ev (duvar) inşa etmeliyiz.", 4.0)
			queue_dialogue("Yine odun topla ve bana getir.", 3.0)
			total_houses_needed = 2
			walls_placed = 0
			woman_state = 8
		else:
			queue_dialogue("Kadın: Tanrıya bir çocuğu kurban etmelisin.", 3.0)
	elif woman_state == 8:
		if player.wood_count >= 3:
			player.wood_count -= 3
			player.wall_count += 1
			queue_dialogue("Kadın: 1 Duvar ürettim! Evleri inşa et.", 3.0)
		else:
			queue_dialogue("Kadın: Evler için odun lazım.", 3.0)

func _spawn_children():
	for i in range(5):
		var c = CharacterBody3D.new()
		c.set_script(load("res://scripts/child.gd"))
		c.position = kabe_center + Vector3(randf_range(-1,1), 0.5, randf_range(-1,1))
		var cm = CSGSphere3D.new(); cm.radius = 0.4
		var mat = StandardMaterial3D.new(); mat.albedo_color = Color(1, 0.8, 0.8)
		cm.material = mat; c.add_child(cm)
		var cc = CollisionShape3D.new(); cc.shape = SphereShape3D.new(); cc.shape.radius = 0.4
		c.add_child(cc)
		var body = StaticBody3D.new(); body.add_to_group("child")
		var bcol = CollisionShape3D.new(); bcol.shape = SphereShape3D.new(); bcol.shape.radius = 0.5
		body.add_child(bcol); c.add_child(body)
		env_node.add_child(c)

func child_sacrificed():
	children_sacrificed += 1
	queue_dialogue("Çocuğu Tanrı'ya kurban ettin!", 3.0)

func child_placed():
	children_placed += 1

func _end_game():
	var end_bg = ColorRect.new()
	end_bg.color = Color(1, 1, 1, 0)
	end_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	$CanvasLayer.add_child(end_bg)
	
	var label1 = Label.new(); label1.text = "TANRI MEMNUN OLDU"
	label1.set_anchors_preset(Control.PRESET_CENTER)
	label1.position.y -= 50
	label1.add_theme_font_size_override("font_size", 64)
	label1.add_theme_color_override("font_color", Color(0,0,0,1))
	label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_bg.add_child(label1)
	
	var label2 = Label.new(); label2.text = "ÇAĞ ATLADIN"
	label2.set_anchors_preset(Control.PRESET_CENTER)
	label2.position.y += 50
	label2.add_theme_font_size_override("font_size", 64)
	label2.add_theme_color_override("font_color", Color(0,0,0,1))
	label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_bg.add_child(label2)
	
	var tw = create_tween()
	tw.tween_property(end_bg, "color", Color(1, 1, 1, 1), 3.0)
	tw.tween_callback(func(): get_tree().paused = true)

func _build_earth():
	player.checkpoint_pos = Vector3(500, 0, -2000)
	player.global_position = player.checkpoint_pos
	woman_state = 2
	
	# Earth environment
	var g = CSGBox3D.new()
	g.size = Vector3(200, 1, 200)
	g.position = Vector3(500, -0.5, -2000)
	g.use_collision = true
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.1) # Grass
	g.material = mat
	env_node.add_child(g)
	
	# Trees
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.4, 0.2, 0) # Trunk
	var l_mat = StandardMaterial3D.new()
	l_mat.albedo_color = Color(0, 0.5, 0) # Leaves
	
	for i in range(20):
		var tree = StaticBody3D.new()
		tree.add_to_group("tree")
		tree.position = Vector3(500 + randf_range(-80, 80), 0, -2000 + randf_range(-80, 80))
		
		var trunk = CSGCylinder3D.new()
		trunk.radius = 0.5; trunk.height = 5.0; trunk.position.y = 2.5
		trunk.material = t_mat; tree.add_child(trunk)
		var leaves = CSGSphere3D.new()
		leaves.radius = 2.5; leaves.position.y = 6.0
		leaves.material = l_mat; tree.add_child(leaves)
		var col = CollisionShape3D.new()
		var cs = CylinderShape3D.new(); cs.radius = 0.5; cs.height = 5.0
		col.shape = cs; col.position.y = 2.5; tree.add_child(col)
		
		# Add apple at top
		var a = Node3D.new()
		a.position.y = 8.5
		var fb = CSGSphere3D.new(); fb.radius = 0.3
		var am = StandardMaterial3D.new(); am.albedo_color = Color(0.85, 0.1, 0.1)
		fb.material = am; a.add_child(fb)
		var b = StaticBody3D.new(); b.add_to_group("apple")
		var c = CollisionShape3D.new(); c.shape = SphereShape3D.new(); c.shape.radius = 0.6
		b.add_child(c); a.add_child(b); tree.add_child(a)
		
		env_node.add_child(tree)
		
	# Move woman to Earth
	var woman = env_node.get_node_or_null("Woman")
	if woman:
		woman.position = Vector3(505, 0, -2005)



var walls_placed = 0
var total_houses_needed = 0
var kabe_center = Vector3(500, 0, -2005)
var tawaf_angle = 0.0
var tawaf_count = 0
var last_tawaf_angle = 0.0
var children_sacrificed = 0
var children_placed = 0

func place_wall_from_player(pos: Vector3):
	var wall = CSGBox3D.new()
	wall.size = Vector3(3, 3, 0.2)
	wall.position = pos
	wall.position.y = 1.5
	# Black with gold stripe
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.1)
	wall.material = mat
	# Gold stripe (simple child box)
	var stripe = CSGBox3D.new()
	stripe.size = Vector3(3.05, 0.2, 0.25)
	stripe.position.y = 0.5
	var gmat = StandardMaterial3D.new()
	gmat.albedo_color = Color(0.8, 0.7, 0.2)
	stripe.material = gmat
	wall.add_child(stripe)
	
	var body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = wall.size
	col.shape = shape
	body.add_child(col)
	wall.add_child(body)
	env_node.add_child(wall)
	
	if woman_state == 2:
		walls_placed += 1
		if walls_placed >= 4:
			queue_dialogue("KABE duvarları tamamlandı!", 4.0)
			queue_dialogue("İhtiyar Dayı: Ormanda saklı bir sandık var, içinde Buz mucizesi var.", 5.0)
			_spawn_ice_chest()
	elif woman_state == 6: # Building regular houses
		walls_placed += 1
		if walls_placed >= 4:
			total_houses_needed -= 1
			walls_placed = 0
			queue_dialogue("Bir ev tamamlandı!", 3.0)
			if total_houses_needed <= 0:
				queue_dialogue("Tüm evler tamamlandı! (Oyun Sonu)", 5.0)
				_end_game()

func _spawn_ice_chest():
	woman_state = 3
	var chest = CSGBox3D.new()
	chest.size = Vector3(2, 1.5, 1.5)
	chest.position = Vector3(500 + randf_range(-30, 30), 0.75, -2000 + randf_range(-30, 30))
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.3, 0.15, 0.05)
	chest.material = wood_mat
	var body = StaticBody3D.new()
	body.add_to_group("chest_ice")
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = chest.size
	body.add_child(col)
	chest.add_child(body)
	env_node.add_child(chest)
	
	# Add trigger for Kabe Roof
	var r = CSGBox3D.new()
	r.size = Vector3(5, 5, 5)
	r.position = kabe_center + Vector3(0, 3, 0)
	var rmat = StandardMaterial3D.new()
	rmat.albedo_color = Color(0,0,1,0.2); rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r.material = rmat
	var rbody = StaticBody3D.new()
	rbody.add_to_group("kabe_build_area")
	var rcol = CollisionShape3D.new()
	rcol.shape = BoxShape3D.new(); rcol.shape.size = r.size
	rbody.add_child(rcol); r.add_child(rbody); env_node.add_child(r)

func build_kabe_roof():
	queue_dialogue("Buzdan tavan oluştu!", 3.0)
	var roof = CSGBox3D.new()
	roof.size = Vector3(3.2, 0.2, 3.2)
	roof.position = kabe_center + Vector3(0, 3.1, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.8, 1.0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	roof.material = mat
	env_node.add_child(roof)
	
	queue_dialogue("Kadın: Kabe çok güzel oldu! Şimdi senden geyik avlamanı istiyorum (3 adet).", 5.0)
	queue_dialogue("İhtiyar Dayı: Ok ve yay için yeni sandığı bul.", 4.0)
	woman_state = 4
	_spawn_bow_chest()

func _spawn_bow_chest():
	var chest = CSGBox3D.new()
	chest.size = Vector3(2, 1.5, 1.5)
	chest.position = Vector3(500 + randf_range(-30, 30), 0.75, -2000 + randf_range(-30, 30))
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.3, 0.15, 0.05)
	chest.material = wood_mat
	var body = StaticBody3D.new()
	body.add_to_group("chest_bow")
	var col = CollisionShape3D.new(); col.shape = BoxShape3D.new(); col.shape.size = chest.size
	body.add_child(col); chest.add_child(body); env_node.add_child(chest)
	
	# Spawn 3 Deer
	for i in range(3):
		var d = CharacterBody3D.new()
		d.set_script(load("res://scripts/deer.gd"))
		d.position = Vector3(500 + randf_range(-50, 50), 1.0, -2000 + randf_range(-50, 50))
		var dm = CSGBox3D.new(); dm.size = Vector3(1, 1.5, 2)
		var dmat = StandardMaterial3D.new(); dmat.albedo_color = Color(0.5, 0.3, 0.1)
		dm.material = dmat; d.add_child(dm)
		var dc = CollisionShape3D.new(); dc.shape = BoxShape3D.new(); dc.shape.size = dm.size
		d.add_child(dc)
		
		# Head (Hurtbox)
		var head = CSGBox3D.new(); head.size = Vector3(0.5, 0.5, 0.5); head.position = Vector3(0, 1.0, 1.0)
		head.material = dmat; d.add_child(head)
		var hb = StaticBody3D.new(); hb.add_to_group("deer_head"); hb.position = head.position
		var hc = CollisionShape3D.new(); hc.shape = BoxShape3D.new(); hc.shape.size = head.size
		hb.add_child(hc); d.add_child(hb)
		
		env_node.add_child(d)

func deer_killed(deer):
	queue_dialogue("Geyik öldü! E ile topla.", 2.0)
	var body = StaticBody3D.new(); body.add_to_group("dead_deer")
	var col = CollisionShape3D.new(); col.shape = BoxShape3D.new(); col.shape.size = Vector3(2,2,2)
	body.add_child(col); deer.add_child(body)

func _process_tawaf():
	if woman_state == 5:
		var curr_angle = atan2(player.global_position.z - kabe_center.z, player.global_position.x - kabe_center.x)
		var diff = curr_angle - last_tawaf_angle
		
		if diff > PI: diff -= 2*PI
		if diff < -PI: diff += 2*PI
		
		# Counter-clockwise means diff is positive (or negative depending on Godot axis, Godot Z is forward so let's just accumulate absolute diff)
		# Actually, CCW in X-Z top-down where +X is right, +Z is down.
		if diff < 0: # Let's accept any circle direction or strict CCW
			tawaf_angle += abs(diff)
			
		last_tawaf_angle = curr_angle
		
		if tawaf_angle >= 2 * PI:
			tawaf_angle = 0.0
			tawaf_count += 1
			queue_dialogue("Tavaf: " + str(tawaf_count) + "/7", 2.0)
			if tawaf_count >= 7:
				queue_dialogue("Kadın: Görev tamamlandı! Kabe'ye gir.", 4.0)
				woman_state = 6 # Ready to reproduce
