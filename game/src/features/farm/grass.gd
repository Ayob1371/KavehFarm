class_name Grass
extends Node2D

## علف کشیدنی — با لمس گرفته می‌شود، با کشیدن جابه‌جا می‌شود
## و با رها کردن، مکان رها شدن را اعلام می‌کند.
## چند لمس هم‌زمان پشتیبانی می‌شود تا دست کودک خطا نیندازد.

signal dropped_at(position: Vector2)

const MOUSE_POINTER: int = -1
const BLADE_COLOR: Color = Color(0.22, 0.58, 0.22)
const BASE_COLOR: Color = Color(0.16, 0.42, 0.16)
const HIT_RADIUS: float = 110.0
const GRAB_SCALE: float = 1.15
const NORMAL_SCALE: float = 1.0
const RETURN_SECONDS: float = 0.35
const FADE_SECONDS: float = 0.4
const FADE_END_SCALE: float = 0.4
const BASE_RADIUS: float = 26.0
const BLADE_1: Vector3 = Vector3(-38.0, 18.0, 80.0)
const BLADE_2: Vector3 = Vector3(0.0, 20.0, 105.0)
const BLADE_3: Vector3 = Vector3(38.0, 18.0, 75.0)

var _grabbing: bool = false
var _interactive: bool = true
var _active_pointer: int = MOUSE_POINTER


func _ready() -> void:
    scale = Vector2(NORMAL_SCALE, NORMAL_SCALE)


func _draw() -> void:
    _draw_blade(BLADE_1)
    _draw_blade(BLADE_2)
    _draw_blade(BLADE_3)
    draw_circle(Vector2.ZERO, BASE_RADIUS, BASE_COLOR)


func _input(event: InputEvent) -> void:
    if not _interactive:
        return
    if event is InputEventScreenTouch:
        _handle_touch(event)
    elif event is InputEventScreenDrag:
        _handle_drag(event)
    elif event is InputEventMouseButton:
        _handle_mouse_button(event)
    elif event is InputEventMouseMotion:
        _handle_mouse_motion(event)


## بازگشت نرم علف به نقطه‌ی شروع پس از رها شدن ناموفق.
func return_to_spawn(spawn_position: Vector2) -> void:
    var tween := create_tween()
    tween.tween_property(self, "position", spawn_position, RETURN_SECONDS)


## خورده شدن علف: غیرفعال شدن، محو شدن و پاک شدن از صحنه.
func consume() -> void:
    _interactive = false
    var tween := create_tween()
    tween.set_parallel()
    tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
    tween.tween_property(
        self,
        "scale",
        Vector2(FADE_END_SCALE, FADE_END_SCALE),
        FADE_SECONDS,
    )
    tween.chain().tween_callback(queue_free)


func _handle_touch(event: InputEventScreenTouch) -> void:
    if event.pressed:
        if not _grabbing:
            _try_grab(event.index, event.position)
    elif _grabbing and event.index == _active_pointer:
        _release(event.position)


func _handle_drag(event: InputEventScreenDrag) -> void:
    if _grabbing and event.index == _active_pointer:
        position = event.position


func _handle_mouse_button(event: InputEventMouseButton) -> void:
    if event.button_index != MOUSE_BUTTON_LEFT:
        return
    if event.pressed:
        if not _grabbing:
            _try_grab(MOUSE_POINTER, event.position)
    elif _grabbing and _active_pointer == MOUSE_POINTER:
        _release(event.position)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
    if _grabbing and _active_pointer == MOUSE_POINTER:
        position = event.position


func _try_grab(pointer: int, touch_position: Vector2) -> void:
    if global_position.distance_to(touch_position) <= HIT_RADIUS:
        _grabbing = true
        _active_pointer = pointer
        scale = Vector2(GRAB_SCALE, GRAB_SCALE)


func _release(touch_position: Vector2) -> void:
    _grabbing = false
    _active_pointer = MOUSE_POINTER
    scale = Vector2(NORMAL_SCALE, NORMAL_SCALE)
    dropped_at.emit(touch_position)


func _draw_blade(blade: Vector3) -> void:
    ## اجزای Vector3: x = مرکز تیغه، y = پهنا، z = ارتفاع.
    var points := PackedVector2Array([
        Vector2(blade.x - blade.y / 2.0, 0.0),
        Vector2(blade.x + blade.y / 2.0, 0.0),
        Vector2(blade.x, -blade.z),
    ])
    draw_polygon(points, PackedColorArray([BLADE_COLOR]))
