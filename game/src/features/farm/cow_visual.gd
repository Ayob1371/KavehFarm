class_name CowVisual
extends Node2D

## نمایش رویه‌ای گاو: بدن، لکه‌ها، پاها، دم و سرِ متحرک.
## کل ظاهر گاو همین فایل است؛ جایگزینی با اسپرایت واقعی
## فقط همین ماژول را تغییر می‌دهد و منطق دست‌نخورده می‌ماند.

const BODY_COLOR: Color = Color(0.97, 0.96, 0.93)
const SPOT_COLOR: Color = Color(0.55, 0.37, 0.26)
const HOOF_COLOR: Color = Color(0.30, 0.24, 0.20)
const SNOUT_COLOR: Color = Color(0.95, 0.73, 0.76)
const HORN_COLOR: Color = Color(0.90, 0.84, 0.62)
const INNER_EAR_COLOR: Color = Color(0.93, 0.78, 0.80)
const EYE_COLOR: Color = Color(0.12, 0.10, 0.10)
const NOSE_COLOR: Color = Color(0.62, 0.40, 0.45)

const BODY_RX: float = 170.0
const BODY_RY: float = 110.0
const LEG_WIDTH: float = 34.0
const LEG_HEIGHT: float = 80.0
const LEG_HOOF_HEIGHT: float = 18.0
const LEG_TOP_Y: float = 70.0
const LEG_XS: Array[float] = [-130.0, -52.0, 44.0, 122.0]
const TAIL_PIVOT: Vector2 = Vector2(-162.0, -46.0)
const TAIL_LENGTH: float = 105.0
const TAIL_THICKNESS: float = 10.0
const TAIL_TUFT_RADIUS: float = 12.0
const HEAD_POSITION: Vector2 = Vector2(150.0, -10.0)
const HEAD_RADIUS: float = 64.0
const EAR_OFFSET: Vector2 = Vector2(58.0, -34.0)
const EAR_RX: float = 24.0
const EAR_RY: float = 14.0
const INNER_EAR_RX: float = 12.0
const INNER_EAR_RY: float = 7.0
const HORN_OFFSET: Vector2 = Vector2(24.0, -64.0)
const HORN_RX: float = 10.0
const HORN_RY: float = 18.0
const SNOUT_CENTER: Vector2 = Vector2(20.0, 34.0)
const SNOUT_RX: float = 42.0
const SNOUT_RY: float = 27.0
const NOSTRIL_OFFSET: float = 14.0
const NOSTRIL_RADIUS: float = 5.0
const EYE_OFFSET: Vector2 = Vector2(20.0, -14.0)
const EYE_RADIUS: float = 6.0
const SPOT_1: Vector2 = Vector2(-58.0, -34.0)
const SPOT_1_RX: float = 48.0
const SPOT_1_RY: float = 32.0
const SPOT_2: Vector2 = Vector2(42.0, 24.0)
const SPOT_2_RX: float = 38.0
const SPOT_2_RY: float = 26.0
const SPOT_3: Vector2 = Vector2(96.0, -46.0)
const SPOT_3_RX: float = 30.0
const SPOT_3_RY: float = 20.0
const EAT_BOB: float = 34.0
const EAT_CYCLES: int = 2
const EAT_SECONDS: float = 1.8
const HOP_HEIGHT: float = 26.0
const HOP_COUNT: int = 2
const HOP_SECONDS: float = 1.4
const TAIL_WAG_SECONDS: float = 0.45
const TAIL_WAG_MAX_DEGREES: float = 18.0
const ELLIPSE_SEGMENTS: int = 32

var _head: Node2D
var _tail: Node2D
var _tail_time: float = 0.0


func _ready() -> void:
    _tail = Node2D.new()
    _tail.position = TAIL_PIVOT
    _tail.draw.connect(_on_tail_draw)
    add_child(_tail)

    _head = Node2D.new()
    _head.position = HEAD_POSITION
    _head.draw.connect(_on_head_draw)
    add_child(_head)


func _process(delta: float) -> void:
    _tail_time += delta
    _tail.rotation = deg_to_rad(
        sin(_tail_time / TAIL_WAG_SECONDS * TAU) * TAIL_WAG_MAX_DEGREES
    )


func _draw() -> void:
    for leg_x: float in LEG_XS:
        draw_rect(
            Rect2(leg_x - LEG_WIDTH / 2.0, LEG_TOP_Y, LEG_WIDTH, LEG_HEIGHT),
            BODY_COLOR,
        )
        draw_rect(
            Rect2(
                leg_x - LEG_WIDTH / 2.0,
                LEG_TOP_Y + LEG_HEIGHT,
                LEG_WIDTH,
                LEG_HOOF_HEIGHT,
            ),
            HOOF_COLOR,
        )
    _draw_ellipse(self, Vector2.ZERO, BODY_RX, BODY_RY, BODY_COLOR)
    _draw_ellipse(self, SPOT_1, SPOT_1_RX, SPOT_1_RY, SPOT_COLOR)
    _draw_ellipse(self, SPOT_2, SPOT_2_RX, SPOT_2_RY, SPOT_COLOR)
    _draw_ellipse(self, SPOT_3, SPOT_3_RX, SPOT_3_RY, SPOT_COLOR)


func _on_head_draw() -> void:
    _draw_ellipse(_head, -EAR_OFFSET, EAR_RX, EAR_RY, BODY_COLOR)
    _draw_ellipse(_head, EAR_OFFSET, EAR_RX, EAR_RY, BODY_COLOR)
    _draw_ellipse(_head, -EAR_OFFSET, INNER_EAR_RX, INNER_EAR_RY, INNER_EAR_COLOR)
    _draw_ellipse(_head, EAR_OFFSET, INNER_EAR_RX, INNER_EAR_RY, INNER_EAR_COLOR)
    _draw_ellipse(_head, -HORN_OFFSET, HORN_RX, HORN_RY, HORN_COLOR)
    _draw_ellipse(_head, HORN_OFFSET, HORN_RX, HORN_RY, HORN_COLOR)
    _head.draw_circle(Vector2.ZERO, HEAD_RADIUS, BODY_COLOR)
    _draw_ellipse(_head, SNOUT_CENTER, SNOUT_RX, SNOUT_RY, SNOUT_COLOR)
    _head.draw_circle(
        SNOUT_CENTER + Vector2(-NOSTRIL_OFFSET, 0.0), NOSTRIL_RADIUS, NOSE_COLOR
    )
    _head.draw_circle(
        SNOUT_CENTER + Vector2(NOSTRIL_OFFSET, 0.0), NOSTRIL_RADIUS, NOSE_COLOR
    )
    _head.draw_circle(-EYE_OFFSET, EYE_RADIUS, EYE_COLOR)
    _head.draw_circle(EYE_OFFSET, EYE_RADIUS, EYE_COLOR)


func _on_tail_draw() -> void:
    _tail.draw_line(
        Vector2.ZERO,
        Vector2(-14.0, TAIL_LENGTH),
        BODY_COLOR,
        TAIL_THICKNESS,
    )
    _tail.draw_circle(Vector2(-14.0, TAIL_LENGTH), TAIL_TUFT_RADIUS, HOOF_COLOR)


## انیمیشن جویدن: پایین و بالا رفتن سر، دو بار.
func play_eating() -> void:
    var tween := create_tween()
    var half: float = EAT_SECONDS / float(EAT_CYCLES * 2)
    for _cycle: int in EAT_CYCLES:
        tween.tween_property(_head, "position:y", HEAD_POSITION.y + EAT_BOB, half)
        tween.tween_property(_head, "position:y", HEAD_POSITION.y, half)


## انیمیشن خوشحالی: دو بار جست‌وخیز.
func play_happy() -> void:
    var tween := create_tween()
    var half: float = HOP_SECONDS / float(HOP_COUNT * 2)
    for _cycle: int in HOP_COUNT:
        tween.tween_property(self, "position:y", -HOP_HEIGHT, half)
        tween.tween_property(self, "position:y", 0.0, half)


func _draw_ellipse(
        target: CanvasItem,
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
    target.draw_polygon(points, PackedColorArray([color]))
