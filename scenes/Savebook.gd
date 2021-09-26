extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func slash(_attack, _player):
    if $AnimationPlayer.current_animation != "spin":
        $AnimationPlayer.play("spin")
        Manager.save_game()
        EmitterFactory.emit(self, "progress")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if !$AnimationPlayer.is_playing():
        $AnimationPlayer.play("idle")
    pass
