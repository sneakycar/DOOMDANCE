extends SceneTree

func _initialize() -> void:
	var deck := PaintedSegmentDeck.new()
	var dir := SegmentLibrary.PAINTED_NIGHT_DIR
	var n := deck.load_folder(dir)
	if n < 1:
		push_error("FAIL: no painted segments in %s" % dir)
		quit(1)
		return
	var paths: PackedStringArray = []
	for _i in range(mini(n, 5)):
		var art: Dictionary = deck.pick()
		paths.append(art.get("path", ""))
		var tex: Texture2D = SegmentLibrary.load_texture(art.get("path", ""))
		if tex == null:
			push_error("FAIL: could not load %s" % art.get("path", ""))
			quit(1)
			return
		if tex.get_width() != SegmentLibrary.SEGMENT_W or tex.get_height() != SegmentLibrary.SEGMENT_H:
			push_error("FAIL: wrong size %s (%dx%d)" % [art.get("path", ""), tex.get_width(), tex.get_height()])
			quit(1)
			return
	print("OK: %d painted slices; sample picks: %s" % [n, ", ".join(paths)])
	quit(0)
