import sys

with open("scripts/player.gd", "r") as f:
    lines = f.readlines()

new_code = []
for line in lines:
    if 'elif collider.is_in_group("plank_place"):' in line:
        new_code.append(line)
        new_code.append('\t\t\telif collider.is_in_group("chest"):\n')
        new_code.append('\t\t\t\tget_node("/root/Main").interact_with_chest(collider.get_parent())\n')
        new_code.append('\t\t\telif collider.is_in_group("door2"):\n')
        new_code.append('\t\t\t\tget_node("/root/Main").interact_with_door2(collider.get_parent())\n')
    elif 'play_left_hand_animation()' in line:
        new_code.append(line)
        new_code.append('\t\tif has_sword and raycast.is_colliding():\n')
        new_code.append('\t\t\tvar col = raycast.get_collider()\n')
        new_code.append('\t\t\tif col.is_in_group("snake"):\n')
        new_code.append('\t\t\t\tcol.get_parent().queue_free()\n')
        new_code.append('\t\t\t\tget_node("/root/Main").queue_dialogue("Yılanı öldürdün!", 2.0)\n')
    elif 'var has_sword = false' in line:
        continue
    elif 'var fall_timer = 0.0' in line:
        new_code.append(line)
        new_code.append('var has_sword = false\n')
    else:
        new_code.append(line)

new_code.append("""
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
""")

with open("scripts/player.gd", "w") as f:
    f.writelines(new_code)
