class_name CowVisual
extends Node2D

## نمایش گاو با اسپرایت نقاشی‌شده و سایه‌ی نرم.
## کل ظاهر گاو همین فایل است؛ منطق در «cow.gd» جدا مانده است.

const TEXTURE_PATH: String = "res://assets/art/cow.png"
const SPRITE_SCALE: float = 0.2
const SHADOW_OFFSET: Vector2 = Vector2(0.0, 95.0)
const SHADOW_RX: float = 130.0
const SHADOW_RY: float = 26.0
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.15)
const ELLIPSE_SEGMENTS: int = 32
const EAT_DIP: float = 30.0
const EAT_CYCLES: int = 2
const EAT_SECONDS: float = 1.8
const HOP_HEIGHT: float = 26.0
const HOP_COUNT: int = 2
const HOP_SECONDS: float = 1.4
const SQUASH_X: float = 1.1
const SQUASH_Y: float = 0.9

var _sprite: Sprite2D


func _ready() -> void:
    _sprite = Sprite2D.new()
    _sprite.texture = load(TEXTURE_PATH)
    _sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
    add_child(_sprite)


func _draw() -> void:
    _draw_ellipse(SHADOW_OFFSET, SHADOW_RX, SHADOW_RY, SHADOW_COLOR)


## انیمیشن جویدن: تعظیم — پایین و بالا رفتن بدن، دو بار.
func play_eating() -> void:
    var tween := create_tween()
    var half: float = EAT_SECONDS / float(EAT_CYCLES * 2)
    for _cycle: int in EAT_CYCLES:
        tween.tween_property(self, "position:y", EAT_DIP, half)
        tween.tween_property(self, "position:y", 0.0, half)


## انیمیشن خوشحالی: جست‌وخیز همراه با squash و stretch.
func play_happy() -> void:
    var tween := create_tween()
    var half: float = HOP_SECONDS / float(HOP_COUNT * 2)
    for _cycle: int in HOP_COUNT:
        tween.tween_property(self, "position:y", -HOP_HEIGHT, half)
        tween.parallel().tween_property(
            _sprite,
            "scale",
            Vector2(SPRITE_SCALE * SQUASH_X, SPRITE_SCALE * SQUASH_Y),
            half,
        )
        tween.tween_property(self, "position:y", 0.0, half)
        tween.parallel().tween_property(
            _sprite,
            "scale",
            Vector2(SPRITE_SCALE, SPRITE_SCALE),
            half,
        )


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
