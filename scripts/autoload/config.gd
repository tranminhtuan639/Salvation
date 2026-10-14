extends Node
## Chỉ số cân bằng. Key dạng "skill.fire.cooldown" khớp bảng balance_config.
signal loaded(from_remote: bool)
const PX_PER_UNIT := 64.0
const DEFAULTS_PATH := "res://data/default_balance.json"
const CACHE_PATH := "user://balance_cache.json"
var _values: Dictionary = {}
var _warned: Dictionary = {}
func _ready() -> void:
	_values.merge(_read_json(DEFAULTS_PATH), true)
	_values.merge(_read_json(CACHE_PATH), true)
## Gọi ở boot. Trả true nếu lấy được từ server.
func fetch_remote() -> bool:
	var r: Dictionary = await Supa.request(HTTPClient.METHOD_GET,
			"/rest/v1/balance_config?select=key,value", null, false)
	if not r.ok or not (r.data is Array):
		push_warning("Config: dùng cache/default (status %d) %s" % [r.status, str(r.data)])
		loaded.emit(false)
		return false
	var fresh := {}
	for row in r.data:
		fresh[row["key"]] = float(row["value"])
	_values.merge(fresh, true)
	_write_json(CACHE_PATH, fresh)
	loaded.emit(true)
	return true
func get_value(key: String, fallback := 0.0) -> float:
	if _values.has(key):
		return float(_values[key])
	if not _warned.has(key):
		_warned[key] = true
		push_warning("Config thiếu key '%s', dùng %s" % [key, fallback])
	return fallback
func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
func _write_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
