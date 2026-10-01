class_name PlayerVisual
extends Node2D

## نمایش شخصیت بازیگر: اسپرایت، سایه‌ی نرم، و حرکت بدن
## هنگام راه رفتن (بالا-پایین رفتن و تکان نرم).

const TEXTURE_PATH: String = "res://assets/art/player.png"
const SPRITE_SCALE: float = 0.28
const SPRITE_OFFSET: Vector2 = Vector2(0.0, -60.0)
const SHADOW_RX: float = 52.0
const SHADOW_RY: float = 14.0
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.15)
const ELLIPSE_SEGMENTS: int = 24
const STEP_FREQUENCY: float = 11.0
const STEP_HEIGHT: float = 9.0
const STEP_TILT: float = 0.07

var _sprite: Sprite2D
var _walking: bool = false
var _time: float = 0.0


func _ready() -> void:
    _sprite = Sprite2D.new()
    _sprite.texture = load(TEXTURE_PATH)
    _sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
    _sprite.position = SPRITE_OFFSET
    add_child(_sprite)


func _process(delta: float) -> void:
    if not _walking:
        return
    _time += delta
    _sprite.position.y = (
        SPRITE_OFFSET.y - absf(sin(_time * STEP_FREQUENCY)) * STEP_HEIGHT
    )
    _sprite.rotation = sin(_time * STEP_FREQUENCY) * STEP_TILT


## تنظیم جهت نمایش بر اساس مؤلفه‌ی افقی حرکت.
func face_direction(direction_x: float) -> void:
    if absf(direction_x) > 5.0:
        _sprite.flip_h = direction_x < 0.0


func play_walk() -> void:
    _walking = true


func play_idle() -> void:
    _walking = false
    _sprite.position.y = SPRITE_OFFSET.y
    _sprite.rotation = 0.0


func _draw() -> void:
    _draw_ellipse(Vector2.ZERO, SHADOW_RX, SHADOW_RY, SHADOW_COLOR)


func _draw_ellipse(
        center: Vector2,
        rx: float,
        ry: float,
        color: Color,
) -> void:
    var points := PackedVector2Array()
    points.resize(ELLIPSE_SEGMENTS)
    for i: int in ELLIPSE_SEGMENTS:
        var angle: float = TAU * float(i) / float(ELLIPSE_SEGMENTS)
        points[i] = center + Vector2(cos(angle) * rx, sin(angle) * ry)
    draw_polygon(points, PackedColorArray([color]))
