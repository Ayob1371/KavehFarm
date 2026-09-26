class_name TitleScreen
extends Control

## صحنه‌ی ورودی بازی: آسمان، عنوان «مزرعه کاوه» و صدای خوش‌آمد.
## کودک با هر لمس صفحه، صدا را دوباره می‌شنود.

var _title: FarsiLabel


func _ready() -> void:
    add_child(SkyBackground.new())

    _title = FarsiLabel.new(
        GameConfig.PROJECT_TITLE,
        GameConfig.TITLE_FONT_SIZE,
        GameConfig.INK_COLOR
    )
    _title.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_title)

    VoicePlayer.play_line(VoiceKeys.WELCOME)


func _input(event: InputEvent) -> void:
    var is_tap: bool = (
        (event is InputEventMouseButton and event.pressed)
        or (event is InputEventScreenTouch and event.pressed)
    )
    if is_tap:
        VoicePlayer.replay_last()
