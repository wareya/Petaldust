extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var velocity : Vector2
var gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")
var friction : float = 600
var tweaked = false

func _process(delta):
    if abs(velocity.x) > 5:
        if !$Emitter.playing:
            $Emitter.play()
    else:
        $Emitter.stop()
    velocity.y += gravity/2 * delta
    velocity = move_and_slide(velocity, Vector2(0, -1))
    velocity.y += gravity/2 * delta
    if !tweaked and is_on_floor() and abs(velocity.x) > 0:
        var oldsign = sign(velocity.x)
        velocity.x -= oldsign*friction*delta
        if sign(velocity.x) != oldsign:
            velocity.x = 0
    tweaked = false
    $Sprite.global_position = global_position.round()
    
