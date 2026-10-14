"""Server GIẢ cho game-api, chỉ để test phía client khi chưa có Supabase thật.
Chạy:  python tools/mock_game_api.py     (cổng 8787)
Rồi đổi SUPABASE_URL trong scripts/autoload/supa.gd thành "http://127.0.0.1:8787" (nhớ đổi lại khi xong).
Tài khoản thử: a@b.c / secret.  Mọi request ghi vào tools/mock_requests.log.
Chỉ kiểm vài luật (chữ ký, thời gian, sát thương tối thiểu), KHÔNG thay thế game-api thật.
"""
import json, hmac, hashlib, time, uuid, os, sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SECRET = os.environ.get("MOCK_SECRET", "CHANGE-ME-same-as-server").encode()
TOTAL_HP = {"m1s1": 350, "m1s2": 400}
sessions = {}
LOG = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "mock_requests.log"), "w")

def canonical(p):
    s = p["skill_usage"]
    phase = "" if p.get("phase_reached") is None else str(int(p["phase_reached"]))
    return "|".join([p["session_id"], p["result"], str(p["clear_time_ms"]), str(p["damage_dealt"]),
                     str(p["damage_taken"]), str(p["dash_count"]), str(s["wind"]), str(s["water"]),
                     str(s["earth"]), str(s["fire"]), phase])

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def _send(self, code, obj):
        b = json.dumps(obj).encode()
        self.send_response(code); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0)); body = json.loads(self.rfile.read(n) or b"{}")
        auth = self.headers.get("Authorization", "")
        LOG.write(f"{self.path} auth={'yes' if auth else 'no'} body={json.dumps(body, ensure_ascii=False)}\n"); LOG.flush()
        if self.path.startswith("/auth/v1/token?grant_type=password"):
            if body.get("email") == "a@b.c" and body.get("password") == "secret":
                return self._send(200, {"access_token": "tok", "refresh_token": "ref", "user": {"id": "u1"}})
            return self._send(400, {"error": "invalid_grant", "error_description": "Invalid login credentials"})
        if auth != "Bearer tok":
            return self._send(401, {"msg": "no jwt"})
        if self.path.endswith("/runs/start"):
            sid = str(uuid.uuid4())
            sessions[sid] = {"t": time.time(), "stage": body["stage_id"], "used": False, "ver": body["client_version"]}
            return self._send(200, {"session_id": sid})
        if self.path.endswith("/runs/finish"):
            s = sessions.get(body.get("session_id"))
            if not s: return self._send(422, {"status": "rejected", "reason": "session không tồn tại"})
            if s["used"]: return self._send(422, {"status": "rejected", "reason": "session đã nộp rồi"})
            s["used"] = True
            expect = hmac.new(SECRET, canonical(body).encode(), hashlib.sha256).hexdigest()
            if not hmac.compare_digest(expect, body.get("signature", "")):
                return self._send(422, {"status": "rejected", "reason": "chữ ký sai"})
            elapsed = int((time.time() - s["t"]) * 1000)
            if body["clear_time_ms"] > elapsed + 2000:
                return self._send(422, {"status": "rejected", "reason": "thời gian khai dài hơn thời gian thật"})
            if body["result"] == "clear" and body["damage_dealt"] < 0.9 * TOTAL_HP[s["stage"]]:
                return self._send(200, {"status": "flagged"})
            return self._send(200, {"status": "valid", "rank": 3} if body["result"] == "clear" else {"status": "valid"})
        self._send(404, {"error": "not found"})

ThreadingHTTPServer(("127.0.0.1", 8787), H).serve_forever()
