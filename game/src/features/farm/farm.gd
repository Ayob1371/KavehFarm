class_name Farm
extends Node2D

## صحنه‌ی مزرعه — دنیای بزرگ با دوربین متحرک، شخصیتِ راه‌رونده،
## طویله‌ی گاو و مرغدانیِ هنوز بسته.
## ورودی: لمس کوتاه = راه رفتن بازیگر؛ کشیدن انگشت = دوربین.
## مأموریت گاو: دوربین خودش به طویله می‌رود و بازیگر دنبالش.

const WORLD_SIZE: Vector2 = Vector2(1440.0, 2560.0)
const GROUND_PATH: String = "res://assets/art/world_ground.png"
const GROUND_SCALE: float = 1.667
const BARN_PATH: String = "res://assets/art/barn.png"
const BARN_SCALE: float = 0.6
const COOP_PATH: String = "res://assets/art/coop.png"
const COOP_SCALE: float = 0.5

const BARN_POSITION: Vector2 = Vector2(1100.0, 500.0)
const COOP_POSITION: Vector2 = Vector2(320.0, 2140.0)
const COW_POSITION: Vector2 = Vector2(1120.0, 760.0)
const PLAYER_START: Vector2 = Vector2(720.0, 1500.0)
const HOME_POSITION: Vector2 = Vector2(720.0, 1500.0)
const BARN_STAND_POSITION: Vector2 = Vector2(820.0, 900.0)
const COOP_STAND_POSITION: Vector2 = Vector2(520.0, 2290.0)
const BARN_FOCUS_POSITION: Vector2 = Vector2(980.0, 860.0)
const GRASS_SPAWN_POSITION: Vector2 = Vector2(820.0, 1080.0)
const DROP_SUCCESS_RADIUS: float = 240.0
const COOP_TAP_RADIUS: float = 340.0
const WALK_MARGIN: float = 80.0
const PAN_THRESHOLD: float = 26.0
const NEXT_HUNGER_SECONDS: float = 8.0

const HOME_BUTTON_TEXT: String = "خانه"
const HOME_BUTTON_POSITION: Vector2 = Vector2(24.0, 24.0)
const HOME_BUTTON_SIZE: Vector2 = Vector2(150.0, 84.0)
const HOME_BUTTON_FONT_SIZE: int = 34

const FIRST_MISSION_LINES: Array[String] = [
    VoiceKeys.COW_HUNGRY,
    VoiceKeys.GOTO_BARN_01,
    VoiceKeys.COW_FEED_ASK,
]
const LATER_MISSION_LINES: Array[String] = [VoiceKeys.COW_HUNGRY]
const FEED_DONE_LINES: Array[String] = [
    VoiceKeys.COW_FEED_DONE_01,
    VoiceKeys.COW_FEED_DONE_02,
]

var _camera: CameraRig
var _player: Player
var _cow: Cow
var _grass: Grass
var _hunger_timer: Timer
var _voice_queue: Array[String] = []
var _first_mission_done: bool = false
var _pending_grass_spawn: bool = false
var _coop_voice_pending: bool = false
var _touch_index: int = -1
var _press_position: Vector2 = Vector2.ZERO
var _panning: bool = false
var _pan_distance: float = 0.0
var _mouse_down: bool = false


func _ready() -> void:
    _build_ground()
    _build_sprite(BARN_PATH, BARN_POSITION, BARN_SCALE)
    _build_sprite(COOP_PATH, COOP_POSITION, COOP_SCALE)

    _cow = Cow.new()
    _cow.position = COW_POSITION
    _cow.became_hungry.connect(_on_cow_became_hungry)
    add_child(_cow)

    _player = Player.new()
    _player.position = PLAYER_START
    _player.arrived.connect(_on_player_arrived)
    add_child(_player)

    _camera = CameraRig.new()
    add_child(_camera)
    _camera.setup(_player, Rect2(Vector2.ZERO, WORLD_SIZE))

    _hunger_timer = Timer.new()
    _hunger_timer.one_shot = true
    _hunger_timer.timeout.connect(_cow.mark_hungry)
    add_child(_hunger_timer)

    VoicePlayer.line_finished.connect(_on_voice_line_finished)
    _build_home_button()
    _cow.mark_hungry()


func _build_ground() -> void:
    var ground := Sprite2D.new()
    ground.texture = load(GROUND_PATH)
    ground.scale = Vector2(GROUND_SCALE, GROUND_SCALE)
    ground.position = WORLD_SIZE / 2.0
    add_child(ground)


func _build_sprite(path: String, position_: Vector2, scale_: float) -> void:
    var sprite := Sprite2D.new()
    sprite.texture = load(path)
    sprite.scale = Vector2(scale_, scale_)
    sprite.position = position_
    add_child(sprite)


func _build_home_button() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var button := Button.new()
    button.text = HOME_BUTTON_TEXT
    button.add_theme_font_override("font", load(GameConfig.FONT_PATH))
    button.add_theme_font_size_override("font_size", HOME_BUTTON_FONT_SIZE)
    button.position = HOME_BUTTON_POSITION
    button.size = HOME_BUTTON_SIZE
    button.pressed.connect(_on_home_pressed)
    layer.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        _handle_touch(event)
    elif event is InputEventScreenDrag:
        _handle_drag(event)
    elif event is InputEventMouseButton:
        _handle_mouse_button(event)
    elif event is InputEventMouseMotion:
        _handle_mouse_motion(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
    if event.pressed:
        if _touch_index == -1:
            _touch_index = event.index
            _press_position = event.position
            _panning = false
            _pan_distance = 0.0
    elif event.index == _touch_index:
        _finish_gesture(event.position)


func _handle_drag(event: InputEventScreenDrag) -> void:
    if event.index != _touch_index:
        return
    _pan_distance += event.relative.length()
    if not _panning and _pan_distance > PAN_THRESHOLD:
        _panning = true
    if _panning and not _is_grass_grabbed():
        _camera.pan_by(event.relative)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
    if event.button_index != MOUSE_BUTTON_LEFT:
        return
    if event.pressed:
        _mouse_down = true
        _press_position = event.position
        _panning = false
        _pan_distance = 0.0
    elif _mouse_down:
        _mouse_down = false
        _finish_gesture(event.position)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
    if not _mouse_down:
        return
    _pan_distance += event.relative.length()
    if not _panning and _pan_distance > PAN_THRESHOLD:
        _panning = true
    if _panning and not _is_grass_grabbed():
        _camera.pan_by(event.relative)


func _finish_gesture(release_position: Vector2) -> void:
    var was_tap: bool = not _panning
    _touch_index = -1
    _panning = false
    if not was_tap:
        return
    var world: Vector2 = _screen_to_world(_press_position)
    if _is_grass_grabbed() or _is_tap_on_grass(world):
        return
    if world.distance_to(COOP_POSITION) <= COOP_TAP_RADIUS:
        _visit_coop()
        return
    _player.walk_to(_clamped_walk_target(world))
    _camera.follow_target()


func _start_cow_mission() -> void:
    _camera.focus_on(BARN_FOCUS_POSITION)
    _player.walk_to(BARN_STAND_POSITION)
    _pending_grass_spawn = true
    var lines: Array[String] = (
        FIRST_MISSION_LINES if not _first_mission_done else LATER_MISSION_LINES
    )
    _first_mission_done = true
    _voice_queue.assign(lines.slice(1))
    VoicePlayer.play_line(lines[0])


func _on_cow_became_hungry() -> void:
    _start_cow_mission()


func _on_voice_line_finished() -> void:
    if not _voice_queue.is_empty():
        VoicePlayer.play_line(_voice_queue.pop_front())


func _on_player_arrived() -> void:
    if _pending_grass_spawn:
        _pending_grass_spawn = false
        _spawn_grass()
    if _coop_voice_pending:
        _coop_voice_pending = false
        VoicePlayer.play_line(VoiceKeys.COOP_LOCKED_01)


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
    _voice_queue.clear()
    _grass.consume()
    _grass = null
    _cow.start_eating()
    var done_index: int = randi() % FEED_DONE_LINES.size()
    VoicePlayer.play_line(FEED_DONE_LINES[done_index])
    _camera.follow_target()
    _hunger_timer.start(NEXT_HUNGER_SECONDS)


func _visit_coop() -> void:
    _coop_voice_pending = true
    _player.walk_to(COOP_STAND_POSITION)
    _camera.follow_target()


func _on_home_pressed() -> void:
    _player.walk_to(HOME_POSITION)
    _camera.follow_target()


func _is_grass_grabbed() -> bool:
    return _grass != null and _grass.is_grabbed()


func _is_tap_on_grass(world_position: Vector2) -> bool:
    return _grass != null and _grass.contains_point(world_position)


func _clamped_walk_target(world_position: Vector2) -> Vector2:
    return Vector2(
        clampf(world_position.x, WALK_MARGIN, WORLD_SIZE.x - WALK_MARGIN),
        clampf(world_position.y, WALK_MARGIN, WORLD_SIZE.y - WALK_MARGIN),
    )


func _screen_to_world(screen_position: Vector2) -> Vector2:
    return get_viewport().get_canvas_transform().affine_inverse() * screen_position
