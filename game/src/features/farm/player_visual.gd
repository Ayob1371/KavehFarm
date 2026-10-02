class_name PlayerVisual
extends Node2D

## نمایش شخصیت بازیگر: اسپرایت، سایه، و دو پای متحرک زیر بدن
## تا راه رفتن واقعاً «قدم زدن» دیده شود، نه پرش.

const TEXTURE_PATH: String = "res://assets/art/player.png"
const SPRITE_SCALE: float = 0.16
const SPRITE_OFFSET: Vector2 = Vector2(0.0, -100.0)
const SHADOW_RX: float = 45.0
const SHADOW_RY: float = 12.0
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.15)
const ELLIPSE_SEGMENTS: int = 24
const BOUNCE_HEIGHT: float = 6.0
const BOUNCE_FREQUENCY: float = 8.0
const LEG_COLOR: Color = Color(0.35, 0.45, 0.75)
const LEG_RADIUS: float = 11.0
const LEG_CENTER_X: float = 16.0
const LEG_LIFT: float = 14.0
const LEG_BASE_Y: float = -12.0

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
        SPRITE_OFFSET.y - absf(sin(_time * BOUNCE_FREQUENCY)) * BOUNCE_HEIGHT
    )
    queue_redraw()


func _draw() -> void:
    _draw_ellipse(Vector2.ZERO, SHADOW_RX, SHADOW_RY, SHADOW_COLOR)
    if _walking:
        _draw_walking_legs()
    else:
        _draw_standing_legs()


## تنظیم جهت نمایش بر اساس مؤلفه‌ی افقی حرکت.
func face_direction(direction_x: float) -> void:
    if absf(direction_x) > 5.0:
        _sprite.flip_h = direction_x < 0.0


func play_walk() -> void:
    if not _walking:
        _walking = true
        _time = 0.0
        queue_redraw()


func play_idle() -> void:
    _walking = false
    _sprite.position.y = SPRITE_OFFSET.y
    _sprite.rotation = 0.0
    queue_redraw()


func _draw_standing_legs() -> void:
    _draw_leg(Vector2(-LEG_CENTER_X, LEG_BASE_Y))
    _draw_leg(Vector2(LEG_CENTER_X, LEG_BASE_Y))


func _draw_walking_legs() -> void:
    var phase: float = sin(_time * BOUNCE_FREQUENCY * 2.0)
    _draw_leg(Vector2(-LEG_CENTER_X + phase * LEG_LIFT * 0.5, LEG_BASE_Y - maxf(phase, 0.0) * LEG_LIFT))
    _draw_leg(Vector2(LEG_CENTER_X - phase * LEG_LIFT * 0.5, LEG_BASE_Y - maxf(-phase, 0.0) * LEG_LIFT))


func _draw_leg(center: Vector2) -> void:
    draw_circle(center, LEG_RADIUS, LEG_COLOR)


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
