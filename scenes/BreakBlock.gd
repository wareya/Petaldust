extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

var ignore_used = true

func slash(_attack, player):
    collision_mask = 0
    collision_layer = 0
    $Sprite.hide()
    $Particles2D.emitting = true
    $Emitter.play()
    player.confirm_combo_hit(self)
    yield(get_tree().create_timer(1.0), "timeout")
    queue_free()
    pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
