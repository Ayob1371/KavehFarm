class_name Farm
extends Node2D

## صحنه‌ی مزرعه — دنیای بزرگ با دوربین متحرک، شخصیتِ راه‌رونده،
## طویله‌ی گاو و مرغدانیِ هنوز بسته.
## ورودی: لمس کوتاه = راه رفتن بازیگر؛ کشیدن انگشت = دوربین.
## لمس طویله یا مرغدانی = ایستادن جلوی درِ آن‌ها.
## مأموریت گاو: دوربین خودش به طویله می‌رود و بازیگر دنبالش.

const WORLD_SIZE: Vector2 = Vector2(1440.0, 2560.0)
const GROUND_PATH: String = "res://assets/art/world_ground.png"
const GROUND_SCALE: float = 1.667
const BARN_PATH: String = "res://assets/art/barn.png"
const BARN_SCALE: float = 0.9
const COOP_PATH: String = "res://assets/art/coop.png"
const COOP_SCALE: float = 0.5

const BARN_POSITION: Vector2 = Vector2(1080.0, 520.0)
const COOP_POSITION: Vector2 = Vector2(320.0, 2140.0)
const COW_POSITION: Vector2 = Vector2(1080.0, 760.0)
const PLAYER_START: Vector2 = Vector2(720.0, 1500.0)
const HOME_POSITION: Vector2 = Vector2(720.0, 1500.0)
const BARN_STAND_POSITION: Vector2 = Vector2(830.0, 950.0)
const COOP_STAND_POSITION: Vector2 = Vector2(420.0, 2420.0)
const BARN_FOCUS_POSITION: Vector2 = Vector2(950.0, 850.0)
const FOOD_SPAWN_POSITION: Vector2 = Vector2(830.0, 1050.0)
const FOOD_TEXTURE_PATH: String = "res://assets/art/cow_food.png"
const DROP_SUCCESS_RADIUS: float = 240.0
const BARN_TAP_RADIUS: float = 430.0
const COOP_TAP_RADIUS: float = 340.0
const WALK_MARGIN: float = 80.0
const PAN_THRESHOLD: float = 70.0
const NEXT_HUNGER_SECONDS: float = 8.0

const HOME_BUTTON_RECT: Rect2 = Rect2(24.0, 24.0, 150.0, 84.0)
const HOME_BUTTON_COLOR: Color = Color(1.0, 0.96, 0.86, 0.9)
const HOME_BUTTON_TEXT: String = "خانه"
const HOME_BUTTON_FONT_SIZE: int = 38

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
var _food: FoodItem
var _hunger_timer: Timer
var _voice_queue: Array[String] = []
var _first_mission_done: bool = false
var _pending_food_spawn: bool = false
var _coop_voice_pending: bool = false
var _touch_active: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _panning: bool = false
var _pan_distance: float = 0.0


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


func _build_sprite(path: String, sprite_position: Vector2, sprite_scale: float) -> void:
    var sprite := Sprite2D.new()
    sprite.texture = load(path)
    sprite.scale = Vector2(sprite_scale, sprite_scale)
    sprite.position = sprite_position
    add_child(sprite)


func _build_home_button() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := ColorRect.new()
    panel.color = HOME_BUTTON_COLOR
    panel.position = HOME_BUTTON_RECT.position
    panel.size = HOME_BUTTON_RECT.size
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(panel)
    var label := FarsiLabel.new(
        HOME_BUTTON_TEXT,
        HOME_BUTTON_FONT_SIZE,
        GameConfig.INK_COLOR
    )
    label.set_anchors_preset(Control.PRESET_FULL_RECT)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(label)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        _handle_touch(event)
    elif event is InputEventScreenDrag:
        _handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
    if event.pressed:
        _touch_active = true
        _press_position = event.position
        _panning = false
        _pan_distance = 0.0
    elif _touch_active:
        _touch_active = false
        _finish_gesture()


func _handle_drag(event: InputEventScreenDrag) -> void:
    if not _touch_active:
        return
    _pan_distance += event.relative.length()
    if not _panning and _pan_distance > PAN_THRESHOLD:
        _panning = true
    if _panning and not _is_food_grabbed():
        _camera.pan_by(event.relative)


func _finish_gesture() -> void:
    if not _panning:
        _handle_tap(_press_position)


func _handle_tap(screen_position: Vector2) -> void:
    if HOME_BUTTON_RECT.has_point(screen_position):
        _go_home()
        return
    var world: Vector2 = _screen_to_world(screen_position)
    if _is_food_grabbed() or _is_tap_on_food(world):
        return
    if world.distance_to(COOP_POSITION) <= COOP_TAP_RADIUS:
        _visit_coop()
        return
    if world.distance_to(BARN_POSITION) <= BARN_TAP_RADIUS:
        _player.walk_to(BARN_STAND_POSITION)
    else:
        _player.walk_to(_clamped_walk_target(world))
    _camera.follow_target()


func _start_cow_mission() -> void:
    _camera.focus_on(BARN_FOCUS_POSITION)
    _player.walk_to(BARN_STAND_POSITION)
    _pending_food_spawn = true
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
    if _pending_food_spawn:
        _pending_food_spawn = false
        _spawn_food()
    if _coop_voice_pending:
        _coop_voice_pending = false
        VoicePlayer.play_line(VoiceKeys.COOP_LOCKED_01)


func _spawn_food() -> void:
    _food = FoodItem.new()
    _food.setup(FOOD_TEXTURE_PATH)
    _food.position = FOOD_SPAWN_POSITION
    _food.dropped_at.connect(_on_food_dropped_at)
    add_child(_food)


func _on_food_dropped_at(dropped_position: Vector2) -> void:
    if _food == null or not _cow.is_hungry():
        return
    var mouth: Vector2 = _cow.get_mouth_position()
    if dropped_position.distance_to(mouth) <= DROP_SUCCESS_RADIUS:
        _feed_cow()
    else:
        _food.return_to_spawn(FOOD_SPAWN_POSITION)


func _feed_cow() -> void:
    _voice_queue.clear()
    _food.consume()
    _food = null
    _cow.start_eating()
    var done_index: int = randi() % FEED_DONE_LINES.size()
    VoicePlayer.play_line(FEED_DONE_LINES[done_index])
    _camera.follow_target()
    _hunger_timer.start(NEXT_HUNGER_SECONDS)


func _visit_coop() -> void:
    _coop_voice_pending = true
    _player.walk_to(COOP_STAND_POSITION)
    _camera.follow_target()


func _go_home() -> void:
    _player.walk_to(HOME_POSITION)
    _camera.follow_target()


func _is_food_grabbed() -> bool:
    return _food != null and _food.is_grabbed()


func _is_tap_on_food(world_position: Vector2) -> bool:
    return _food != null and _food.contains_point(world_position)


func _clamped_walk_target(world_position: Vector2) -> Vector2:
    return Vector2(
        clampf(world_position.x, WALK_MARGIN, WORLD_SIZE.x - WALK_MARGIN),
        clampf(world_position.y, WALK_MARGIN, WORLD_SIZE.y - WALK_MARGIN),
    )


func _screen_to_world(screen_position: Vector2) -> Vector2:
    return get_viewport().get_canvas_transform().affine_inverse() * screen_position
