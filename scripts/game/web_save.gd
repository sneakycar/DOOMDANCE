extends RefCounted
class_name WebSave

const STORAGE_KEY := "doom_dance_save_v1"

static func is_web() -> bool:
	return OS.has_feature("web")

static func save_dict(data: Dictionary) -> void:
	if not is_web():
		return
	var json_text := JSON.stringify(data)
	var b64 := Marshalls.utf8_to_base64(json_text)
	JavaScriptBridge.eval("localStorage.setItem('%s', '%s');" % [STORAGE_KEY, b64], true)

static func load_dict() -> Dictionary:
	if not is_web():
		return {}
	var b64: Variant = JavaScriptBridge.eval(
		"(function(){try{return localStorage.getItem('%s')||'';}catch(e){return '';}})()" % STORAGE_KEY,
		true
	)
	if b64 == null or str(b64).is_empty():
		return {}
	var json_text := Marshalls.base64_to_utf8(str(b64))
	if json_text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}

static func clear() -> void:
	if not is_web():
		return
	JavaScriptBridge.eval("localStorage.removeItem('%s');" % STORAGE_KEY, true)
