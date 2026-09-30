class_name Grass
extends Node2D

## علف کشیدنی — با لمس گرفته می‌شود، با کشیدن جابه‌جا می‌شود
## و با رها کردن، مکان رها شدن را اعلام می‌کند.
## چند لمس هم‌زمان پشتیبانی می‌شود تا دست کودک خطا نیندازد.

signal dropped_at(position: Vector2)

const TEXTURE_PATH: String = "res://assets/art/grass_bundle.png"
const SPRITE_SCALE: float = 0.35
const MOUSE_POINTER: int = -1
const HIT_RADIUS: float = 110.0
const GRAB_SCALE: float = 1.15
const NORMAL_SCALE: float = 1.0
const RETURN_SECONDS: float = 0.35
const FADE_SECONDS: float = 0.4
const FADE_END_SCALE: float = 0.4

var _sprite: Sprite2D
var _grabbing: bool = false
var _interactive: bool = true
var _active_pointer: int = MOUSE_POINTER


func _ready() -> void:
    _sprite = Sprite2D.new()
    _sprite.texture = load(TEXTURE_PATH)
    _sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
    add_child(_sprite)


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
