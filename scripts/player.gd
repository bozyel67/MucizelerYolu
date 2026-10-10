extends CharacterBody3D

@export var speed := 8.0
@export var jump_velocity := 6.0
@export var gravity := 15.0
@export var mouse_sensitivity := 0.002

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var raycast = $Head/Camera3D/RayCast3D
@onready var right_hand = $Head/Camera3D/RightHand
@onready var left_hand = $Head/Camera3D/LeftHand

var r_hand_default_pos = Vector3(0.4, -0.3, -0.6)
var l_hand_default_pos = Vector3(-0.4, -0.3, -0.6)
var hand_bob_timer = 0.0

var is_r_grabbing = false
var is_l_punching = false
var has_sword = false
var has_bow = false
var current_weapon = 0 # 0: sword, 1: bow
var wood_count = 0
var wall_count = 0
var deer_meat = 0
var has_ice_miracle = false
var is_climbing_tree = false
var climb_timer = 0.0

var has_miracle = false


# Phase 1 Vars
var hp = 100
var max_hp = 100
var checkpoint_pos = Vector3.ZERO
var is_crouching = false
var max_fall_y = -9999.0
var is_wall_running = false
var is_frozen = false
var wall_run_timer = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	right_hand.position = r_hand_default_pos
	left_hand.position = l_hand_default_pos
	checkpoint_pos = global_position

func _input(event):

	if event.is_action_pressed("ultimate"):
		if has_miracle:
			var main = get_node_or_null("/root/Main")
			if main and main.apples_collected >= 5:
				main.apples_collected -= 5
				main.ui_apples.text = "Elma: " + str(main.apples_collected)
				# Cast ultimate
				var fb = CharacterBody3D.new()
				fb.set_script(load("res://scripts/fireball.gd"))
				fb.direction = -camera.global_transform.basis.z
				fb.global_position = camera.global_position + fb.direction * 2.0
				var fm = CSGBox3D.new() # fallback if heart obj fails
				fm.size = Vector3(0.5, 0.5, 0.5)
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(1, 0.2, 0)
				mat.emission_enabled = true
				mat.emission = Color(1, 0, 0)
				mat.emission_energy_multiplier = 3.0
				fm.material = mat
				fb.add_child(fm)
				var fc = CollisionShape3D.new()
				fc.shape = BoxShape3D.new()
				fc.shape.size = Vector3(0.5, 0.5, 0.5)
				fb.add_child(fc)
				get_tree().root.add_child(fb)
			else:
				main.queue_dialogue("Yeterli elman yok! (5 elma gerekli)", 2.0)
		else:
			var main = get_node_or_null("/root/Main")
			if main: main.queue_dialogue("Henüz mucize gücüne sahip değilsin.", 2.0)

	if is_frozen and not (event is InputEventMouseMotion): return
	if hp <= 0: return
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
	if event.is_action_pressed("ui_cancel"):
		var main = get_node_or_null("/root/Main")
		if main and main.has_method("toggle_pause"):
			main.toggle_pause()
		else:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if event.is_action_pressed("interact"):
		play_right_hand_animation()
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			var p = collider.get_parent()
			if collider.is_in_group("apple"):
				p.queue_free()
				get_node("/root/Main").collect_apple()
			elif collider.is_in_group("npc"):
				get_node("/root/Main").interact_with_npc()
			elif collider.is_in_group("npc2"):
				get_node("/root/Main").interact_with_npc2()
			elif collider.is_in_group("door3"):
				get_node("/root/Main").interact_with_door3()
				get_node("/root/Main").interact_with_npc()
			elif collider.is_in_group("door"):
				get_node("/root/Main").interact_with_door()
			elif collider.is_in_group("plank_pickup"):
				get_node("/root/Main").pickup_plank(p)
			elif collider.is_in_group("plank_place"):
				get_node("/root/Main").place_plank(p)
			elif collider.is_in_group("chest"):
				get_node("/root/Main").interact_with_chest(p)
			elif collider.is_in_group("door2"):
				get_node("/root/Main").interact_with_door2(p)
				

	if event.is_action_pressed("weapon_next") or event.is_action_pressed("weapon_prev"):
		if has_bow and has_sword:
			current_weapon = 1 if current_weapon == 0 else 0
			get_node("/root/Main").queue_dialogue("Silah: " + ("Ok" if current_weapon == 1 else "Kılıç"), 1.0)

	if event.is_action_pressed("punch"): # Left click
		if wall_count > 0:
			# Place wall
			get_node("/root/Main").place_wall_from_player(global_position + -camera.global_transform.basis.z * 3.0)
			wall_count -= 1
			get_node("/root/Main").queue_dialogue("Duvar yerleştirildi. Kalan: " + str(wall_count), 2.0)
		elif current_weapon == 0: # Sword
			play_left_hand_animation()
			if has_sword and raycast.is_colliding():
				var col = raycast.get_collider()
				if col.is_in_group("snake"):
					var snake = col if col.has_method("take_damage") else col.get_parent()
					if snake and snake.has_method("take_damage"):
						snake.take_damage(50)
						if snake.hp <= 0:
							get_node("/root/Main").queue_dialogue("Yılanı öldürdün!", 2.0)
							get_node("/root/Main").snake_killed()
				elif col.is_in_group("tree"):
					col.get_parent().queue_free()
					wood_count += 1
					get_node("/root/Main").queue_dialogue("Odun elde ettin! (" + str(wood_count) + ")", 2.0)
				elif col.is_in_group("child"):
					col.take_damage(100)
		elif current_weapon == 1: # Bow
			play_left_hand_animation() # reuse anim for bow recoil
			var main = get_node("/root/Main")
			var arrow = CharacterBody3D.new()
			arrow.set_script(load("res://scripts/arrow.gd"))
			arrow.direction = -camera.global_transform.basis.z
			arrow.global_position = camera.global_position + arrow.direction * 1.0
			var am = CSGBox3D.new()
			am.size = Vector3(0.05, 0.05, 0.5)
			arrow.add_child(am)
			var ac = CollisionShape3D.new()
			ac.shape = BoxShape3D.new()
			ac.shape.size = am.size
			arrow.add_child(ac)
			get_tree().root.add_child(arrow)
			
	if event.is_action_pressed("ice_miracle"):
		if has_ice_miracle:
			var main = get_node_or_null("/root/Main")
			if main and main.apples_collected >= 5:
				main.apples_collected -= 5
				main.ui_apples.text = "Elma: " + str(main.apples_collected)
				var ice = CharacterBody3D.new()
				ice.set_script(load("res://scripts/ice_miracle.gd"))
				ice.direction = -camera.global_transform.basis.z
				ice.global_position = camera.global_position + ice.direction * 2.0
				var im = CSGSphere3D.new()
				im.radius = 0.3
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0, 0.8, 1.0, 0.8)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				im.material = mat
				ice.add_child(im)
				var ic = CollisionShape3D.new()
				ic.shape = SphereShape3D.new()
				ic.shape.radius = 0.3
				ice.add_child(ic)
				get_tree().root.add_child(ice)
			else:
				get_node("/root/Main").queue_dialogue("Buz gücü için 5 elma lazım!", 2.0)



func play_right_hand_animation():
	if is_r_grabbing: return
	is_r_grabbing = true
	var tween = create_tween()
	tween.tween_property(right_hand, "position", r_hand_default_pos + Vector3(-0.2, 0.1, -0.4), 0.15)
	tween.tween_property(right_hand, "rotation", Vector3(0, deg_to_rad(45), 0), 0.15)
	tween.tween_property(right_hand, "position", r_hand_default_pos, 0.15)
	tween.tween_property(right_hand, "rotation", Vector3(0, 0, 0), 0.15)
	tween.tween_callback(func(): is_r_grabbing = false)

func play_left_hand_animation():
	if is_l_punching: return
	is_l_punching = true
	var tween = create_tween()
	tween.tween_property(left_hand, "position", l_hand_default_pos + Vector3(0, 0, -0.6), 0.08)
	tween.tween_property(left_hand, "rotation", Vector3(deg_to_rad(30), 0, 0), 0.08)
	tween.tween_property(left_hand, "position", l_hand_default_pos, 0.15)
	tween.tween_property(left_hand, "rotation", Vector3(0, 0, 0), 0.15)
	tween.tween_callback(func(): is_l_punching = false)

func take_damage(amount: int):
	hp -= amount
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("flash_damage"):
		main.flash_damage()
	if hp <= 0:
		die()

func die():
	hp = 100
	global_position = checkpoint_pos
	velocity = Vector3.ZERO
	max_fall_y = -9999.0
	var main = get_node_or_null("/root/Main")
	if main:
		main.queue_dialogue("Öldün! Son kontrolden başlanıyor...", 3.0)

func _physics_process(delta):
	if position.y < -30.0:
		die()
		return

	# Crouch Logic
	if Input.is_action_pressed("crouch"):
		is_crouching = true
		speed = 4.0
		head.position.y = lerpf(head.position.y, -0.5, delta * 10.0)
	else:
		is_crouching = false
		speed = 8.0
		head.position.y = lerpf(head.position.y, 0.0, delta * 10.0)

	# Fall Damage Tracking
	if not is_on_floor():
		if velocity.y < 0 and global_position.y > max_fall_y:
			max_fall_y = global_position.y
	else:
		if max_fall_y != -9999.0:
			var fall_dist = max_fall_y - global_position.y
			if fall_dist > 10.0: # ~3x jump height
				take_damage(20)
			max_fall_y = -9999.0

	# Jump Logic
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if is_crouching:
			velocity.y = jump_velocity * 3.0
		else:
			velocity.y = jump_velocity

	# Walljump Logic
	
	var on_tree = false
	if is_on_wall():
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			if col.get_collider().is_in_group("tree"):
				on_tree = true
				break

	if on_tree and not is_on_floor():
		if Input.is_action_pressed("move_forward"):
			if climb_timer < 1.0:
				climb_timer += delta
				velocity.y = 2.0 # Climb up
			else:
				velocity.y = 0 # Hold
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity * 1.5
			velocity += get_wall_normal() * jump_velocity * 2.0
			get_node("/root/Main").queue_dialogue("Maymun Zıplayışı!", 1.5)
	else:
		climb_timer = 0.0

	var input_dir = Vector2.ZERO
	if not is_frozen:
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_wall() and not is_on_floor() and velocity.y > -2.0:
		if Input.is_action_pressed("move_forward") and not is_wall_running:
			is_wall_running = true
			wall_run_timer = 2.0
			
	if is_wall_running:
		wall_run_timer -= delta
		velocity.y = 0 # walk on wall
		var wall_norm = get_wall_normal()
		var right_dir = head.global_transform.basis.x
		var tilt_dir = 1.0 if wall_norm.dot(right_dir) > 0 else -1.0
		camera.rotation.z = lerpf(camera.rotation.z, deg_to_rad(35 * tilt_dir), delta * 2.0)
		
		if wall_run_timer <= 0.0 or not is_on_wall():
			is_wall_running = false
	else:
		camera.rotation.z = lerpf(camera.rotation.z, 0.0, delta * 2.0)
		if not is_on_floor():
			velocity.y -= gravity * delta

	# Movement
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if is_on_floor() or is_wall_running:
			hand_bob_timer += delta * 10.0
			var bob_y = sin(hand_bob_timer) * 0.05
			var bob_x = cos(hand_bob_timer * 0.5) * 0.02
			if not is_r_grabbing:
				right_hand.position.y = r_hand_default_pos.y + bob_y
				right_hand.position.x = r_hand_default_pos.x + bob_x
			if not is_l_punching:
				left_hand.position.y = l_hand_default_pos.y - bob_y
				left_hand.position.x = l_hand_default_pos.x + bob_x
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		if not is_r_grabbing:
			right_hand.position = right_hand.position.lerp(r_hand_default_pos, delta * 10.0)
		if not is_l_punching:
			left_hand.position = left_hand.position.lerp(l_hand_default_pos, delta * 10.0)
		hand_bob_timer = 0.0

	move_and_slide()

func equip_sword():
	has_sword = true
	var sword = CSGBox3D.new()
	sword.size = Vector3(0.05, 0.05, 1.2)
	sword.position = Vector3(0, 0, -0.6)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 0.8)
	mat.metallic = 0.8
	mat.roughness = 0.2
	sword.material = mat
	left_hand.add_child(sword)
