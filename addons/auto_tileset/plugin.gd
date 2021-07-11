tool
extends EditorPlugin

var import_plugin:EditorImportPlugin

func _enter_tree():
    import_plugin = preload("tilesetter.gd").new()
    add_import_plugin(import_plugin)

func _exit_tree():
    remove_import_plugin(import_plugin)
