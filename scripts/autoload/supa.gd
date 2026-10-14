extends Node
## Gọi REST của Supabase: Auth, PostgREST, Edge Functions.

const SUPABASE_URL := "https://ibiblfxzbcrojziquqhn.supabase.co"
const API_KEY := "sb_publishable_VnAlkosk0jUjnIry2PtOsQ_EfPmd2h8"
const SESSION_PATH := "user://session.cfg"

signal signed_in
signal signed_out

var access_token := ""
var refresh_token := ""
var user_id := ""


func is_logged_in() -> bool:
	return access_token != ""


## Trả về {ok: bool, status: int, data: Variant}. status = 0 nghĩa là lỗi mạng.
func request(method: HTTPClient.Method, path: String, body: Variant = null,
		use_auth := true, retried := false) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)

	var headers := PackedStringArray(["apikey: " + API_KEY, "Content-Type: application/json"])
	if use_auth and access_token != "":
		headers.append("Authorization: Bearer " + access_token)

	var payload := "" if body == null else JSON.stringify(body)
	var err := http.request(SUPABASE_URL + path, headers, method, payload)
	if err != OK:
		http.queue_free()
		return {"ok": false, "status": 0, "data": null}

	var res: Array = await http.request_completed  # [result, code, headers, body]
	http.queue_free()
	if res[0] != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "status": 0, "data": null}

	var code: int = res[1]
	var text: String = (res[3] as PackedByteArray).get_string_from_utf8()
	var data: Variant = JSON.parse_string(text) if text != "" else null

	# JWT hết hạn: refresh một lần rồi gọi lại
	if code == 401 and use_auth and not retried and refresh_token != "":
		if await refresh_session():
			return await request(method, path, body, use_auth, true)

	return {"ok": code >= 200 and code < 300, "status": code, "data": data}


## Gọi Edge Function game-api, ví dụ: Supa.game_api(HTTPClient.METHOD_GET, "/save")
func game_api(method: HTTPClient.Method, route: String, body: Variant = null) -> Dictionary:
	return await request(method, "/functions/v1/game-api" + route, body)


# ---------------- Auth ----------------

func sign_up(email: String, password: String, username: String) -> Dictionary:
	# Lúc dev: tắt "Confirm email" trong Supabase → Authentication, nếu không sẽ không có session ngay.
	var r: Dictionary = await request(HTTPClient.METHOD_POST, "/auth/v1/signup",
			{"email": email, "password": password, "data": {"username": username}}, false)
	if r.ok and r.data is Dictionary and r.data.has("access_token"):
		_store_session(r.data)
	return r


func sign_in(email: String, password: String) -> Dictionary:
	var r: Dictionary = await request(HTTPClient.METHOD_POST,
			"/auth/v1/token?grant_type=password",
			{"email": email, "password": password}, false)
	if r.ok:
		_store_session(r.data)
	return r


func refresh_session() -> bool:
	if refresh_token == "":
		return false
	var r: Dictionary = await request(HTTPClient.METHOD_POST,
			"/auth/v1/token?grant_type=refresh_token",
			{"refresh_token": refresh_token}, false)
	if r.ok:
		_store_session(r.data)
		return true
	_clear_session()
	return false


## Gọi ở boot: đăng nhập lại bằng refresh token đã lưu.
func restore_session() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SESSION_PATH) != OK:
		return false
	refresh_token = cfg.get_value("auth", "refresh_token", "")
	return await refresh_session()


func sign_out() -> void:
	if is_logged_in():
		await request(HTTPClient.METHOD_POST, "/auth/v1/logout")
	_clear_session()


func _store_session(data: Dictionary) -> void:
	access_token = data.get("access_token", "")
	refresh_token = data.get("refresh_token", "")
	user_id = data.get("user", {}).get("id", "")
	var cfg := ConfigFile.new()  # lưu dạng plain text; nâng cấp (mã hóa) sau nếu cần
	cfg.set_value("auth", "refresh_token", refresh_token)
	cfg.save(SESSION_PATH)
	signed_in.emit()


func _clear_session() -> void:
	access_token = ""
	refresh_token = ""
	user_id = ""
	var cfg := ConfigFile.new()
	cfg.save(SESSION_PATH)
	signed_out.emit()
