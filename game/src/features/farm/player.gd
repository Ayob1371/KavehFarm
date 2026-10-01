class_name Player
extends Node2D

## شخصیت بازیگر — با walk_to به نقطه‌ی مقصد راه می‌رود،
## جهت خود را تنظیم می‌کند و پس از رسیدن، arrived را اعلام می‌کند.

signal arrived

const SPEED: float = 230.0
const STOP_DISTANCE: float = 12.0

var _target: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _visual: PlayerVisual


func _ready() -> void:
    _visual = PlayerVisual.new()
    add_child(_visual)


## شروع راه‌رفتن به سمت نقطه‌ی مقصد در مختصات دنیا.
func walk_to(world_position: Vector2) -> void:
    _target = world_position
    _has_target = true
    _visual.play_walk()


## آیا بازیگر در حال راه رفتن است؟
func is_moving() -> bool:
    return _has_target


func _process(delta: float) -> void:
    if not _has_target:
        return
    var to_target: Vector2 = _target - position
    if to_target.length() <= STOP_DISTANCE:
        _has_target = false
        _visual.play_idle()
        arrived.emit()
        return
    position += to_target.normalized() * SPEED * delta
    _visual.face_direction(to_target.x)
