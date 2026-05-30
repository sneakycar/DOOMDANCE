class_name RbdSave
extends RefCounted

static func load_session() -> Dictionary:
	if not FileAccess.file_exists(RbdConstants.SAVE_PATH):
		return {}
	var f := FileAccess.open(RbdConstants.SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = f.get_var()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func save_session(data: Dictionary) -> void:
	var f := FileAccess.open(RbdConstants.SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("RBD: could not write save")
		return
	f.store_var(data)

static func delete_session() -> void:
	if FileAccess.file_exists(RbdConstants.SAVE_PATH):
		DirAccess.remove_absolute(RbdConstants.SAVE_PATH)
