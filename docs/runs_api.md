# Hợp đồng API: `runs/start` và `runs/finish`

Phía client nằm ở `scripts/autoload/runs.gd` (autoload `Runs`), `scripts/core/run_stats.gd` và `scenes/levels/level.gd`.
Phía server (Edge Function `game-api`) phải làm đúng theo tài liệu này.

## Luồng

```
Vào stage ──> POST /game-api/runs/start  ──> { session_id }      (không đăng nhập hoặc lỗi = chơi OFFLINE, không nộp)
Chơi ...
Thắng / chết / rời stage ──> POST /game-api/runs/finish  ──> { status, rank? }
```

- Client **không chặn** gameplay chờ `runs/start`. Nếu người chơi kết thúc sớm hơn lúc phản hồi về thì `Runs.submit` tự đợi.
- Đồng hồ `clear_time_ms` chạy từ lúc scene stage được load (trước khi nhận `session_id` một chút), nên luôn **nhỏ hơn hoặc bằng**
  thời gian server đã chờ. Luật 3 (`clear_time_ms <= now - started_at + 2000`) vì thế có dư 2 giây cho độ trễ mạng.
- Mỗi phiên chỉ nộp **một lần**. Client tự khóa sau lần nộp đầu, server vẫn phải chặn nộp lần 2.

## `POST /game-api/runs/start`

```json
{ "stage_id": "m1s1", "client_version": "0.1.0" }
```
Trả `200 { "session_id": "<uuid>" }`. Header: `apikey` và `Authorization: Bearer <JWT>`.

## `POST /game-api/runs/finish`

```json
{
  "session_id": "b1c2...",
  "result": "clear",
  "clear_time_ms": 84210,
  "damage_dealt": 1250,
  "damage_taken": 38,
  "dash_count": 14,
  "skill_usage": { "wind": 4, "water": 1, "earth": 2, "fire": 1 },
  "phase_reached": null,
  "signature": "<hmac_sha256_hex, 64 ký tự>"
}
```

`result` là `clear` (hạ hết quái), `death` (player hết máu) hoặc `quit` (rời stage giữa chừng).
`phase_reached` là `null` ở stage thường, `1` hoặc `2` ở boss cuối.

### Cách client đếm các số

| Trường | Định nghĩa |
| --- | --- |
| `damage_dealt` | Tổng **HP thực sự bị trừ** của quái. Đánh quá tay chỉ tính phần máu còn lại. Hạ hết quái thì đúng bằng tổng HP quái trong stage |
| `damage_taken` | Tổng HP player mất (hồi máu không tính, phần dư khi chết không tính) |
| `dash_count` | Số lần vào state Dash |
| `skill_usage` | Số lần **bắt đầu** cast mỗi skill (cooldown bắt đầu tính từ lúc này, nên khớp luật 6) |
| `clear_time_ms` | Thời gian thực (đồng hồ hệ thống, không bị hit-stop làm chậm), tối thiểu 1 |

### Chữ ký HMAC

Ký trên **chuỗi ghép cố định**, KHÔNG ký JSON (thứ tự key giữa Godot và server có thể khác):

```
session_id|result|clear_time_ms|damage_dealt|damage_taken|dash_count|wind|water|earth|fire|phase
```

Số viết dạng nguyên thập phân, `phase` là chuỗi rỗng nếu `phase_reached` là `null`.
Thuật toán: HMAC-SHA256, khóa là secret, kết quả hex chữ thường.
Secret phía client là hằng `HMAC_SECRET` trong `runs.gd`, phía server là biến môi trường `RUN_HMAC_SECRET`:

```
supabase secrets set RUN_HMAC_SECRET=<chuỗi ngẫu nhiên dài>
```

Mã tham chiếu cho Edge Function (Deno / Web Crypto, đã chạy thử cho ra cùng chữ ký với bản Godot):

```ts
type RunFinishBody = {
  session_id: string; result: "clear" | "death" | "quit";
  clear_time_ms: number; damage_dealt: number; damage_taken: number; dash_count: number;
  skill_usage: { wind: number; water: number; earth: number; fire: number };
  phase_reached: number | null; signature: string;
};

export function canonical(p: RunFinishBody): string {
  const s = p.skill_usage;
  return [p.session_id, p.result, p.clear_time_ms, p.damage_dealt, p.damage_taken, p.dash_count,
          s.wind, s.water, s.earth, s.fire, p.phase_reached ?? ""].join("|");
}

export async function sign(secret: string, msg: string): Promise<string> {
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const mac = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(msg));
  return [...new Uint8Array(mac)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

// So sánh thời gian hằng số, tránh lộ chữ ký qua độ trễ khi so từng ký tự
export function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}
```

**Test vector** (secret = `test-secret`), dùng để viết unit test cho server:

| | |
| --- | --- |
| payload | `session_id=11111111-2222-3333-4444-555555555555, result=clear, clear_time_ms=84210, damage_dealt=1250, damage_taken=38, dash_count=14, skill_usage={wind:4,water:1,earth:2,fire:1}, phase_reached=2` |
| chuỗi ký | `11111111-2222-3333-4444-555555555555\|clear\|84210\|1250\|38\|14\|4\|1\|2\|1\|2` |
| chữ ký | `102d24580b0fcab1a819f2e865fe8eacb3716903fefc55afcb75469b670cdeed` |
| cùng payload nhưng `phase_reached=null` | `db8df3ebb68eb1f7de3af61ac091d0bc5a59c7e06d65ca65011b1f7ff4b956d2` |

### Phản hồi mà client hiểu

| HTTP | Body | Client hiển thị |
| --- | --- | --- |
| 200 | `{ "status": "valid", "rank": 3 }` | "Đã ghi kết quả: hạng #3" (`rank` chỉ có khi `clear`) |
| 200 | `{ "status": "valid" }` | "Đã ghi kết quả" |
| 200 | `{ "status": "flagged" }` | "Kết quả đang chờ admin duyệt, chưa lên bảng xếp hạng" |
| 422 | `{ "status": "rejected", "reason": "..." }` | "Kết quả bị từ chối: <reason>" |
| khác | | "Máy chủ báo lỗi (<mã>)" |
| lỗi mạng | | "Không kết nối được máy chủ: kết quả chưa được ghi" |

## Lưu ý khi viết luật anti-cheat ở server

- **Luật 4 (`clear_time_ms >= min_clear_time_ms`) và luật 5 (`damage_dealt >= total_enemy_hp * 0.9`) chỉ áp dụng cho `result = clear`.**
  Người chơi chết sau 20 giây hay rời stage sau 3 giây là bình thường, không được reject.
- Các luật còn lại (3, 5 phần "tối đa lý thuyết", 6) áp dụng cho mọi `result`.
- `quit` do client gửi ở `_exit_tree` của stage, chỉ là cố gắng tốt nhất. Tắt cửa sổ hoặc mất mạng thì session ở lại chưa `consumed_at`.
  Nên có job dọn session cũ, và đặt giới hạn số session chưa nộp mỗi user.
- Client không chứng minh được người chơi có thật sự chơi hay không. Một bot gửi số khai nhất quán và đúng chữ ký vẫn qua mọi luật,
  chặn lại được tới sàn `min_clear_time_ms`. Vì vậy hãy đặt `min_clear_time_ms` sát mức nhanh nhất khả thi và tự flag các lượt sát sàn.

## Chạy thử không cần Supabase

`python tools/mock_game_api.py` dựng server giả ở cổng 8787 (tài khoản thử `a@b.c` / `secret`).
Đổi `SUPABASE_URL` trong `scripts/autoload/supa.gd` thành `http://127.0.0.1:8787`, chạy game, xem `tools/mock_requests.log`.
