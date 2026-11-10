extends Control

@onready var prompt_label: Label = $PromptLabel
@onready var crosshair: ColorRect = $Crosshair
@onready var notification_label: Label = $NotificationBanner/Label
@onready var notification_banner: PanelContainer = $NotificationBanner

var _notif_tween: Tween = null

func _ready():
	prompt_label.text = ""
	prompt_label.visible = false
	notification_banner.modulate.a = 0.0
	notification_banner.visible = false
	GameManager.interaction_prompt_changed.connect(_on_prompt_changed)
	GameManager.interaction_prompt_cleared.connect(_on_prompt_cleared)
	GameManager.notification_requested.connect(_on_notification_requested)

func _on_prompt_changed(text: String):
	prompt_label.text = text
	prompt_label.visible = true

func _on_prompt_cleared():
	prompt_label.text = ""
	prompt_label.visible = false

func _on_notification_requested(msg: String):
	notification_label.text = msg
	notification_banner.visible = true
	if _notif_tween:
		_notif_tween.kill()
	_notif_tween = create_tween()
	_notif_tween.tween_property(notification_banner, "modulate:a", 1.0, 0.25)
	_notif_tween.tween_interval(2.6)
	_notif_tween.tween_property(notification_banner, "modulate:a", 0.0, 0.45)
	_notif_tween.finished.connect(func(): notification_banner.visible = false)
