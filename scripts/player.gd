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
var is_falling_to_void = false
var fall_timer = 0.0
var has_sword = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	right_hand.position = r_hand_default_pos
	left_hand.position = l_hand_default_pos

func _input(event):
	if is_falling_to_void: return
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if event.is_action_pressed("interact"): # E Tuşu (Sağ El)
		play_right_hand_animation()
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("apple"):
				collider.get_parent().queue_free()
				get_node("/root/Main").collect_apple()
			elif collider.is_in_group("npc"):
				get_node("/root/Main").interact_with_npc()
			elif collider.is_in_group("door"):
				get_node("/root/Main").interact_with_door()
			elif collider.is_in_group("plank_pickup"):
				get_node("/root/Main").pickup_plank(collider.get_parent())
			elif collider.is_in_group("plank_place"):
				get_node("/root/Main").place_plank(collider.get_parent())
			elif collider.is_in_group("chest"):
				get_node("/root/Main").interact_with_chest(collider.get_parent())
			elif collider.is_in_group("door2"):
				get_node("/root/Main").interact_with_door2(collider.get_parent())
				
	if event.is_action_pressed("punch"): # Q Tuşu (Sol El)
		play_left_hand_animation()
		if has_sword and raycast.is_colliding():
			var col = raycast.get_collider()
			if col.is_in_group("snake"):
				col.get_parent().queue_free()
				get_node("/root/Main").queue_dialogue("Yılanı öldürdün!", 2.0)

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

func _physics_process(delta):
	if position.y < -15.0:
		if not is_falling_to_void:
			is_falling_to_void = true
			get_node("/root/Main").queue_dialogue("Aşağı düştün...", 3.0)
		
		fall_timer += delta
		if fall_timer >= 3.0:
			get_tree().reload_current_scene()
	
	if is_falling_to_void:
		velocity.y -= gravity * delta
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		if is_on_floor():
			hand_bob_timer += delta * 10.0
			var bob_y = sin(hand_bob_timer) * 0.05
			var bob_x = cos(hand_bob_timer * 0.5) * 0.02
			
			if not is_r_grabbing:
				right_hand.position.y = r_hand_default_pos.y + bob_y
				right_hand.position.x = r_hand_default_pos.x + bob_x
			if not is_l_punching:
				# Sol el zıt yönde sallansın
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
