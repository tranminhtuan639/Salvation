# Salvation

Action RPG 2D (Godot 4.3+, GDScript) + backend Supabase + web admin.

## Chạy thử
1. Mở Godot 4.3+ -> Import -> chọn `project.godot`. Lần đầu nó import mất vài giây.
2. Bấm F5. Scene `boot` sẽ thử gọi Supabase (chưa điền key thì tự dùng `data/default_balance.json`), rồi vào `test_arena`.
3. Điều khiển: A/D chạy, Space nhảy, K dash, J đánh thường (bấm 3 lần ra combo), U/I/O/P = Gió/Nước/Đất/Lửa.
4. Bật `Debug -> Visible Collision Shapes` để canh hitbox.

## Supabase
Sửa `SUPABASE_URL` và `API_KEY` trong `scripts/autoload/supa.gd`. Chỉ dùng key anon/publishable, tuyệt đối không để `service_role` vào repo.

## Còn thiếu (stub)
- `skill_fire.gd`: mới đánh 1 nhát, chưa có 4 xung + buff.
- `hurt.gd`, `dead.gd`: có script nhưng chưa nối vào cây scene.
- Quái thường, boss, UI, level thật, sprite thật.
