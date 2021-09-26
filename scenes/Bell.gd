extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

export(float) var semitone_offset = 0.0
onready var semitone_ratio = pow(2.0, 1.0/12.0)

func play_sound():
    #print("playing animation for bell")
    $AnimationPlayer.play("Hit")
    $AnimationPlayer.seek(0.0, true)
    yield(get_tree().create_timer(0.15), "timeout")
    var hardcoded_offset = -3.25
    $Emitter.pitch_scale = pow(semitone_ratio, semitone_offset+hardcoded_offset)
    $Emitter.play()

func slash(attack, player):
    play_sound()
    if !player.is_on_floor():
        player.velocity.y = min(player.velocity.y, -150)
        player.bypass_variable_jump_height = true
        player.force_just_jumped = true
    attack.used = true
    player.confirm_combo_hit(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
