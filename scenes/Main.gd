extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func cutscene():
    Manager.reset_timer()
    Manager.hide_timer()
    Manager.timer_stopped = true
    Manager.input_mode = "fadein"
    if $Whiteout.get_node("AnimationPlayer").is_playing():
        yield($Whiteout.get_node("AnimationPlayer"), "animation_finished")
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
    #Manager.show_timer()

# Called when the node enters the scene tree for the first time.
var startmode = "new"
func _ready():
    Manager.prepare_persists()
    $Whiteout.get_node("AnimationPlayer").play("fadein")
    Manager.timer_stopped = true
    
    Manager.input_mode = "fadein"
    
    if $Menu.waiting:
        yield($Menu, "done")
    
    if startmode == "load":
        Manager.play_bgm(preload("res://bgm/slowly slowly everlasting.ogg"))
        Manager.input_mode = "gameplay"
        Manager.timer_stopped = false
    else:
        Manager.input_mode = "gameplay"
        Manager.start_cutscene(self, "cutscene")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    pass
