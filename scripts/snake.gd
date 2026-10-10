extends CharacterBody3D

var hp = 100
var speed = 4.0
var bite_timer = 0.0
var player: CharacterBody3D

func _ready():
    player = get_node_or_null("/root/Main/Player")
    add_to_group("snake")

func _physics_process(delta):
    if not player or hp <= 0: return
    
    var dist = global_position.distance_to(player.global_position)
    
    if dist < 2.5:
        # Stop moving, start biting
        velocity = Vector3.ZERO
        bite_timer += delta
        if bite_timer >= 3.0:
            bite_timer = 0.0
            player.take_damage(40)
    else:
        # Move towards player
        bite_timer = 0.0
        var dir = (player.global_position - global_position).normalized()
        dir.y = 0 # stay on ground
        velocity = dir * speed
        
    # Gravity
    if not is_on_floor():
        velocity.y -= 15.0 * delta
        
    move_and_slide()

func take_damage(amount: int):
    hp -= amount
    if hp <= 0:
        queue_free()
