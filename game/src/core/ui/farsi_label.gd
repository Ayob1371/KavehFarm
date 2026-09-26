class_name FarsiLabel
extends Label

## برچسب متنی فارسی با فونت، چینش و رنگ استاندارد پروژه.
## تنها راهِ نمایش متن در بازی همین کلاس است.

func _init(
        text: String = "",
        font_size: int = 32,
        font_color: Color = Color.WHITE
) -> void:
    self.text = text
    add_theme_font_size_override("font_size", font_size)
    add_theme_color_override("font_color", font_color)
    horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _ready() -> void:
    add_theme_font_override("font", load(GameConfig.FONT_PATH))
