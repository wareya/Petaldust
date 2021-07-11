tool
extends EditorImportPlugin

var presets:Array = [
    {
        "name": "32px Scanline",
        "options": {
            "fallback_tile_size": 32,
            "fallback_collision_strategy": "scanline"
        },
    },
    {
        "name": "16px Scanline",
        "options": {
            "fallback_tile_size": 16,
            "fallback_collision_strategy": "scanline"
        },
    }
]
var default_preset_options:Array = [
    {
        "name": "fallback_tile_size",
        "default_value": 32
    },
    {
        "name": "fallback_collision_strategy",
        "default_value": "none",
        "property_hint": PROPERTY_HINT_ENUM,
        "hint_string": "none,scanline,rectangle,convex"
    },
    {
        "name": "fallback_tile_type",
        "default_value": "autotile",
        "property_hint": PROPERTY_HINT_ENUM,
        "hint_string": "single,autotile,minitiles",
    },
    {
        "name": "fallback_bitmask",
        "default_value": "3x3minimal",
        "property_hint": PROPERTY_HINT_ENUM,
        "hint_string": "2x2,3x3minimal", #,3x3
    },
    {
        "name": "convert_minitiles",
        "default_value": true,
    }
]

enum CollisionStrategy {
    None, #collision is not generated
    FullRectangle, #just creates a simple full rectangle and expects the user to fix it up themselves
    Scanline, #traverses the block horizontally and makes horizontal rectangles
    BuiltinConvexApproximation, #uses godot's builtin convex hull approximator thing that doesn't work too well when fed a ton of pixels
}

func get_importer_name():
    return "xelivous.auto_tileset"

func get_visible_name():
    return "Auto Tileset"

func get_recognized_extensions():
    return ["json", "tiles"]

func get_save_extension():
    return "tres"

func get_resource_type():
    return "TileSet"

func get_preset_count() -> int:
    return presets.size()

func get_preset_name(preset:int) -> String:
    return presets[preset].name

func get_import_options(preset:int) -> Array:
    var options = default_preset_options.duplicate(true)
    var pre= presets[preset]
    
    for item in options:
        if pre.options.has(item.name):
            item.default_value = pre.options[item.name]
    
    return options

func get_option_visibility(option:String, options:Dictionary):
    return true

func get_import_order() -> int:
    return 10

func import(source_file:String, save_path:String, options:Dictionary, platform_variants:Array, gen_files:Array):
    var file = File.new()
    if file.open(source_file, File.READ) != OK:
        return FAILED
    var file_text:String = file.get_as_text()
    file.close()
    
    var jsonresult:JSONParseResult = JSON.parse(file_text)
    
    if jsonresult.error != OK:
        push_error("Error parsing tileset: %s" % jsonresult.error_string)
        return FAILED
    var json = jsonresult.result
    
    if not json is Dictionary:
        push_error("auto_tileset format should be dictionary: %s " % source_file)
        return FAILED
    
    if process_json_data(json, options, source_file) != OK:
        return FAILED

    var tileset = create_tileset(json.tiles)

    var filename = "%s.%s" % [save_path, get_save_extension()]
    ResourceSaver.save(filename, tileset)
    
    return OK

func process_json_data(data:Dictionary, options:Dictionary, source_file:String) -> int:
    if data.has("tiles"):
        for tile in data.tiles:
            if not tile.has("texture"):
                push_error("auto_tileset should have a texture for every entry")
                return FAILED
            
            if tile.texture.is_rel_path():
                tile.texture = load(source_file.get_base_dir().plus_file(tile.texture))
            else:
                tile.texture = load(tile.texture)
                
            if tile.has("collision"):
                if not tile.collision is String:
                    push_warning("Tile's collision param should be a string. Using supplied default as fallback")
                    tile.collision = options.default_collision_strategy
            else:
                tile.collision = options.fallback_collision_strategy
            
            match tile.collision.to_lower():
                "scanline": 
                    tile.collision = CollisionStrategy.Scanline
                "rectangle":
                    tile.collision = CollisionStrategy.FullRectangle
                "convex":
                    tile.collision = CollisionStrategy.BuiltinConvexApproximation
                "none", "", false:
                    tile.collision = CollisionStrategy.None
                _: 
                    push_warning("Invalid collision strategy (%s). Defaulting to fallback." % tile.collision)
                    tile.collision = options.fallback_collision_strategy
            
            if not tile.has("tile_size"):
                tile.tile_size = options.fallback_tile_size
                
            if not tile.has("type"):
                tile.type = options.fallback_tile_type

            if not tile.has("bitmask"):
                tile.bitmask = options.fallback_bitmask
            
            match tile.bitmask:
                "2x2":
                    tile.bitmask = TileSet.BITMASK_2X2
                "3x3minimal":
                    tile.bitmask = TileSet.BITMASK_3X3_MINIMAL
                #"3x3":
                #	tile.bitmask = TileSet.BITMASK_3X3
                "_":
                    push_warning("Invalid bitmask (%s). Defaulting to 3x3minimal." % tile.collision)
                    tile.bitmask = TileSet.BITMASK_3X3_MINIMAL
            
    return OK

var bitmask_mappings = {
    "3x3minimal": [
        # start at 0,0, move to the right
        TileSet.BIND_CENTER + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_BOTTOM + TileSet.BIND_RIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_BOTTOM + TileSet.BIND_LEFT + TileSet.BIND_RIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_BOTTOM + TileSet.BIND_LEFT,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_LEFT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM,
        # new row
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM,
        0, #empty tile
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM,
        # new row
        TileSet.BIND_CENTER + TileSet.BIND_TOP,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_RIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_RIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_LEFT,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMLEFT,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM,
        # new  row
        TileSet.BIND_CENTER,
        TileSet.BIND_CENTER + TileSet.BIND_RIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_LEFT + TileSet.BIND_RIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_LEFT,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOMLEFT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_LEFT + TileSet.BIND_RIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_RIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM + TileSet.BIND_BOTTOMRIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_RIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_LEFT + TileSet.BIND_RIGHT,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_TOPRIGHT + TileSet.BIND_LEFT + TileSet.BIND_RIGHT + TileSet.BIND_BOTTOM,
        TileSet.BIND_CENTER + TileSet.BIND_TOPLEFT + TileSet.BIND_TOP + TileSet.BIND_LEFT,
    ]
}
    
func create_tileset(textures:Array) -> TileSet:
    var tileset = TileSet.new()
    
    for idx in range(textures.size()):
        var texture = textures[idx]
        tileset.create_tile(idx)
        tileset.tile_set_name(idx, texture.name)
        match texture.type:
            "autotile":
                handle_autotile(tileset, idx, texture)
            "single":
                handle_singletile(tileset, idx, texture)
            "minitiles":
                handle_minitiles(tileset, idx, texture)
            _:
                push_warning("unsupported tile type: %s" % tileset.type)
        if texture.has("no_filter") and texture.no_filter:
            texture.texture.flags &= ~Texture.FLAG_FILTER
    
    return tileset

func handle_singletile(tileset:TileSet, idx:int, texture:Dictionary) -> void:
    push_warning("Single tiles aren't supported at the moment")

func handle_minitiles(tileset:TileSet, idx:int, texture:Dictionary) -> void:
    # small preset tiles that expand into larger images
    
    # TODO: generate/expand into 3x3minimal. for now just resizes lmao
    #push_warning("Minitiles isn't really supported at the moment")
    
    var old_img : Image = texture.texture.get_data()
    var new_size : Vector2 = Vector2(12,4) * texture.tile_size
    var new_img = Image.new()
    new_img.create(texture.tile_size*12, texture.tile_size*4, false, Image.FORMAT_RGBA8)
    
    var cmdlist = [
        # 1x3, 1x1, 3x1
        
        {"type" : "whole", "src" : Vector2(1, 0), "dst" : Vector2(0, 0)},
        {"type" : "top", "src" : Vector2(0, 0), "dst" : Vector2(0, 0)},
        
        {"type" : "whole", "src" : Vector2(1, 0), "dst" : Vector2(0, 1)},
        
        {"type" : "whole", "src" : Vector2(1, 0), "dst" : Vector2(0, 2)},
        {"type" : "bottom", "src" : Vector2(0, 0), "dst" : Vector2(0, 2)},
        
        {"type" : "whole", "src" : Vector2(0, 0), "dst" : Vector2(0, 3)},
        
        {"type" : "whole", "src" : Vector2(2, 0), "dst" : Vector2(1, 3)},
        {"type" : "left", "src" : Vector2(0, 0), "dst" : Vector2(1, 3)},
        
        {"type" : "whole", "src" : Vector2(2, 0), "dst" : Vector2(2, 3)},
        
        {"type" : "whole", "src" : Vector2(2, 0), "dst" : Vector2(3, 3)},
        {"type" : "right", "src" : Vector2(0, 0), "dst" : Vector2(3, 3)},
        
        # 3x3 with interior corners
        
        {"type" : "whole", "src" : Vector2(0, 0), "dst" : Vector2(1, 0)},
        {"type" : "bottom", "src" : Vector2(1, 0), "dst" : Vector2(1, 0)},
        {"type" : "right", "src" : Vector2(2, 0), "dst" : Vector2(1, 0)},
        {"type" : "bottom_right", "src" : Vector2(3, 0), "dst" : Vector2(1, 0)},
        
        {"type" : "whole", "src" : Vector2(1, 0), "dst" : Vector2(1, 1)},
        {"type" : "right", "src" : Vector2(3, 0), "dst" : Vector2(1, 1)},
        
        {"type" : "whole", "src" : Vector2(0, 0), "dst" : Vector2(1, 2)},
        {"type" : "top", "src" : Vector2(1, 0), "dst" : Vector2(1, 2)},
        {"type" : "right", "src" : Vector2(2, 0), "dst" : Vector2(1, 2)},
        {"type" : "top_right", "src" : Vector2(3, 0), "dst" : Vector2(1, 2)},
        
        
        {"type" : "whole", "src" : Vector2(2, 0), "dst" : Vector2(2, 0)},
        {"type" : "bottom", "src" : Vector2(3, 0), "dst" : Vector2(2, 0)},
        
        {"type" : "whole", "src" : Vector2(3, 0), "dst" : Vector2(2, 1)},
        
        {"type" : "whole", "src" : Vector2(2, 0), "dst" : Vector2(2, 2)},
        {"type" : "top", "src" : Vector2(3, 0), "dst" : Vector2(2, 2)},
        
        
        {"type" : "whole", "src" : Vector2(0, 0), "dst" : Vector2(3, 0)},
        {"type" : "bottom", "src" : Vector2(1, 0), "dst" : Vector2(3, 0)},
        {"type" : "left", "src" : Vector2(2, 0), "dst" : Vector2(3, 0)},
        {"type" : "bottom_left", "src" : Vector2(3, 0), "dst" : Vector2(3, 0)},
        
        {"type" : "whole", "src" : Vector2(1, 0), "dst" : Vector2(3, 1)},
        {"type" : "left", "src" : Vector2(3, 0), "dst" : Vector2(3, 1)},
        
        {"type" : "whole", "src" : Vector2(0, 0), "dst" : Vector2(3, 2)},
        {"type" : "top", "src" : Vector2(1, 0), "dst" : Vector2(3, 2)},
        {"type" : "left", "src" : Vector2(2, 0), "dst" : Vector2(3, 2)},
        {"type" : "top_left", "src" : Vector2(3, 0), "dst" : Vector2(3, 2)},
        
        # middle 4x4
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(4, 0)},
        {"type" : "bottom", "src" : Vector2(3, 0), "dst" : Vector2(4, 0)},
        {"type" : "right", "src" : Vector2(3, 0), "dst" : Vector2(4, 0)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(4, 1)},
        {"type" : "left", "src" : Vector2(1, 0), "dst" : Vector2(4, 1)},
        {"type" : "top", "src" : Vector2(1, 0), "dst" : Vector2(4, 1)},
        {"type" : "top_right", "src" : Vector2(3, 0), "dst" : Vector2(4, 1)}, 
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(4, 2)},
        {"type" : "left", "src" : Vector2(1, 0), "dst" : Vector2(4, 2)},
        {"type" : "bottom", "src" : Vector2(1, 0), "dst" : Vector2(4, 2)},
        {"type" : "bottom_right", "src" : Vector2(3, 0), "dst" : Vector2(4, 2)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(4, 3)},
        {"type" : "top", "src" : Vector2(3, 0), "dst" : Vector2(4, 3)},
        {"type" : "right", "src" : Vector2(3, 0), "dst" : Vector2(4, 3)},
        
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(5, 0)},
        {"type" : "left", "src" : Vector2(2, 0), "dst" : Vector2(5, 0)},
        {"type" : "top", "src" : Vector2(2, 0), "dst" : Vector2(5, 0)},
        {"type" : "bottom_left", "src" : Vector2(3, 0), "dst" : Vector2(5, 0)}, 
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(5, 1)},
        {"type" : "top_left", "src" : Vector2(3, 0), "dst" : Vector2(5, 1)}, 
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(5, 2)},
        {"type" : "bottom_left", "src" : Vector2(3, 0), "dst" : Vector2(5, 2)}, 
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(5, 3)},
        {"type" : "left", "src" : Vector2(2, 0), "dst" : Vector2(5, 3)},
        {"type" : "bottom", "src" : Vector2(2, 0), "dst" : Vector2(5, 3)},
        {"type" : "top_left", "src" : Vector2(3, 0), "dst" : Vector2(5, 3)},
        
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(6, 0)},
        {"type" : "right", "src" : Vector2(2, 0), "dst" : Vector2(6, 0)},
        {"type" : "top", "src" : Vector2(2, 0), "dst" : Vector2(6, 0)},
        {"type" : "bottom_right", "src" : Vector2(3, 0), "dst" : Vector2(6, 0)}, 
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(6, 1)},
        {"type" : "top_right", "src" : Vector2(3, 0), "dst" : Vector2(6, 1)}, 
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(6, 2)},
        {"type" : "bottom_right", "src" : Vector2(3, 0), "dst" : Vector2(6, 2)}, 
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(6, 3)},
        {"type" : "right", "src" : Vector2(2, 0), "dst" : Vector2(6, 3)},
        {"type" : "bottom", "src" : Vector2(2, 0), "dst" : Vector2(6, 3)},
        {"type" : "top_right", "src" : Vector2(3, 0), "dst" : Vector2(6, 3)},
        
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(7, 0)},
        {"type" : "bottom", "src" : Vector2(3, 0), "dst" : Vector2(7, 0)},
        {"type" : "left", "src" : Vector2(3, 0), "dst" : Vector2(7, 0)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(7, 1)},
        {"type" : "right", "src" : Vector2(1, 0), "dst" : Vector2(7, 1)},
        {"type" : "top", "src" : Vector2(1, 0), "dst" : Vector2(7, 1)},
        {"type" : "top_left", "src" : Vector2(3, 0), "dst" : Vector2(7, 1)}, 
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(7, 2)},
        {"type" : "right", "src" : Vector2(1, 0), "dst" : Vector2(7, 2)},
        {"type" : "bottom", "src" : Vector2(1, 0), "dst" : Vector2(7, 2)},
        {"type" : "bottom_left", "src" : Vector2(3, 0), "dst" : Vector2(7, 2)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(7, 3)},
        {"type" : "top", "src" : Vector2(3, 0), "dst" : Vector2(7, 3)},
        {"type" : "left", "src" : Vector2(3, 0), "dst" : Vector2(7, 3)},
        
        # final 4x4
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(8, 0)},
        {"type" : "top", "src" : Vector2(0, 0), "dst" : Vector2(8, 0)},
        {"type" : "left", "src" : Vector2(0, 0), "dst" : Vector2(8, 0)},
        {"type" : "top_right", "src" : Vector2(2, 0), "dst" : Vector2(8, 0)},
        {"type" : "bottom_left", "src" : Vector2(1, 0), "dst" : Vector2(8, 0)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(8, 1)},
        {"type" : "left", "src" : Vector2(1, 0), "dst" : Vector2(8, 1)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(8, 2)},
        {"type" : "left", "src" : Vector2(3, 0), "dst" : Vector2(8, 2)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(8, 3)},
        {"type" : "bottom", "src" : Vector2(0, 0), "dst" : Vector2(8, 3)},
        {"type" : "left", "src" : Vector2(0, 0), "dst" : Vector2(8, 3)},
        {"type" : "bottom_right", "src" : Vector2(2, 0), "dst" : Vector2(8, 3)},
        {"type" : "top_left", "src" : Vector2(1, 0), "dst" : Vector2(8, 3)},
        
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(9, 0)},
        {"type" : "top", "src" : Vector2(3, 0), "dst" : Vector2(9, 0)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(9, 1)},
        {"type" : "top_left", "src" : Vector2(3, 0), "dst" : Vector2(9, 1)},
        {"type" : "bottom_right", "src" : Vector2(3, 0), "dst" : Vector2(9, 1)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(9, 2)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(9, 3)},
        {"type" : "bottom", "src" : Vector2(2, 0), "dst" : Vector2(9, 3)},
        
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(10, 0)},
        {"type" : "top", "src" : Vector2(2, 0), "dst" : Vector2(10, 0)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(10, 2)},
        {"type" : "bottom_left", "src" : Vector2(3, 0), "dst" : Vector2(10, 2)},
        {"type" : "top_right", "src" : Vector2(3, 0), "dst" : Vector2(10, 2)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(10, 3)},
        {"type" : "bottom", "src" : Vector2(3, 0), "dst" : Vector2(10, 3)},
        
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(11, 0)},
        {"type" : "top", "src" : Vector2(0, 0), "dst" : Vector2(11, 0)},
        {"type" : "right", "src" : Vector2(0, 0), "dst" : Vector2(11, 0)},
        {"type" : "top_left", "src" : Vector2(2, 0), "dst" : Vector2(11, 0)},
        {"type" : "bottom_right", "src" : Vector2(1, 0), "dst" : Vector2(11, 0)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(11, 1)},
        {"type" : "right", "src" : Vector2(3, 0), "dst" : Vector2(11, 1)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(11, 2)},
        {"type" : "right", "src" : Vector2(1, 0), "dst" : Vector2(11, 2)},
        
        {"type" : "whole", "src" : Vector2(4, 0), "dst" : Vector2(11, 3)},
        {"type" : "bottom", "src" : Vector2(0, 0), "dst" : Vector2(11, 3)},
        {"type" : "right", "src" : Vector2(0, 0), "dst" : Vector2(11, 3)},
        {"type" : "bottom_left", "src" : Vector2(2, 0), "dst" : Vector2(11, 3)},
        {"type" : "top_right", "src" : Vector2(1, 0), "dst" : Vector2(11, 3)},
        
    ]
    
    for cmd in cmdlist:
        cmd.src *= texture.tile_size
        cmd.dst *= texture.tile_size
        var unit_tile = Vector2(texture.tile_size, texture.tile_size)
        if cmd.type in ["whole", "bottom", "top", "left", "right", "bottom_left", "bottom_right", "top_left", "top_right"]:
            var default_offset_start = texture.tile_size/2
            var default_offset_end = texture.tile_size - texture.tile_size/2
            var offset_x_start = 0
            var offset_x_end   = 0
            var offset_y_start = 0
            var offset_y_end   = 0
            if "bottom" in cmd.type:
                offset_y_start = default_offset_start
                if texture.has("margin_bottom"):
                    offset_y_start = texture.tile_size - texture.margin_bottom
            if "top" in cmd.type:
                offset_y_end = default_offset_end
                if texture.has("margin_top"):
                    offset_y_end = texture.tile_size - texture.margin_top
            if "right" in cmd.type:
                offset_x_start = default_offset_start
                if texture.has("margin_right"):
                    offset_x_start = texture.tile_size - texture.margin_right
            if "left" in cmd.type:
                offset_x_end = default_offset_end
                if texture.has("margin_left"):
                    offset_x_end = texture.tile_size - texture.margin_left
            var offset_start = Vector2(offset_x_start, offset_y_start)
            var offset_end = Vector2(offset_x_end, offset_y_end)
            new_img.blit_rect(old_img, Rect2(cmd.src + offset_start, unit_tile - offset_start - offset_end), cmd.dst + offset_start)
    
    var tex = ImageTexture.new()
    tex.create_from_image(new_img)
    texture.texture = tex

    handle_autotile(tileset, idx, texture)

func handle_autotile(tileset:TileSet, idx:int, texture:Dictionary) -> void:
    # handle 3x3minimal/2x2 autotile textures i guess
    tileset.tile_set_texture(idx, texture.texture)
    tileset.tile_set_tile_mode(idx, TileSet.AUTO_TILE)
    tileset.autotile_set_size(idx, Vector2(1,1) * texture.tile_size)
    
    #define the region our tileset should be in
    populate_regions(tileset, idx, texture.texture, texture.tile_size)
    populate_bitmask(tileset, idx, texture.bitmask, texture.tile_size)
    populate_collisions(tileset, idx, texture.collision, texture.texture, texture.tile_size, texture.bitmask)
    set_tileset_icon(tileset, idx, texture.tile_size, texture.bitmask)

func set_tileset_icon(tileset:TileSet, idx:int, tile_size:int, bitmask_mode:int) -> void:
    match bitmask_mode:
        TileSet.BITMASK_3X3_MINIMAL:
            tileset.autotile_set_icon_coordinate(idx, Vector2(0, 3))
    pass

func populate_regions(tileset:TileSet, idx:int, texture:Texture, tile_size:int) -> void:
    tileset.tile_set_region(idx, Rect2(Vector2(0,0), texture.get_size()))

func populate_bitmask(tileset:TileSet, idx:int, bitmask_mode:int, tile_size:int) -> void:
    var mapping:Array
    var columns:int = 0
    var rows:int = 0
    
    match bitmask_mode:
        TileSet.BITMASK_3X3_MINIMAL:
            mapping = bitmask_mappings["3x3minimal"]
            columns = 12
            rows = 4
        _:
            push_warning("Only 3x3 minimal bitmask mode is supported at the moment")
            return
    
    tileset.autotile_set_bitmask_mode(idx, bitmask_mode)
    
    var bitmask_idx:int = 0
    for y in range(rows):
        for x in range(columns):
            var bitmask = mapping[bitmask_idx]
            tileset.autotile_set_bitmask(idx, Vector2(x,y), bitmask)
            bitmask_idx += 1

func populate_collisions(tileset:TileSet, idx:int, strategy:int, texture:Texture, tile_size:int, bitmask_mode:int) -> void:
    var img = texture.get_data()
    var columns:int = 0
    var rows:int = 0
    
    match bitmask_mode:
        TileSet.BITMASK_3X3_MINIMAL:
            columns = 12
            rows = 4
    
    var size = Vector2(1,1) * tile_size
    
    for y in range(rows):
        for x in range(columns):
            var bitmask_idx = Vector2(x,y)
            var bitmask_pos = bitmask_idx * tile_size
            var bitmask_coord = Rect2(bitmask_pos, size)
            match strategy:
                CollisionStrategy.FullRectangle:
                    collision_strategy_fullrectangle(tileset, idx, img, bitmask_coord, bitmask_idx)
                CollisionStrategy.Scanline:
                    collision_strategy_scanline(tileset, idx, img, bitmask_coord, bitmask_idx)
                CollisionStrategy.BuiltinConvexApproximation:
                    collision_strategy_builtin_convex(tileset, idx, img, bitmask_coord, bitmask_idx)

func collision_strategy_fullrectangle(tileset:TileSet, idx:int, img:Image, coords:Rect2, bitmask_idx:Vector2) -> void:
    var tile_img = img.get_rect(coords)
    
    var used_rect = tile_img.get_used_rect()
    if used_rect.has_no_area(): # fully empty
        return
    
    var collider = _create_collision_rectangle(Vector2(0,0), coords.size)
    tileset.tile_add_shape(idx, collider, Transform2D.IDENTITY, false, bitmask_idx)

func collision_strategy_scanline(tileset:TileSet, idx:int, img:Image, coords:Rect2, bitmask_idx:Vector2) -> void:
    var tile_img = img.get_rect(coords)
    
    var scan_start:int = -1
    var scan_end:int = -1
    var last_was_opaque:bool = false
    
    var collider_array = []
    
    tile_img.lock()
    for y in range(coords.size.y):
        last_was_opaque = false #assume transparent to start with
        scan_start = -1
        scan_end = -1
        
        for x in range(coords.size.x):
            var pixel = tile_img.get_pixel(x,y)
            if pixel.a >= 0.5: #opaque pixel
                if scan_start == -1:
                    scan_start = x
                if x == coords.size.x-1: #reached the end of the line
                    scan_end = x+1
            else: #"transparent" pixel
                if scan_start != -1:
                    scan_end = x

            if scan_start != -1 and scan_end != -1:
                var start = Vector3(scan_start, y, 0)
                var end = Vector3(scan_end, y+1, 0)
                collider_array.append(AABB(start, end-start))
                scan_start = -1
                scan_end = -1
    tile_img.unlock()
    
    var merged_collider_array = []
    
    while collider_array.size() > 0:
        var collider:AABB = collider_array.pop_front()
        if collider_array.size() <= 1:
            merged_collider_array.append(collider)
            collider_array.clear()
            break
        
        var colliders_to_remove = []

        for j in range(0, collider_array.size()):
            var other_collider:AABB = collider_array[j]
            
            if collider.position.y == other_collider.position.y:
                #ignore if on same row
                continue
            elif collider.end.y == other_collider.position.y and collider.position.x == other_collider.position.x and collider.end.x == other_collider.end.x:
                # should be a valid merge
                collider = collider.merge(other_collider)
                colliders_to_remove.append(other_collider)
            else:
                # can't merge downwards any more probably
                break
        
        for j in colliders_to_remove:
            collider_array.erase(j)
        
        merged_collider_array.append(collider)
    
    for aabb in merged_collider_array:
        var collider = _create_collision_rectangle(Vector2(aabb.position.x, aabb.position.y), Vector2(aabb.end.x, aabb.end.y))
        tileset.tile_add_shape(idx, collider, Transform2D.IDENTITY, false, bitmask_idx)

func collision_strategy_builtin_convex(tileset:TileSet, idx:int, img:Image, coords:Rect2, bitmask_idx:Vector2) -> void:
    var tile_img = img.get_rect(coords)
    var tile_data = tile_img.get_data()
    
    var collision_array = PoolVector2Array()
    
    tile_img.lock()
    for y in range(coords.size.y):
        for x in range(coords.size.x):
            var pixel = tile_img.get_pixel(x,y)
            if pixel.a == 1.0:
                collision_array.append(Vector2(x, y))
    tile_img.unlock()

    var collision_shape = ConvexPolygonShape2D.new()
    collision_shape.set_point_cloud(collision_array)
    tileset.tile_add_shape(idx, collision_shape, Transform2D.IDENTITY, false, bitmask_idx)

func _create_collision_rectangle(top_left:Vector2, bottom_right:Vector2) -> ConvexPolygonShape2D:
    var collider = ConvexPolygonShape2D.new()
    collider.points = PoolVector2Array([
        top_left,
        Vector2(bottom_right.x,top_left.y),
        bottom_right,
        Vector2(top_left.x,bottom_right.y),
    ])
    return collider
