class_name Farm
extends Control

## صحنه‌ی مزرعه — فاز ۱: سیر کردن گاو.
## چرخه‌ی بازی: گاو گرسنه می‌شود و علف ظاهر می‌شود، کودک علف را
## سمت دهان گاو می‌کشد، گاو می‌خورد و تشویق می‌شود، و بعد از
## یک مکث کوتاه چرخه از نو آغاز می‌شود.

const BACKGROUND_PATH: String = "res://assets/art/farm_background.png"
const COW_POSITION: Vector2 = Vector2(360.0, 760.0)
const GRASS_SPAWN_POSITION: Vector2 = Vector2(360.0, 1120.0)
const DROP_SUCCESS_RADIUS: float = 240.0
const NEXT_HUNGER_SECONDS: float = 8.0
const FEED_DONE_LINES: Array[String] = [
    VoiceKeys.COW_FEED_DONE_01,
    VoiceKeys.COW_FEED_DONE_02,
]

var _cow: Cow
var _grass: Grass
var _hunger_timer: Timer
var _feed_ask_pending: bool = false


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build_background()

    _cow = Cow.new()
    _cow.position = COW_POSITION
    _cow.became_hungry.connect(_on_cow_became_hungry)
    add_child(_cow)

    _hunger_timer = Timer.new()
    _hunger_timer.one_shot = true
    _hunger_timer.timeout.connect(_cow.mark_hungry)
    add_child(_hunger_timer)

    VoicePlayer.line_finished.connect(_on_voice_line_finished)
    _cow.mark_hungry()


func _build_background() -> void:
    var background := TextureRect.new()
    background.texture = load(BACKGROUND_PATH)
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)


func _on_cow_became_hungry() -> void:
    _feed_ask_pending = true
    VoicePlayer.play_line(VoiceKeys.COW_HUNGRY)
    _spawn_grass()


func _on_voice_line_finished() -> void:
    if _feed_ask_pending and _cow.is_hungry():
        _feed_ask_pending = false
        VoicePlayer.play_line(VoiceKeys.COW_FEED_ASK)


func _spawn_grass() -> void:
    _grass = Grass.new()
    _grass.position = GRASS_SPAWN_POSITION
    _grass.dropped_at.connect(_on_grass_dropped_at)
    add_child(_grass)


func _on_grass_dropped_at(dropped_position: Vector2) -> void:
    if _grass == null or not _cow.is_hungry():
        return
    var mouth: Vector2 = _cow.get_mouth_position()
    if dropped_position.distance_to(mouth) <= DROP_SUCCESS_RADIUS:
        _feed_cow()
    else:
        _grass.return_to_spawn(GRASS_SPAWN_POSITION)


func _feed_cow() -> void:
    _grass.consume()
    _grass = null
    _cow.start_eating()
    var done_index: int = randi() % FEED_DONE_LINES.size()
    VoicePlayer.play_line(FEED_DONE_LINES[done_index])
    _hunger_timer.start(NEXT_HUNGER_SECONDS)
