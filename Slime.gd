extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var hp = 3

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func play_sound():
    #$AnimationPlayer.play("Hit")
    #$AnimationPlayer.seek(0.0, true)
    $HitAnim.play("hit")
    $HitAnim.seek(0.0, true)
    $Emitter.play()

func repeat_combo_ok():
    return true

func slash(attack, player):
    if hp > 0:
        hp -= 1
        play_sound()
        player.velocity.y = min(player.velocity.y, -150)
        player.bypass_variable_jump_height = true
        attack.used = true
        player.confirm_combo_hit(self)
    if hp == 0 and $AnimationPlayer.current_animation != "die":
        $AnimationPlayer.play("die")
        $AnimationPlayer.seek(0.0, true)
        yield($AnimationPlayer, "animation_finished")
        queue_free()
        pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
