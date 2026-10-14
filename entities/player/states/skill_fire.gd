extends AttackState
## STUB: hiện chỉ đánh 1 nhát như AttackState thường, để node SkillFire không làm game lỗi.
## TODO (md mục 5):
##  1. Chia pha active thành `skill.fire.hits` (4) xung, mỗi xung gọi lại hitbox.arm(damage).
##  2. Ghi đè _try_cancel: chỉ cho dash sau xung cuối (dash_cancel_ratio = 1.0).
##  3. Hết 4 nhát thì player.add_damage_buff(Config.get_value("skill.fire.buff_mult"),
##     Config.get_value("skill.fire.buff_duration")).
