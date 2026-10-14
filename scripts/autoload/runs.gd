extends Node
## Phiên chơi với backend: runs/start khi vào stage, runs/finish khi kết thúc, kèm chữ ký HMAC.
## Chưa đăng nhập hoặc runs/start thất bại -> chơi OFFLINE (không nộp, không lên bảng xếp hạng).
## Hợp đồng API + cách server kiểm chữ ký: docs/runs_api.md

## Phát sau mỗi lần nộp. text = câu hiển thị cho người chơi, response = {ok, status, data, offline}.
signal submitted(text: String, response: Dictionary)
signal _start_finished

const CLIENT_VERSION := "0.1.0"   # phải nằm trong danh sách phiên bản server hỗ trợ (luật 8)
## PHẢI GIỐNG biến môi trường RUN_HMAC_SECRET của Edge Function game-api.
## Nằm trong game nên có thể bị dump ra; chỉ nâng độ khó, phòng thủ thật là các kiểm tra phía server.
const HMAC_SECRET := "Salvation_Secret_Key_2026_@XYZ!9988"

var session_id := ""
var _starting := false


## Gọi khi vào stage. Có thể không await: lúc nộp kết quả sẽ tự đợi nếu phiên chưa mở xong.
func start(stage_id: String) -> bool:
	session_id = ""
	if not Supa.is_logged_in():
		return false
	_starting = true
	var r: Dictionary = await Supa.game_api(HTTPClient.METHOD_POST, "/runs/start",
			{"stage_id": stage_id, "client_version": CLIENT_VERSION})
	_starting = false
	if r.ok and r.data is Dictionary and r.data.has("session_id"):
		session_id = str(r.data["session_id"])
	else:
		push_warning("Runs: không mở được phiên (status %d), chơi offline" % r.status)
	_start_finished.emit()
	return session_id != ""


## result: "clear" | "death" | "quit". Mỗi phiên chỉ nộp được 1 lần.
func submit(result: String, stats: RunStats) -> Dictionary:
	if _starting:
		await _start_finished
	var response: Dictionary
	if session_id == "":
		response = {"ok": false, "status": 0, "data": null, "offline": true}
	else:
		var sid := session_id
		session_id = ""   # khóa phía client (server cũng chặn nộp lần 2)
		var payload := stats.to_payload(sid, result)
		payload["signature"] = sign_payload(payload)
		response = await Supa.game_api(HTTPClient.METHOD_POST, "/runs/finish", payload)
		response["offline"] = false
	submitted.emit(describe(response, result), response)
	return response


## Chuỗi đem đi ký. KHÔNG ký JSON.stringify vì thứ tự key giữa Godot và server có thể khác.
## Thứ tự và định dạng này là hợp đồng: server phải dựng lại y hệt.
static func canonical(p: Dictionary) -> String:
	var su: Dictionary = p["skill_usage"]
	var phase := "" if p["phase_reached"] == null else str(int(p["phase_reached"]))
	return "|".join(PackedStringArray([
		str(p["session_id"]), str(p["result"]), str(p["clear_time_ms"]),
		str(p["damage_dealt"]), str(p["damage_taken"]), str(p["dash_count"]),
		str(su["wind"]), str(su["water"]), str(su["earth"]), str(su["fire"]), phase,
	]))


static func sign_payload(p: Dictionary) -> String:
	var mac := Crypto.new().hmac_digest(HashingContext.HASH_SHA256,
			HMAC_SECRET.to_utf8_buffer(), canonical(p).to_utf8_buffer())
	return mac.hex_encode()


## Đổi phản hồi của server thành câu cho người chơi.
static func describe(r: Dictionary, result: String) -> String:
	if r.get("offline", false):
		return "Chơi offline: kết quả không được ghi lên bảng xếp hạng"
	var status: int = r.get("status", 0)
	if status == 0:
		return "Không kết nối được máy chủ: kết quả chưa được ghi"
	var data: Dictionary = r["data"] if r.get("data") is Dictionary else {}
	if status == 422 or data.get("status", "") == "rejected":
		return "Kết quả bị từ chối: %s" % str(data.get("reason", data.get("error", "không hợp lệ")))
	if not r.get("ok", false):
		return "Máy chủ báo lỗi (%d)" % status
	match str(data.get("status", "")):
		"flagged":
			return "Kết quả đang chờ admin duyệt, chưa lên bảng xếp hạng"
		"valid":
			if result == "clear" and data.get("rank") != null:
				return "Đã ghi kết quả: hạng #%d" % int(data["rank"])
			return "Đã ghi kết quả"
	return "Đã nộp kết quả"
