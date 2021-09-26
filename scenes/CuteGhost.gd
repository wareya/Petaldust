extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    $Camera.zoom.x = 1.0/3.0
    $Camera.zoom.y = 1.0/3.0
    $LightWander.show()
    pass # Replace with function body.

var _unused

var velocity = Vector2(0, 0)
#var gravity = 480
var lowgrav = 420
var highgrav = 840
var maxspeed = 77
var jumpvelocity = 180
var want_to_jump = false
var lowairfriciton = 200
var highairfriciton = 400
var friction = 1000
var accel = 800

var lastpos : Vector2
var force_canjump = false
var was_on_floor = false
var was_was_on_floor = false

var walk_emitter_clock = 0.3
var walk_emitter_rollover = 0.4

var combo_counter = 0
var combo_timer = 0
var confirmed_combo = 0
#var combo_confirmation_timer = 0

var last_combo_object : Node = null

func confirm_combo_hit(obj):
    #print("testing combo hit")
    if combo_counter > 0:
        #print("still testing combo hit")
        if obj != last_combo_object or (obj.has_method("repeat_combo_ok") and obj.repeat_combo_ok()):
            confirmed_combo += 1
            confirmed_combo = min(confirmed_combo, combo_counter)
            Manager.highest_combo = max(Manager.highest_combo, confirmed_combo)
            #print("highest combo:")
            #print(Manager.highest_combo)
        last_combo_object = obj
        #combo_confirmation_timer = 1

var bypass_variable_jump_height = false

func fadein_splash():
    $Sprite.frame = 0
    EmitterFactory.emit(self, "spawn")
    pass

var hitstun = 0
var force_just_jumped = false

func inform_cutscene():
    if $AnimationPlayer.current_animation == "walk":
        $AnimationPlayer.play("stand")
    want_to_jump = false
    if Manager.cutscene_inertia_thing:
        velocity.x = 0

var safe_ground
func reset_to_safe_ground():
    if global_position.distance_to(safe_ground) < 1:
        return
    #print("emitting...")
    global_position = safe_ground
    EmitterFactory.emit(self, "unexpectedoutcome")
    velocity = Vector2(0, 0)


var disable_gravity = false
var process_speed = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    delta *= process_speed
    
    $LightWander/Follower.offset += delta*20
    $LightWander.transform.x = transform.x
    $LightWander.global_position = global_position.round()
    
    if Manager.input_mode == "gameplay" and Input.is_action_just_pressed("ui_end"):
        Manager.bypass_loading = true
        Manager.highest_combo = 0
        Manager.reset_timer()
        get_tree().reload_current_scene()
    
    if Input.is_action_just_pressed("ui_home"):
        if !Manager.timer_visible():
            Manager.show_timer()
        else:
            Manager.hide_timer()
    
    if Manager.input_mode == "fadein":
        $AnimationPlayer.play("white")
        return
    
    var wishdir = 0
    if Manager.input_mode != "cutscene":
        if Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_up"):
            for _node in get_tree().get_nodes_in_group("Interactable"):
                var node : Area2D = _node
                if node.overlaps_body(self) and node.has_method("interact"):
                    if !node.has_method("usable") or node.usable():
                        node.interact(self)
                        break
        for _node in get_tree().get_nodes_in_group("Trigger"):
            var node : Area2D = _node
            if node.overlaps_body(self) and node.has_method("trigger"):
                if !node.has_method("usable") or node.usable():
                    node.trigger(self)
        
        if Input.is_action_pressed("ui_right"):
            wishdir += 1
        if Input.is_action_pressed("ui_left"):
            wishdir -= 1
        if Input.is_action_just_pressed("ui_jump"):
            want_to_jump = true
        if !Input.is_action_pressed("ui_jump"):
            want_to_jump = false
        
    if wishdir == 1:
        transform.x = Vector2(1.0, 0)
    elif wishdir == -1:
        transform.x = Vector2(-1.0, 0)
    elif Input.is_action_just_pressed("ui_right"):
        transform.x = Vector2(1.0, 0)
    elif Input.is_action_just_pressed("ui_left"):
        transform.x = Vector2(-1.0, 0)
    
    $LightWander.transform.x = transform.x
    
    var old_anim = $AnimationPlayer.current_animation
    
    var just_jumped = false
    if force_just_jumped:
        just_jumped = true
    if (is_on_floor() or was_on_floor or was_was_on_floor or force_canjump) and want_to_jump:
        #print("playing jump")
        EmitterFactory.emit(self, "jump")
        $AnimationPlayer.play("jump")
        $AnimationPlayer.advance(0.0)
        velocity.y = -jumpvelocity
        just_jumped = true
        want_to_jump = false
    
    if is_on_floor() and !(just_jumped or want_to_jump):
        if wishdir != 0:
            #print("playing walk")
            $AnimationPlayer.play("walk")
            $AnimationPlayer.advance(0.0)
            if old_anim == "jump":
                $AnimationPlayer.advance(0.201)
        else:
            $AnimationPlayer.play("stand")
            $AnimationPlayer.advance(0.0)
    else:
        $AnimationPlayer.play("jump")
    
    if abs(velocity.x) > 5 and is_on_floor() and !is_on_wall():
        walk_emitter_clock += delta
        if walk_emitter_clock > walk_emitter_rollover:
            var footsteps = ["A", "B", "C", "D", "E", "F"]
            var choice = footsteps[randi() % footsteps.size()]
            EmitterFactory.emit(self, "footstep"+choice)
            walk_emitter_clock -= walk_emitter_rollover
    else:
        walk_emitter_clock = 0.3
    
    if wishdir == 0 or (wishdir != sign(velocity.x) and abs(velocity.x) > 0):
        var actual_friction = friction
        if wishdir == 0 and !is_on_floor():
            if (Input.is_action_pressed("ui_jump") and Manager.input_mode != "cutscene") or is_on_wall():
                actual_friction = lowairfriciton
            else:
                actual_friction = highairfriciton
        elif wishdir != 0 and is_on_wall():
            actual_friction = 100000
        if abs(velocity.x) > 0 and Manager.cutscene_inertia_thing:
            var old_sign = sign(velocity.x)
            velocity.x -= actual_friction*delta * old_sign
            if sign(velocity.x) != old_sign:
                velocity.x = 0
    else:
        if is_on_wall() and sign(velocity.x) == wishdir:
            pass
        else:
            velocity.x += wishdir*accel*delta
            velocity.x = clamp(velocity.x, -maxspeed, maxspeed)
    
    if combo_timer < 0.4 and is_on_floor():
        #print("resetting combo")
        combo_counter = 0
        combo_timer = 0
        confirmed_combo = 0
        last_combo_object = null
    #if  or combo_timer <= 0:
    #    
    
    if Input.is_action_just_pressed("ui_attack") and Manager.input_mode != "cutscene" and combo_timer <= 0.8:
        var list = ["A", "B", "C", "D"]
        #var choice = list[randi() % list.size()]
        var choice = list[combo_counter % 4]
        EmitterFactory.emit(self, "slash"+choice)
        var slash = preload("res://scenes/Slash.tscn").instance()
        slash.player = self
        get_tree().get_root().add_child(slash)
        if !is_on_wall():
            slash.set_velocity(velocity * Vector2(0.5, 0))
        slash.set_frame(fmod(combo_counter, 4))
        slash.transform.x = transform.x
        slash.global_position = global_position + transform.x*6
        combo_counter += 1
        combo_timer = 1.0
    
    combo_timer -= delta
    #combo_confirmation_timer -= delta
    
    var gravity = lowgrav
    if !Input.is_action_pressed("ui_jump") and velocity.y < 0 and !bypass_variable_jump_height and Manager.input_mode != "cutscene":
        gravity = highgrav
    
    for _lowgravarea in get_tree().get_nodes_in_group("LowGrav"):
        var lowgravarea : Area2D = _lowgravarea
        if lowgravarea.overlaps_body(self):
            gravity = lowgrav*0.4
            break
    
    if velocity.y >= 0 or is_on_floor():
        bypass_variable_jump_height = false
    
    if !disable_gravity:
        if (wishdir == 0) or !(is_on_floor() or was_on_floor) or just_jumped:
            velocity.y += gravity/2*delta
    was_was_on_floor = was_on_floor
    was_on_floor = is_on_floor()
    
    var previous_position = global_position
    
    if velocity.y > 420:
        velocity.y = 420
        #print(velocity.y)
    
    if process_speed != 0:
        if is_on_floor() and !just_jumped:
            _unused = move_and_slide_with_snap(velocity*process_speed, Vector2(0, 4), Vector2(0, -1), true, 4, 0.79, false)
        else:
            _unused = move_and_slide(velocity*process_speed, Vector2(0, -1), true, 4, 0.78, false)
        _unused /= process_speed
    
    if was_on_floor and is_on_floor():
        safe_ground = previous_position
    
    #if _unused.x == 0 and velocity.x != 0 and is_on_wall():
    #    #if 
    #    pass
    
    if !was_on_floor and is_on_floor():
        if abs(velocity.y - _unused.y) > 150:
            EmitterFactory.emit(self, "land")
        elif abs(velocity.y - _unused.y) > 100:
            EmitterFactory.emit(self, "footstepB")
    
    force_canjump = false
    if !is_on_floor() and is_on_wall() and (global_position-lastpos).length_squared() < 0.001 and velocity.y > 5:
        force_canjump = true
    
    lastpos = global_position
    
    if is_on_wall() and !is_on_floor() and abs(velocity.y - _unused.y) > 1.0 and wishdir != 0:
        velocity.x = _unused.x
    
    if is_on_ceiling() and velocity.y < -60 and  _unused.y >= 0:
        #print("playing bonk -- " + str(velocity) + str(_unused))
        EmitterFactory.emit(self, "bonk")
    velocity.y = _unused.y
    
    if previous_position.y == global_position.y:
        velocity.y = 0
    
    var old_y = velocity.y
    
    if !disable_gravity:
        if (wishdir == 0) or !(is_on_floor() or was_on_floor) or just_jumped:
            velocity.y += gravity/2*delta
    
    if force_canjump and velocity.y > 5 and old_y < 5:
        velocity.y = 5
    
    force_just_jumped = false
    if hitstun <= 0:
        for _hurtbox in get_tree().get_nodes_in_group("HurtBox"):
            var hurtbox : Area2D = _hurtbox
            if hurtbox.overlaps_body(self):
                EmitterFactory.emit(self, "hurtsound")
                velocity.y = -50
                velocity.x = sign(global_position.x - hurtbox.global_position.x) * 100
                hitstun = 0.6
                force_just_jumped = true
                bypass_variable_jump_height = true
                combo_counter = 0
                combo_timer = 0
                confirmed_combo = 0
                last_combo_object = null
                break
    hitstun -= delta
    
    #print(velocity.x)
    
    #$Pusher.global_position.y = global_position.y
    #$Pusher.linear_velocity = lerp($Pusher.linear_velocity, velocity, delta*10)
    #$Pusher.sleeping = false
    #$Pusher.sleeping = true
    #$Pusher.global_position.x = lerp($Pusher.global_position.x, global_position.x, delta)
    $LightWander.global_position = global_position.round()
    $Sprite.global_position = global_position.round()
    $Camera.global_position = global_position.round()
    $Camera.force_update_scroll()
