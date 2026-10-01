class_name FoodItem
extends Node2D

## آیتم غذایی کشیدنی — با لمس گرفته می‌شود، جابه‌جا می‌شود و
## محل رها شدن را در مختصات دنیا اعلام می‌کند.
## بافت از بیرون با setup تعیین می‌شود تا هر حیوون غذای خودش
## را داشته باشد: لوبیا برای گاو، سیب‌زمینی برای بز، سیب برای اسب.

signal dropped_at(world_position: Vector2)

const FALLBACK_TEXTURE_PATH: String = "res://assets/art/grass_bundle.png"
const SPRITE_SCALE: float = 0.35
const HIT_RADIUS: float = 110.0
const GRAB_SCALE: float = 1.15
const NORMAL_SCALE: float = 1.0
const RETURN_SECONDS: float = 0.35
const FADE_SECONDS: float = 0.4
const FADE_END_SCALE: float = 0.4

var _texture_path: String = FALLBACK_TEXTURE_PATH
var _sprite: Sprite2D
var _grabbing: bool = false
var _interactive: bool = true
var _active_pointer: int = -1


func _ready() -> void:
    _sprite = Sprite2D.new()
    _sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
    add_child(_sprite)
    _refresh_texture()


## تعیین بافت آیتم؛ اگر فایل نباشد، بافت جایگزین به‌کار می‌رود.
func setup(texture_path: String) -> void:
    _texture_path = texture_path
    if is_inside_tree():
        _refresh_texture()


func _input(event: InputEvent) -> void:
    if not _interactive:
        return
    if event is InputEventScreenTouch:
        _handle_touch(event)
    elif event is InputEventScreenDrag:
        _handle_drag(event)


## آیا این غذا اکنون در دست کودک است؟
func is_grabbed() -> bool:
    return _grabbing


## آیا نقطه‌ای از دنیا روی این غذا افت می‌کند؟
func contains_point(world_position: Vector2) -> bool:
    return global_position.distance_to(world_position) <= HIT_RADIUS


## بازگشت نرم غذا به نقطه‌ی شروع پس از رها شدن ناموفق.
func return_to_spawn(spawn_position: Vector2) -> void:
    var tween := create_tween()
    tween.tween_property(self, "position", spawn_position, RETURN_SECONDS)


## خورده شدن غذا: غیرفعال شدن، محو شدن و پاک شدن از صحنه.
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
    var world: Vector2 = _screen_to_world(event.position)
    if event.pressed:
        if not _grabbing:
            _try_grab(event.index, world)
    elif _grabbing and event.index == _active_pointer:
        _release(world)


func _handle_drag(event: InputEventScreenDrag) -> void:
    if _grabbing and event.index == _active_pointer:
        position = _screen_to_world(event.position)


func _try_grab(pointer: int, world_position: Vector2) -> void:
    if global_position.distance_to(world_position) <= HIT_RADIUS:
        _grabbing = true
        _active_pointer = pointer
        scale = Vector2(GRAB_SCALE, GRAB_SCALE)


func _release(world_position: Vector2) -> void:
    _grabbing = false
    _active_pointer = -1
    scale = Vector2(NORMAL_SCALE, NORMAL_SCALE)
    dropped_at.emit(world_position)


func _refresh_texture() -> void:
    var path: String = _texture_path
    if not ResourceLoader.exists(path):
        path = FALLBACK_TEXTURE_PATH
    _sprite.texture = load(path)


func _screen_to_world(screen_position: Vector2) -> Vector2:
    return get_viewport().get_canvas_transform().affine_inverse() * screen_position
