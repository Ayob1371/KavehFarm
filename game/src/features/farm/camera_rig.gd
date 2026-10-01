class_name CameraRig
extends Camera2D

## دوربین صحنه‌ی مزرعه — سه حالت: دنبال‌کردن بازیگر،
## جابه‌جایی با کشیدن انگشت، و پرش نرم به نقطه‌ی هدف.
## همیشه داخل مرزهای دنیا محدود می‌ماند تا بیرون مزرعه دیده نشود.

enum Mode { FOLLOW, FREE, FOCUSING }

const FOLLOW_SMOOTHING: float = 6.0
const FOCUS_SECONDS: float = 0.9

var _mode: Mode = Mode.FOLLOW
var _target: Node2D
var _world_rect: Rect2
var _focus_tween: Tween


func setup(target: Node2D, world_rect: Rect2) -> void:
    _target = target
    _world_rect = world_rect
    position = _clamped(target.global_position)
    make_current()


func _process(delta: float) -> void:
    if _mode == Mode.FOLLOW and _target != null:
        var smoothed: Vector2 = position.lerp(
            _target.global_position,
            1.0 - exp(-FOLLOW_SMOOTHING * delta),
        )
        position = _clamped(smoothed)


## جابه‌جایی دوربین با کشیدن انگشت (دلتای مختصات صفحه).
func pan_by(screen_delta: Vector2) -> void:
    _stop_focus()
    _mode = Mode.FREE
    position = _clamped(position - screen_delta)


## پرش نرم به یک نقطه از دنیا (مثلاً سمت طویله در مأموریت).
func focus_on(world_position: Vector2) -> void:
    _stop_focus()
    _mode = Mode.FOCUSING
    _focus_tween = create_tween()
    _focus_tween.tween_property(
        self, "position", _clamped(world_position), FOCUS_SECONDS
    )


## بازگشت به حالت دنبال‌کردن بازیگر.
func follow_target() -> void:
    _stop_focus()
    _mode = Mode.FOLLOW


func _stop_focus() -> void:
    if _focus_tween != null and _focus_tween.is_valid():
        _focus_tween.kill()


func _clamped(world_position: Vector2) -> Vector2:
    var half: Vector2 = get_viewport_rect().size * 0.5
    return Vector2(
        clampf(
            world_position.x,
            _world_rect.position.x + half.x,
            _world_rect.end.x - half.x,
        ),
        clampf(
            world_position.y,
            _world_rect.position.y + half.y,
            _world_rect.end.y - half.y,
        ),
    )
