class_name TitleScreen
extends Control

## صحنه‌ی ورودی بازی: آسمان، عنوان «مزرعه کاوه» و صدای خوش‌آمد.
## پس از پایان خوش‌آمد، راهنمای چشمک‌زن ظاهر می‌شود و هر لمس،
## کودک را به صحنه‌ی مزرعه می‌برد.

const FARM_SCENE_PATH: String = "res://src/features/farm/farm.tscn"
const START_HINT_TEXT: String = "برای شروع، صفحه را لمس کن"
const START_HINT_FONT_SIZE: int = 40
const START_HINT_ANCHOR_Y: float = 0.70
const START_HINT_HEIGHT: float = 120.0
const PULSE_ALPHA_MIN: float = 0.3
const PULSE_SECONDS: float = 0.7

var _start_hint: FarsiLabel
var _can_start: bool = false


func _ready() -> void:
    add_child(SkyBackground.new())

    var title := FarsiLabel.new(
        GameConfig.PROJECT_TITLE,
        GameConfig.TITLE_FONT_SIZE,
        GameConfig.INK_COLOR
    )
    title.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(title)

    _start_hint = FarsiLabel.new(
        START_HINT_TEXT,
        START_HINT_FONT_SIZE,
        GameConfig.INK_COLOR
    )
    _start_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
    _start_hint.anchor_top = START_HINT_ANCHOR_Y
    _start_hint.anchor_bottom = START_HINT_ANCHOR_Y
    _start_hint.offset_bottom = START_HINT_HEIGHT
    _start_hint.visible = false
    add_child(_start_hint)

    var started: bool = VoicePlayer.play_line(VoiceKeys.WELCOME)
    if started:
        VoicePlayer.line_finished.connect(_on_voice_line_finished)
    else:
        _show_start_hint()


func _input(event: InputEvent) -> void:
    if not _can_start:
        return
    var is_tap: bool = (
        (event is InputEventMouseButton and event.pressed)
        or (event is InputEventScreenTouch and event.pressed)
    )
    if is_tap:
        get_tree().change_scene_to_file(FARM_SCENE_PATH)


func _on_voice_line_finished() -> void:
    _show_start_hint()


func _show_start_hint() -> void:
    _can_start = true
    _start_hint.visible = true
    var pulse := create_tween().set_loops()
    pulse.tween_property(_start_hint, "modulate:a", PULSE_ALPHA_MIN, PULSE_SECONDS)
    pulse.tween_property(_start_hint, "modulate:a", 1.0, PULSE_SECONDS)
