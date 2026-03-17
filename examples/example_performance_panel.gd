extends RefCounted

const DEFAULT_TARGET_FPS := 60.0
const REFRESH_INTERVAL_USEC := 250000
const BYTES_PER_KIB := 1024.0
const BYTES_PER_MIB := BYTES_PER_KIB * 1024.0
const BYTES_PER_GIB := BYTES_PER_MIB * 1024.0
const MAX_LABEL_LENGTH := 42

var _viewport_rid: RID
var _cached_text := "Perf panel: waiting for measurements..."
var _gpu_label := "Unavailable"
var _renderer_label := "Unavailable"
var _next_refresh_usec := 0


func setup(viewport: Viewport) -> void:
	_viewport_rid = viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_viewport_rid, true)
	_gpu_label = _truncate_label(RenderingServer.get_video_adapter_name().strip_edges())
	_renderer_label = _truncate_label("%s / %s" % [
		RenderingServer.get_current_rendering_method(),
		RenderingServer.get_current_rendering_driver_name(),
	])
	if _gpu_label.is_empty():
		_gpu_label = "Unavailable"
	if _renderer_label.is_empty():
		_renderer_label = "Unavailable"
	_refresh_metrics(true)


func get_text() -> String:
	if _viewport_rid.is_valid():
		var now := Time.get_ticks_usec()
		if now >= _next_refresh_usec:
			_refresh_metrics()
	return _cached_text


func _refresh_metrics(force: bool = false) -> void:
	if not _viewport_rid.is_valid():
		_cached_text = "Perf panel unavailable"
		return

	var now := Time.get_ticks_usec()
	if not force and now < _next_refresh_usec:
		return

	_next_refresh_usec = now + REFRESH_INTERVAL_USEC

	var target_fps := _get_target_fps()
	var process_time_ms := float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
	var physics_time_ms := float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
	var gpu_render_ms := RenderingServer.viewport_get_measured_render_time_gpu(_viewport_rid)
	var frame_budget_load := _to_budget_percent(process_time_ms, target_fps)
	var gpu_budget_load := _to_budget_percent(gpu_render_ms, target_fps)
	var canvas_draw_calls := RenderingServer.viewport_get_render_info(
		_viewport_rid,
		RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
		RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME
	)
	var canvas_objects := RenderingServer.viewport_get_render_info(
		_viewport_rid,
		RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
		RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME
	)
	var canvas_primitives := RenderingServer.viewport_get_render_info(
		_viewport_rid,
		RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
		RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME
	)
	var fps := int(round(Engine.get_frames_per_second()))
	var ram_bytes := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var vram_bytes := int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))

	_cached_text = "Perf panel: whole demo scene\nAddon path: input + vector math\nRenderer: %s\nGPU: %s\nFPS: %d\nFrame: %s\nPhysics: %.2f ms fixed step\nCanvas: %s\nGPU render: %s\nMemory: %s RAM | %s VRAM" % [
		_renderer_label,
		_gpu_label,
		fps,
		_format_frame_stats(frame_budget_load, target_fps, process_time_ms),
		physics_time_ms,
		_format_canvas_stats(canvas_draw_calls, canvas_objects, canvas_primitives),
		_format_gpu_load(gpu_budget_load, target_fps, gpu_render_ms),
		_format_bytes(ram_bytes),
		_format_bytes(vram_bytes),
	]


func _get_target_fps() -> float:
	if Engine.max_fps > 0:
		return float(Engine.max_fps)

	var refresh_rate := DisplayServer.screen_get_refresh_rate()
	if refresh_rate > 0.0:
		return refresh_rate

	return DEFAULT_TARGET_FPS


func _to_budget_percent(time_ms: float, target_fps: float) -> float:
	if target_fps <= 0.0:
		return 0.0

	var frame_budget_ms := 1000.0 / target_fps
	if frame_budget_ms <= 0.0:
		return 0.0

	return maxf(0.0, (time_ms / frame_budget_ms) * 100.0)


func _format_frame_stats(budget_load: float, target_fps: float, process_time_ms: float) -> String:
	return "%.2f ms script (%.1f%% @ %.0f FPS budget)" % [
		process_time_ms,
		budget_load,
		target_fps,
	]


func _format_canvas_stats(draw_calls: int, canvas_objects: int, canvas_primitives: int) -> String:
	if draw_calls <= 0 and canvas_objects <= 0 and canvas_primitives <= 0:
		return "warming up..."

	return "%d draws | %d items | %s prims" % [
		draw_calls,
		canvas_objects,
		_format_count(canvas_primitives),
	]


func _format_gpu_load(budget_load: float, target_fps: float, gpu_render_ms: float) -> String:
	if gpu_render_ms <= 0.0:
		return "warming up..."

	return "%.1f%% @ %.0f FPS budget (%.2f ms render)" % [
		budget_load,
		target_fps,
		gpu_render_ms,
	]


func _format_bytes(bytes: int) -> String:
	if bytes <= 0:
		return "n/a"
	if bytes >= int(BYTES_PER_GIB):
		return "%.2f GiB" % [float(bytes) / BYTES_PER_GIB]
	if bytes >= int(BYTES_PER_MIB):
		return "%.1f MiB" % [float(bytes) / BYTES_PER_MIB]
	if bytes >= int(BYTES_PER_KIB):
		return "%.1f KiB" % [float(bytes) / BYTES_PER_KIB]
	return "%d B" % bytes


func _format_count(value: int) -> String:
	if value >= 1000000:
		return "%.2fM" % [float(value) / 1000000.0]
	if value >= 1000:
		return "%.1fk" % [float(value) / 1000.0]
	return "%d" % value


func _truncate_label(value: String) -> String:
	if value.length() <= MAX_LABEL_LENGTH:
		return value
	return "%s..." % value.substr(0, MAX_LABEL_LENGTH - 3)