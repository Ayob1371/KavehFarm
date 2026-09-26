class_name SkyBackground
extends ColorRect

## پس‌زمینه‌ی تمام‌صفحه با رنگ آسمان استاندارد پروژه.

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    color = GameConfig.SKY_COLOR
