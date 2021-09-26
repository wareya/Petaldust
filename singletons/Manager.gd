extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func delete_save():
    # FIXME: implement
    pass

func save_game():
    var saved_game = File.new()
    saved_game.open("user://PetaldustSave.save", File.WRITE)
    var persisted_data = {}
    for _node in persists.keys():
        var node : Node2D = _node
        if is_instance_valid(node):
            var node_data = {}
            node_data["x"] = node.position.x
            node_data["y"] = node.position.y
            if "hp" in node:
                node_data["hp"] = node.hp
            if "used" in node:
                node_data["used"] = node.used
            persisted_data[persists[node]] = node_data
            
    persisted_data["highest_combo"] = highest_combo
    var elapsed_time = OS.get_system_time_msecs() - time
    persisted_data["elapsed_time"] = elapsed_time
    
    saved_game.store_string(to_json(persisted_data))
    saved_game.close()

var bypass_loading = false

func load_exists():
    return File.new().file_exists("user://PetaldustSave.save")

func load_game():
    if bypass_loading:
        bypass_loading = false
        prepare_persists()
        return
    var saved_game = File.new()
    if not saved_game.file_exists("user://PetaldustSave.save"):
        return false
    saved_game.open("user://PetaldustSave.save", File.READ)
    var persisted_data = parse_json(saved_game.get_as_text())
    saved_game.close()
    print(persisted_data)
    
    if "highest_combo" in persisted_data:
        highest_combo = persisted_data["highest_combo"]
    
    if "elapsed_time" in persisted_data:
        time = OS.get_system_time_msecs() - persisted_data["elapsed_time"]
    
    var i = -1
    for _node in get_tree().get_nodes_in_group("Persist"):
        i += 1
        var node : Node2D = _node
        if not str(i) in persisted_data:
            print("index %s not in list, erasing node" % i)
            node.queue_free()
            continue
        for key in persisted_data[str(i)]:
            var val = persisted_data[str(i)][key]
            if key == "x":
                node.position.x = val
            elif key == "y":
                node.position.y = val
            elif key == "hp" and "hp" in node:
                node.hp = val
            elif key == "used" and "used" in node:
                node.used = val
        
    for _node in get_tree().get_nodes_in_group("Trigger"):
        i += 1
        var node : Node2D = _node
        if not str(i) in persisted_data:
            print("index %s not in list, erasing node" % i)
            node.queue_free()
            continue
        for key in persisted_data[str(i)]:
            var val = persisted_data[str(i)][key]
            if key == "x":
                node.position.x = val
            elif key == "y":
                node.position.y = val
            elif key == "hp" and "hp" in node:
                node.hp = val
            elif key == "used" and "used" in node:
                node.used = val
    return true

var persists : Dictionary = {}
func prepare_persists():
    persists = {}
    var i = 0
    for _node in get_tree().get_nodes_in_group("Persist"):
        var node : Node2D = _node
        persists[node] = i
        i += 1
    for _node in get_tree().get_nodes_in_group("Trigger"):
        var node : Node2D = _node
        persists[node] = i
        i += 1


# Called when the node enters the scene tree for the first time.
func _ready():
    randomize()
    $EndingBG.hide()
    $Textbox.hide()
    pass # Replace with function body.

func play_bgm(bgm : AudioStream):
    $BGM.stream = bgm
    $BGM.play()

func delayed_emit_signal(sig : String, delay : float = 1.0):
    yield(get_tree().create_timer(delay), "timeout")
    emit_signal(sig)

onready var time = OS.get_system_time_msecs()
var timer_stopped = false

func reset_timer():
    time = OS.get_system_time_msecs()

func show_timer():
    $Timer.show()
func hide_timer():
    $Timer.hide()
func timer_visible():
    return $Timer.visible

var cutscene_inertia_thing = true
var highest_combo = 0
var input_mode = "gameplay"

var typein_mode = true
var typein_chars = -1
func textbox_set_typin(onoff : bool):
    typein_mode = onoff

signal cutscene_continue
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if input_mode == "cutscene":
        if Input.is_action_pressed("ui_skip") and typein_chars >= 0:
            typein_chars = -1
            $Textbox/Label.visible_characters = -1
            delayed_emit_signal("cutscene_continue", 1/20.0)
        if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_jump"):
            if $Textbox/Label.visible_characters < 0 or $Textbox/Label.visible_characters >= $Textbox/Label.get_total_character_count():
                emit_signal("cutscene_continue")
            else:
                typein_chars = -1
                $Textbox/Label.visible_characters = -1
            
            if Input.is_action_just_pressed("ui_accept"):
                Input.action_release("ui_accept")
            if Input.is_action_just_pressed("ui_jump"):
                Input.action_release("ui_jump")
            if Input.is_action_just_pressed("ui_m1"):
                Input.action_release("ui_m1")
        if typein_chars >= 0 and typein_chars < $Textbox/Label.get_total_character_count():
            #if $Textbox/Name.visible or $Textbox/Face.texture != null:
            #    $BleepPlayer.playing = true
            #else:
            #    $BleepPlayer.playing = false
            
            if $Textbox/AnimationPlayer.current_animation == "show" and $Textbox/AnimationPlayer.is_playing():
                pass
            else:
                typein_chars += delta*60 # 20 chars per sec
                $Textbox/Label.visible_characters = floor(typein_chars)
            #$Textbox/NextAnim.hide()
        #else:
            #$BleepPlayer.playing = false
            #if $Textbox/Label.bbcode_text != "":
            #    $Textbox/NextAnim.show()
            #else:
            #    $Textbox/NextAnim.hide()
    
    var player : Node2D = null
    for obj in get_tree().get_nodes_in_group("Player"):
        player = obj
        break
    if player:
        if player.confirmed_combo > 1:
            $ComboLabel.text = str(player.confirmed_combo)+"x Combo"
        else:
            $ComboLabel.text = ""
    if !timer_stopped:# and $Timer.visible:
        var newtime : float = OS.get_system_time_msecs() - time
        var msec = fmod(newtime, 1000)
        var sec = fmod(floor(newtime/1000), 60)
        var minute = fmod(floor(newtime/1000/60), 60)
        var hour = floor(newtime/1000/60/60)
        var string : String = str(msec)
        if string.length() > 3:
            string = string.substr(0, 4)
        while string.length() < 3:
            string = "0"+string
        
        string = str(sec) + "." + string
        if minute > 0 or hour > 0:
            if string.length() < 6:
                string = "0" + string
            string = str(minute) + ":" + string
            if hour > 0:
                if string.length() < 9:
                    string = "0" + string
                string = str(hour) + ":" + string
        $Timer.text = string

func show_ending_bg():
    $EndingBG.show()

func endcard():
    $Endcard/AnimationPlayer.play("show")

func get_player():
    var player : Node2D = null
    for obj in get_tree().get_nodes_in_group("Player"):
        player = obj
        break
    return player

func textbox_show():
    $Textbox/AnimationPlayer.play("show")

func textbox_fade_out():
    $Textbox/AnimationPlayer.play("fadeout")

func textbox_hide():
    $Textbox/AnimationPlayer.play("hide")

func textbox_set_tag(bbcode : String):
    if bbcode == "":
        $Textbox/Label/Tag.hide()
    else:
        $Textbox/Label/Tag.show()
        $Textbox/Label/Tag.bbcode_text = bbcode

func textbox_set_bbcode(bbcode : String):
    if !$Textbox.visible:
        textbox_show()
    $Textbox/Label.bbcode_text = bbcode
    if typein_mode:
        $Textbox/Label.visible_characters = 0
        typein_chars = 0
        #$Textbox/NextAnim.stop()
        #$Textbox/NextAnim.play()
        #$Textbox/NextAnim.hide()
    else:
        $Textbox/Label.visible_characters = -1
        typein_chars = -1
        #$Textbox/NextAnim.stop()
        #$Textbox/NextAnim.play()
        #$Textbox/NextAnim.show()

var override_mode_after_cutscene = null

func start_cutscene(entity : Node, method : String):
    if !entity.has_method(method):
        return input_mode
    var old_mode = input_mode
    input_mode = "cutscene"
    var player : Node2D = null
    for obj in get_tree().get_nodes_in_group("Player"):
        player = obj
        break
    if player:
        player.inform_cutscene()
    yield(entity.call(method), "completed")
    if override_mode_after_cutscene == null:
        end_cutscene(old_mode)
    else:
        end_cutscene(override_mode_after_cutscene)
        override_mode_after_cutscene = null
    
func end_cutscene(old_mode : String):
    #if do_logging:
    #    logfile.store_line("END SCENE")
    #    logfile.store_line("")
    
    input_mode = old_mode
    textbox_hide()
    #hide_bg()
    #hide_all_tachie()
