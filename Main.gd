extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func cutscene():
    Manager.reset_timer()
    Manager.hide_timer()
    Manager.timer_stopped = true
    Manager.input_mode = "fadein"
    $Whiteout.get_node("AnimationPlayer").play("fadein")
    yield($Whiteout, "done")
    yield(get_tree().create_timer(0.5), "timeout")
    Manager.input_mode = "cutscene"
    $CuteGhost.fadein_splash()
    $SpawnParticles.emitting = true
    Manager.play_bgm(preload("res://bgm/slowly slowly everlasting.ogg"))
    yield(get_tree().create_timer(0.8), "timeout")
    
    Manager.textbox_set_bbcode("Why did she send me [stress]here[/stress]?")
    yield(Manager, "cutscene_continue")
    
    Manager.textbox_set_bbcode("There was a Taco Chime [stress]right across the street[/stress]. I could've just walked over.")
    yield(Manager, "cutscene_continue")
    
    Manager.textbox_set_bbcode("Does she want something else?")
    yield(Manager, "cutscene_continue")
    
    Manager.textbox_set_bbcode("Oh well. Might as well play along.")
    yield(Manager, "cutscene_continue")
    
    Manager.timer_stopped = false
    Manager.reset_timer()
    Manager.show_timer()

# Called when the node enters the scene tree for the first time.
func _ready():
    if true:
        Manager.start_cutscene(self, "cutscene")
    else:
        $Whiteout.get_node("AnimationPlayer").play("fadein")
        Manager.play_bgm(preload("res://bgm/slowly slowly everlasting.ogg"))
        Manager.input_mode = "gameplay"
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    pass
