extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    #rotation = 0
    $Sprite.global_position = global_position.round()
    $Sprite.rotation = -rotation

func _integrate_forces(state):
    state.angular_velocity = 0
    state.transform.x = Vector2(1, 0)
    state.transform.y = Vector2(0, 1)
