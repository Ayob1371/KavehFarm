class_name Cow
extends Control

## گاو — منطق حالت‌ها: سیر، گرسنه، در حال خوردن.
## نمایش و انیمیشن به CowVisual سپرده شده است.

signal became_hungry

enum State { SATISFIED, HUNGRY, EATING }

const MOUTH_OFFSET: Vector2 = Vector2(-90.0, 10.0)
const EAT_SECONDS: float = 1.8

var _state: State = State.SATISFIED
var _visual: CowVisual


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _visual = CowVisual.new()
    add_child(_visual)


## ورود به حالت گرسنه و اعلام آن برای صحنه.
func mark_hungry() -> void:
    if _state != State.SATISFIED:
        return
    _state = State.HUNGRY
    became_hungry.emit()


## خوردن غذا: انیمیشن جویدن و بازگشت به حالت سیر.
func start_eating() -> void:
    _state = State.EATING
    _visual.play_eating()
    get_tree().create_timer(EAT_SECONDS).timeout.connect(_on_finished_eating)


## آیا گاو منتظر غذا است؟
func is_hungry() -> bool:
    return _state == State.HUNGRY


## مختصات جهانی دهان برای بررسی محل رها کردن غذا.
func get_mouth_position() -> Vector2:
    return global_position + MOUTH_OFFSET


func _on_finished_eating() -> void:
    _state = State.SATISFIED
    _visual.play_happy()
