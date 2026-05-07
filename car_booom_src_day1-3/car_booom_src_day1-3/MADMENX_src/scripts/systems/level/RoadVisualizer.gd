# RoadVisualizer -路段可视化系统
# 垂直追尾视角：机车在下方，道路在屏幕中下方
class_name RoadVisualizer
extends CanvasLayer

signal segment_progress_changed(progress: float)

# 垂直视角：道路区域在屏幕中下方
const ROAD_TOP: float = 450.0    # 道路上边界（偏下）
const ROAD_BOTTOM: float = 900.0   # 道路下边界
const ROAD_CENTER_Y: float = 675.0  # 道路中心Y
const ROAD_HEIGHT: float = ROAD_BOTTOM - ROAD_TOP

const LANE_COUNT: int = 4
const SEGMENT_LENGTH: float = 2000.0
const DASH_COUNT: int = 8

var _current_width_ratio: float = 1.0
var _current_segment: int = 0
var _total_segments: int = 10
var _segment_progress: float = 0.0

var _scroll_offset: float = 0.0
var _scroll_speed: float = 150.0
var _scroll_enabled: bool = false

var _background: Polygon2D
var _boundary_top: Line2D
var _boundary_bottom: Line2D
var _lane_lines: Array = []
var _scroll_markers: Array = []
var _scroll_marker_positions: Array = []

var _hud_layer: CanvasLayer
var _segment_label: Label
var _segment_progress_bar: ProgressBar

var _rest_point_label: Label
var _rest_point_timer: float = 0.0

var _special_overlay: ColorRect
var _rest_point_visual: Node2D

var _viewport_width: float = 1920.0
var _viewport_height: float = 1080.0

var _game_started: bool = false

var _world_road_layer: Node2D

# 道路宽度过渡动画
var _target_width_ratio: float = 1.0
var _width_transition_speed: float = 3.0

func _ready() -> void:
	_connect_signals()
	_update_viewport_size()
	_build_world_road_layer()
	_build_all_visuals()
	print("[RoadVisualizer] Initialized")

func _connect_signals() -> void:
	EventBus.road_width_changed.connect(_on_road_width_changed)
	EventBus.segment_changed.connect(_on_segment_changed)
	EventBus.segment_started.connect(_on_segment_started)
	EventBus.fog_activated.connect(_on_fog_activated)
	EventBus.fog_deactivated.connect(_on_fog_deactivated)
	EventBus.level_start_requested.connect(_on_level_started)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	EventBus.vehicle_speed_changed.connect(_on_vehicle_speed_changed)
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.rest_point_entered.connect(_on_rest_point_entered)
	EventBus.rest_point_exited.connect(_on_rest_point_exited)

	if get_viewport():
		get_viewport().size_changed.connect(_on_viewport_size_changed)

func _build_world_road_layer() -> void:
	_world_road_layer = Node2D.new()
	_world_road_layer.name = "RoadWorldLayer"
	_world_road_layer.z_index = -50
	var parent = get_parent()
	if parent:
		parent.add_child(_world_road_layer)

func _on_viewport_size_changed() -> void:
	_update_viewport_size()
	_build_all_visuals()

func _update_viewport_size() -> void:
	if get_viewport():
		var size = get_viewport().get_visible_rect().size
		if size.x > 0 and size.y > 0:
			_viewport_width = size.x
			_viewport_height = size.y

func _process(delta: float) -> void:
	if not _scroll_enabled:
		return

	_scroll_offset += _scroll_speed * delta
	if _scroll_offset >= SEGMENT_LENGTH:
		_scroll_offset -= SEGMENT_LENGTH

	_update_scroll_markers()

	if _rest_point_timer > 0:
		_rest_point_timer -= delta
		if _rest_point_timer <= 0:
			_hide_rest_point_hint()

	# 平滑过渡道路宽度
	_update_road_width_transition(delta)

func _on_vehicle_speed_changed(speed: float) -> void:
	_scroll_speed = 150.0 + speed * 0.3

func _get_road_height() -> float:
	return ROAD_HEIGHT * _current_width_ratio

func _get_road_top() -> float:
	return ROAD_CENTER_Y - _get_road_height() / 2.0

func _get_road_bottom() -> float:
	return ROAD_CENTER_Y + _get_road_height() / 2.0

func _build_all_visuals() -> void:
	_clear_visuals()

	var road_top = _get_road_top()
	var road_bottom = _get_road_bottom()

	_build_world_road_layer()
	_build_background(road_top, road_bottom)
	_build_boundaries(road_top, road_bottom)
	_build_lane_dividers(road_top, road_bottom)
	_build_scroll_markers(road_top, road_bottom)
	_build_hud()
	_build_special_overlay(road_top, road_bottom)
	_build_rest_point_visual(road_top, road_bottom)

func _get_or_create_road_parent() -> Node:
	if not is_instance_valid(_world_road_layer):
		_build_world_road_layer()
	return _world_road_layer

func _build_background(road_top: float, road_bottom: float) -> void:
	var parent = _get_or_create_road_parent()

	var pts = PackedVector2Array([
		Vector2(0, road_top), Vector2(_viewport_width, road_top),
		Vector2(_viewport_width, road_bottom), Vector2(0, road_bottom)
	])
	var bg = Polygon2D.new()
	bg.name = "RoadBackground"
	bg.polygon = pts
	bg.color = Color(0.3, 0.3, 0.36, 1.0)
	bg.z_index = -20
	parent.add_child(bg)
	_background = bg

	var shoulder_pts_top = PackedVector2Array([
		Vector2(0, road_top - 60), Vector2(_viewport_width, road_top - 60),
		Vector2(_viewport_width, road_top), Vector2(0, road_top)
	])
	var top_shoulder = Polygon2D.new()
	top_shoulder.name = "ShoulderTop"
	top_shoulder.polygon = shoulder_pts_top
	top_shoulder.color = Color(0.15, 0.15, 0.2, 1.0)
	top_shoulder.z_index = -19
	parent.add_child(top_shoulder)

	var shoulder_pts_bottom = PackedVector2Array([
		Vector2(0, road_bottom), Vector2(_viewport_width, road_bottom),
		Vector2(_viewport_width, road_bottom + 60), Vector2(0, road_bottom + 60)
	])
	var bottom_shoulder = Polygon2D.new()
	bottom_shoulder.name = "ShoulderBottom"
	bottom_shoulder.polygon = shoulder_pts_bottom
	bottom_shoulder.color = Color(0.15, 0.15, 0.2, 1.0)
	bottom_shoulder.z_index = -19
	parent.add_child(bottom_shoulder)

func _build_boundaries(road_top: float, road_bottom: float) -> void:
	var parent = _get_or_create_road_parent()
	var boundary_color = Color(1.0, 0.9, 0.2, 1.0)

	var top_pts = PackedVector2Array([Vector2(0, road_top), Vector2(_viewport_width, road_top)])
	var top_line = Line2D.new()
	top_line.name = "BoundaryTop"
	top_line.points = top_pts
	top_line.default_color = boundary_color
	top_line.width = 6.0
	top_line.z_index = 9
	parent.add_child(top_line)
	_boundary_top = top_line

	var bot_pts = PackedVector2Array([Vector2(0, road_bottom), Vector2(_viewport_width, road_bottom)])
	var bot_line = Line2D.new()
	bot_line.name = "BoundaryBottom"
	bot_line.points = bot_pts
	bot_line.default_color = boundary_color
	bot_line.width = 6.0
	bot_line.z_index = 9
	parent.add_child(bot_line)
	_boundary_bottom = bot_line

func _build_lane_dividers(road_top: float, _road_bottom: float) -> void:
	var parent = _get_or_create_road_parent()
	var road_h = _get_road_height()
	var lane_color = Color(1.0, 0.9, 0.2, 0.6)

	for i in range(1, LANE_COUNT):
		var lane_y = road_top + road_h * (float(i) / LANE_COUNT)
		for seg in range(8):
			var seg_y = lane_y + (seg - 3.5) * (road_h * 0.05)
			var line_pts = PackedVector2Array([Vector2(0, seg_y), Vector2(_viewport_width, seg_y)])
			var line = Line2D.new()
			line.name = "LaneDivider_%d_%d" % [i, seg]
			line.points = line_pts
			line.default_color = lane_color
			line.width = 3.0
			line.z_index = 8
			parent.add_child(line)
			_lane_lines.append(line)

func _build_scroll_markers(road_top: float, _road_bottom: float) -> void:
	var parent = _get_or_create_road_parent()
	var road_h = _get_road_height()
	var marker_color = Color(0.5, 0.5, 0.5, 0.3)
	var marker_w = 60.0
	var marker_h = 3.0
	var marker_gap = road_h * 0.12

	_scroll_marker_positions.clear()
	for col in range(3):
		var x_pos = _viewport_width * 0.25 + col * _viewport_width * 0.25
		for i in range(DASH_COUNT):
			var y_base = road_top + marker_gap * 0.5 + (marker_h + marker_gap) * i
			_scroll_marker_positions.append({"x": x_pos, "y": y_base, "col": col, "idx": i})

			var line_pts = PackedVector2Array([
				Vector2(x_pos - marker_w / 2, y_base), Vector2(x_pos + marker_w / 2, y_base)
			])
			var line = Line2D.new()
			line.name = "ScrollMarker_%d_%d" % [col, i]
			line.points = line_pts
			line.default_color = marker_color
			line.width = marker_h
			line.z_index = 7
			parent.add_child(line)
			_scroll_markers.append(line)

func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HUD_Layer"
	_hud_layer.layer = 100
	add_child(_hud_layer)

	var hud_bg = ColorRect.new()
	hud_bg.name = "HUDBG"
	hud_bg.set_anchors_preset(Control.PRESET_CENTER)
	hud_bg.anchor_left = 0.5
	hud_bg.anchor_top = 0.0
	hud_bg.anchor_right = 0.5
	hud_bg.anchor_bottom = 0.0
	hud_bg.offset_left = -200.0
	hud_bg.offset_top = 15.0
	hud_bg.offset_right = 200.0
	hud_bg.offset_bottom = 65.0
	hud_bg.color = Color(0.0, 0.0, 0.0, 0.6)
	_hud_layer.add_child(hud_bg)

	_segment_progress_bar = ProgressBar.new()
	_segment_progress_bar.name = "SegmentProgress"
	_segment_progress_bar.set_anchors_preset(Control.PRESET_CENTER)
	_segment_progress_bar.anchor_left = 0.5
	_segment_progress_bar.anchor_top = 0.0
	_segment_progress_bar.anchor_right = 0.5
	_segment_progress_bar.anchor_bottom = 0.0
	_segment_progress_bar.offset_left = -180.0
	_segment_progress_bar.offset_top = 20.0
	_segment_progress_bar.offset_right = 180.0
	_segment_progress_bar.offset_bottom = 40.0
	_segment_progress_bar.max_value = 100.0
	_segment_progress_bar.value = 0.0
	_segment_progress_bar.show_percentage = false
	_hud_layer.add_child(_segment_progress_bar)

	_segment_label = Label.new()
	_segment_label.name = "SegmentLabel"
	_segment_label.set_anchors_preset(Control.PRESET_CENTER)
	_segment_label.anchor_left = 0.5
	_segment_label.anchor_top = 0.0
	_segment_label.anchor_right = 0.5
	_segment_label.anchor_bottom = 0.0
	_segment_label.offset_left = -50.0
	_segment_label.offset_top = 42.0
	_segment_label.offset_right = 50.0
	_segment_label.offset_bottom = 62.0
	_segment_label.text = "SEG 1 / 10"
	_segment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_layer.add_child(_segment_label)

	_rest_point_label = Label.new()
	_rest_point_label.name = "RestPointHint"
	_rest_point_label.set_anchors_preset(Control.PRESET_CENTER)
	_rest_point_label.anchor_left = 0.5
	_rest_point_label.anchor_top = 0.5
	_rest_point_label.anchor_right = 0.5
	_rest_point_label.anchor_bottom = 0.5
	_rest_point_label.offset_left = -150.0
	_rest_point_label.offset_top = -20.0
	_rest_point_label.offset_right = 150.0
	_rest_point_label.offset_bottom = 20.0
	_rest_point_label.text = "[ REST POINT ]"
	_rest_point_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rest_point_label.add_theme_font_size_override("font_size", 28)
	_rest_point_label.modulate.a = 0.0
	_hud_layer.add_child(_rest_point_label)

func _build_rest_point_visual(road_top: float, road_bottom: float) -> void:
	var parent = _get_or_create_road_parent()
	var visual = Node2D.new()
	visual.name = "RestPointVisual"
	visual.z_index = 1
	parent.add_child(visual)
	_rest_point_visual = visual

	var road_h = road_bottom - road_top
	var wall_color = Color(0.08, 0.06, 0.04, 0.85)
	var wall_w = 140.0
	var wall_gap = road_h * 0.1

	for side in range(2):
		var is_left = side == 0
		var x_pos = 0.0 if is_left else _viewport_width - wall_w
		var wall_pts = PackedVector2Array([
			Vector2(x_pos, road_top + wall_gap),
			Vector2(x_pos + wall_w, road_top + wall_gap),
			Vector2(x_pos + wall_w, road_bottom - wall_gap),
			Vector2(x_pos, road_bottom - wall_gap)
		])
		var wall = Polygon2D.new()
		wall.name = "RestWall_%d" % side
		wall.polygon = wall_pts
		wall.color = wall_color
		wall.z_index = 2
		visual.add_child(wall)

		for i in range(4):
			var building_h = randf_range(30.0, 70.0)
			var building_w = randf_range(20.0, 50.0)
			var gap_y = (road_h - wall_gap * 2) / 5.0
			var by = road_top + wall_gap + gap_y * (i + 1) - building_h * 0.5
			var bx = x_pos + randf_range(5.0, wall_w - building_w - 5.0)

			var bld_pts = PackedVector2Array([
				Vector2(bx, by), Vector2(bx + building_w, by),
				Vector2(bx + building_w, by + building_h), Vector2(bx, by + building_h)
			])
			var building = Polygon2D.new()
			building.name = "Building_%d_%d" % [side, i]
			building.polygon = bld_pts
			building.color = Color(0.06, 0.05, 0.04, 1.0)
			building.z_index = 2
			visual.add_child(building)

	var roof_top_pts = PackedVector2Array([
		Vector2(0, road_top - 60), Vector2(_viewport_width, road_top - 60),
		Vector2(_viewport_width, road_top), Vector2(0, road_top)
	])
	var roof_top = Polygon2D.new()
	roof_top.name = "RoofTop"
	roof_top.polygon = roof_top_pts
	roof_top.color = Color(0.06, 0.05, 0.04, 0.9)
	roof_top.z_index = 2
	visual.add_child(roof_top)

	var roof_bot_pts = PackedVector2Array([
		Vector2(0, road_bottom), Vector2(_viewport_width, road_bottom),
		Vector2(_viewport_width, road_bottom + 60), Vector2(0, road_bottom + 60)
	])
	var roof_bot = Polygon2D.new()
	roof_bot.name = "RoofBottom"
	roof_bot.polygon = roof_bot_pts
	roof_bot.color = Color(0.06, 0.05, 0.04, 0.9)
	roof_bot.z_index = 2
	visual.add_child(roof_bot)

	visual.modulate.a = 0.0

func _build_special_overlay(road_top: float, road_bottom: float) -> void:
	_hud_layer = get_node_or_null("HUD_Layer")
	if not _hud_layer:
		_hud_layer = CanvasLayer.new()
		_hud_layer.name = "HUD_Layer"
		_hud_layer.layer = 100
		add_child(_hud_layer)

	var overlay = ColorRect.new()
	overlay.name = "SpecialOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.position = Vector2(0, road_top)
	overlay.size = Vector2(_viewport_width, road_bottom - road_top)
	overlay.color = Color(0, 0, 0, 0)
	overlay.z_index = -60
	_hud_layer.add_child(overlay)
	_special_overlay = overlay

func _update_scroll_markers() -> void:
	if _scroll_markers.size() == 0 or _scroll_marker_positions.size() == 0:
		return

	var road_top = _get_road_top()
	var road_h = _get_road_height()

	for i in range(_scroll_markers.size()):
		var marker = _scroll_markers[i]
		if not is_instance_valid(marker):
			continue
		var pos_data = _scroll_marker_positions[i]
		var y_base = pos_data["y"]
		var x_pos = pos_data["x"]
		var scrolled_y = fposmod(y_base + _scroll_offset * 0.5, road_h) + road_top

		var new_pts = PackedVector2Array([
			Vector2(x_pos - 30.0, scrolled_y), Vector2(x_pos + 30.0, scrolled_y)
		])
		marker.points = new_pts

func _clear_visuals() -> void:
	_lane_lines.clear()
	_scroll_markers.clear()
	_scroll_marker_positions.clear()

	for child in get_children():
		if child.name == "HUD_Layer":
			continue
		child.queue_free()

	if is_instance_valid(_hud_layer):
		for child in _hud_layer.get_children():
			child.queue_free()
		_hud_layer.queue_free()
		_hud_layer = null

	if is_instance_valid(_world_road_layer):
		for child in _world_road_layer.get_children():
			child.queue_free()

	_background = null
	_boundary_top = null
	_boundary_bottom = null
	_segment_label = null
	_segment_progress_bar = null
	_rest_point_label = null
	_special_overlay = null
	_rest_point_visual = null

func _on_road_width_changed(ratio: float) -> void:
	_target_width_ratio = clamp(ratio, 0.3, 1.0)
	# 不再立即重建，只更新目标值，过渡动画在 _process 中处理
	print("[RoadVisualizer] Road width target: ", _target_width_ratio)

## 平滑过渡道路宽度
func _update_road_width_transition(delta: float) -> void:
	if abs(_current_width_ratio - _target_width_ratio) < 0.01:
		if _current_width_ratio != _target_width_ratio:
			_current_width_ratio = _target_width_ratio
			_build_all_visuals()  # 过渡完成后重建以确保精确
		return
	
	_current_width_ratio = lerp(_current_width_ratio, _target_width_ratio, _width_transition_speed * delta)
	_build_all_visuals()

func _on_segment_changed(segment_id: int) -> void:
	_current_segment = segment_id
	_segment_progress = 0.0
	_scroll_offset = 0.0
	_update_hud()
	print("[RoadVisualizer] Segment changed: ", segment_id)

func _on_segment_started(segment_id: int) -> void:
	_current_segment = segment_id
	_segment_progress = 0.0
	_scroll_offset = 0.0
	_update_hud()
	print("[RoadVisualizer] Segment started: ", segment_id)

func _on_level_started(_level_id: String) -> void:
	_game_started = true
	_scroll_enabled = true
	_scroll_offset = 0.0
	_current_segment = 0
	_segment_progress = 0.0
	_update_hud()
	print("[RoadVisualizer] Level started, scrolling enabled")

func _on_level_completed(level_id: int) -> void:
	_scroll_enabled = false
	print("[RoadVisualizer] Level completed: ", level_id)

func _on_rest_point_entered() -> void:
	_show_rest_point_hint()
	_show_rest_point_visual()

func _show_rest_point_hint() -> void:
	if _rest_point_label:
		_rest_point_label.modulate.a = 1.0
	_rest_point_timer = 3.0

	var tween = create_tween()
	if _rest_point_label:
		tween.tween_property(_rest_point_label, "modulate:a", 0.0, 1.0).set_delay(2.0)

func _hide_rest_point_hint() -> void:
	if _rest_point_label:
		_rest_point_label.modulate.a = 0.0

func _show_rest_point_visual() -> void:
	if not is_instance_valid(_rest_point_visual):
		return
	var tween = create_tween()
	tween.tween_property(_rest_point_visual, "modulate:a", 1.0, 0.8)

func _hide_rest_point_visual() -> void:
	if not is_instance_valid(_rest_point_visual):
		return
	var tween = create_tween()
	tween.tween_property(_rest_point_visual, "modulate:a", 0.0, 0.5)

func _on_rest_point_exited() -> void:
	_hide_rest_point_visual()

func _on_fog_activated(coverage_ratio: float) -> void:
	if _special_overlay:
		var current_alpha = _special_overlay.color.a
		var fog_alpha = coverage_ratio * 0.5
		_special_overlay.color = Color(0.3, 0.3, 0.4, max(current_alpha, fog_alpha))
	print("[RoadVisualizer] Fog activated (coverage: ", coverage_ratio, ")")

func _on_fog_deactivated() -> void:
	if _special_overlay:
		# 所有雾效都已结束，清除雾效
		_special_overlay.color = Color(0, 0, 0, 0)
	print("[RoadVisualizer] Fog deactivated")

func _get_special_segment_manager() -> Node:
	var game_world = get_tree().get_first_node_in_group("GameWorld")
	if game_world and game_world.has_node("SpecialSegmentManager"):
		return game_world.get_node("SpecialSegmentManager")
	elif has_node("../SpecialSegmentManager"):
		return get_node("../SpecialSegmentManager")
	return null

func _on_game_paused() -> void:
	_scroll_enabled = false

func _on_game_resumed() -> void:
	if _game_started:
		_scroll_enabled = true

func _update_hud() -> void:
	if _segment_label:
		_segment_label.text = "SEG %d / %d" % [_current_segment + 1, _total_segments]
	if _segment_progress_bar:
		_segment_progress_bar.value = _segment_progress * 100.0

func update_segment_progress(progress: float) -> void:
	_segment_progress = clamp(progress, 0.0, 1.0)
	segment_progress_changed.emit(_segment_progress)
	_update_hud()

func set_total_segments(count: int) -> void:
	_total_segments = count
	_update_hud()

func get_road_bounds() -> Dictionary:
	return {
		"top": _get_road_top(),
		"bottom": _get_road_bottom(),
		"center_y": ROAD_CENTER_Y,
		"height": _get_road_height()
	}

func get_road_spawn_bounds() -> Dictionary:
	var bounds = get_road_bounds()
	return {
		"left": 50.0,
		"right": _viewport_width - 50.0,
		"top": bounds["top"] + 20.0,
		"bottom": bounds["bottom"] - 20.0
	}
