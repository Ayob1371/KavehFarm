extends Node

## پخش‌کننده‌ی سراسری خطوط گفتار.
## به‌صورت autoload با نام VoicePlayer ثبت شده است؛
## صحنه‌ها فقط با کلید صدا درخواست می‌دهند و این نود
## بارگذاری، پخش و تکرار را مدیریت می‌کند.

signal line_finished

const AUDIO_EXTENSION: String = ".wav"

var _audio_player: AudioStreamPlayer
var _last_key: String = ""


func _ready() -> void:
    _audio_player = AudioStreamPlayer.new()
    _audio_player.finished.connect(_on_audio_finished)
    add_child(_audio_player)


## پخش یک خط گفتار با کلید آن؛ اگر فایل موجود نباشد false برمی‌گرداند.
func play_line(key: String) -> bool:
    var path: String = "%s/%s%s" % [GameConfig.VOICE_DIR, key, AUDIO_EXTENSION]
    if not ResourceLoader.exists(path):
        push_warning("VoicePlayer: فایل صدا پیدا نشد: %s" % path)
        return false
    _last_key = key
    _audio_player.stream = load(path)
    _audio_player.play()
    return true


## پخش دوباره‌ی آخرین خط؛ برای لمس صفحه توسط کودک.
func replay_last() -> bool:
    if _last_key.is_empty():
        return false
    return play_line(_last_key)


## توقف فوری پخش.
func stop() -> void:
    _audio_player.stop()


func _on_audio_finished() -> void:
    line_finished.emit()
