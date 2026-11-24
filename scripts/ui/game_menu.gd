extends CanvasLayer

const PAPER := Color("#e8dcc1")
const GOLD := Color("#d8b77a")
const MUTED := Color("#a9a998")

var in_game := false
@export var backdrop: Texture2D
var _contents: VBoxContainer
var _title: Label
var _confirmation: Callable

func _ready() -> void:
	var screen := Control.new()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.theme = _menu_theme()

	if not in_game and backdrop:
		var photo := TextureRect.new()
		screen.add_child(photo)
		photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		photo.texture = backdrop
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := TextureRect.new()
	screen.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.texture = _shade_texture()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var scroll := ScrollContainer.new()
	screen.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if not in_game:
		scroll.anchor_left = 0.045
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var rail := MarginContainer.new()
	rail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if in_game else Control.SIZE_SHRINK_BEGIN
	rail.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	rail.add_theme_constant_override("margin_left", 28)
	rail.add_theme_constant_override("margin_right", 28)
	rail.add_theme_constant_override("margin_top", 24)
	rail.add_theme_constant_override("margin_bottom", 24)
	center.add_child(rail)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 15)
	rail.add_child(body)

	_title = Label.new()
	_title.add_theme_color_override("font_color", PAPER)
	_title.add_theme_font_size_override("font_size", 43)
	var display_font := SystemFont.new()
	display_font.font_names = PackedStringArray(["Georgia", "Liberation Serif", "DejaVu Serif"])
	_title.add_theme_font_override("font", display_font)
	body.add_child(_title)

	var divider := ColorRect.new()
	divider.color = Color("#b99c69")
	divider.custom_minimum_size = Vector2(72, 2)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	body.add_child(divider)
	_contents = VBoxContainer.new()
	_contents.add_theme_constant_override("separation", 7)
	body.add_child(_contents)
	show_home()
	if in_game:
		hide()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if not in_game or not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		if _confirmation.is_valid():
			show_home()
		else:
			_resume()
		get_viewport().set_input_as_handled()
	elif not GameManager.ui_open:
		get_tree().paused = true
		GameManager.ui_open = true
		GameManager.interaction_prompt_cleared.emit()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		show()
		show_home()
		get_viewport().set_input_as_handled()

func show_home() -> void:
	_confirmation = Callable()
	_clear_contents()
	_title.text = "Пауза" if in_game else "Летопись судьбы"
	var first: Button
	if in_game:
		first = _button("Вернуться в игру", _resume)
		_button("Сохранить игру", _open_save)
		_button("Загрузить игру", _show_load)
		_button("Главное меню", _confirm_main_menu)
	else:
		var latest := SaveManager.latest_slot()
		first = _button("Продолжить", _load.bind(latest))
		first.disabled = latest.is_empty()
		var new_game := _button("Новая игра", _start)
		_button("Загрузить игру", _show_load)
		_button("Выход", get_tree().quit)
		if first.disabled:
			first = new_game
	var language := HBoxContainer.new()
	language.add_theme_constant_override("separation", 12)
	_contents.add_child(language)
	var caption := _label("Язык", 15, MUTED)
	language.add_child(caption)
	var languages := OptionButton.new()
	languages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	languages.add_item("Русский")
	languages.add_item("English")
	languages.select(1 if TranslationServer.get_locale() == "en" else 0)
	languages.item_selected.connect(func(index: int): GameManager.set_language("en" if index == 1 else "ru"))
	language.add_child(languages)
	_focus(first)

func _show_load() -> void:
	_clear_contents()
	_title.text = "Загрузить игру"
	var first := _slot_row("manual", "Ручное сохранение")
	var automatic := _slot_row("auto", "Автосохранение")
	var back := _button("Назад", show_home)
	_focus(first if not first.disabled else (automatic if not automatic.disabled else back))

func _open_save() -> void:
	_clear_contents()
	_title.text = "Сохранить игру"
	_slot_details("manual", "Ручное сохранение")
	var save := _button("Сохранить", _confirm_save)
	save.disabled = not SaveManager.can_save()
	if save.disabled:
		_contents.add_child(_label("Сохранение доступно на твёрдой земле после изменения мира.", 15, MUTED))
	var back := _button("Назад", show_home)
	_focus(back if save.disabled else save)

func _slot_row(slot: String, title: String) -> Button:
	var info := _slot_details(slot, title)
	var button := _button("Загрузить", _load.bind(slot))
	button.disabled = not info["valid"]
	return button

func _slot_details(slot: String, title: String) -> Dictionary:
	var info := SaveManager.slot_info(slot)
	_contents.add_child(_label(title, 18, PAPER))
	var description := tr("Сохранение повреждено") if info["exists"] else tr("Слот пуст")
	if info["valid"]:
		var branches := {"": "Стартовая поляна", "extinguish_fire": "Путь Жизни", "pass_by": "Путь Пепла"}
		var region := tr(branches[info["ending"]])
		var timestamp := int(info["timestamp"]) + int(Time.get_time_zone_from_system()["bias"]) * 60
		var time := Time.get_datetime_dict_from_unix_time(timestamp)
		description = "%s   ·   %02d.%02d.%04d  %02d:%02d" % [
			region, time["day"], time["month"], time["year"], time["hour"], time["minute"]]
	_contents.add_child(_label(description, 14, MUTED))
	return info

func _start() -> void:
	if not SaveManager.start_new_game():
		_show_error("Не удалось открыть сцену.")

func _load(slot: String) -> void:
	if in_game:
		_confirm("Загрузить сохранение? Несохранённый прогресс будет потерян.", _perform_load.bind(slot))
	else:
		_perform_load(slot)

func _perform_load(slot: String) -> void:
	if not SaveManager.load_slot(slot):
		show_home()
		_show_error("Не удалось загрузить сохранение.")

func _confirm_save() -> void:
	if SaveManager.slot_info("manual")["exists"]:
		_confirm("Перезаписать ручное сохранение?", _perform_save)
	else:
		_perform_save()

func _perform_save() -> void:
	var saved := SaveManager.save_manual()
	_open_save()
	_show_error("Сохранение записано." if saved else "Не удалось записать сохранение.")

func _confirm_main_menu() -> void:
	_confirm("Выйти в главное меню? Несохранённый прогресс будет потерян.", _return_to_menu)

func _return_to_menu() -> void:
	if not SaveManager.return_to_menu():
		show_home()
		_show_error("Не удалось открыть сцену.")

func _confirm(message: String, action: Callable) -> void:
	_clear_contents()
	_confirmation = action
	_contents.add_child(_label(message, 17, PAPER))
	_button("Да", _accept)
	_focus(_button("Отмена", show_home))

func _accept() -> void:
	var action := _confirmation
	_confirmation = Callable()
	action.call()

func _resume() -> void:
	hide()
	get_tree().paused = false
	GameManager.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _clear_contents() -> void:
	for child in _contents.get_children():
		_contents.remove_child(child)
		child.queue_free()

func _focus(button: Button) -> void:
	if button.is_visible_in_tree():
		button.grab_focus()

func _show_error(message: String) -> void:
	_contents.add_child(_label(message, 15, GOLD))

func _button(title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(285, 41)
	button.pressed.connect(action)
	_contents.add_child(button)
	return button

func _label(title: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = title
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 285
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	return label

func _shade_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.46, 1.0])
	gradient.colors = PackedColorArray([Color("#111a19ed"), Color("#111a1999"), Color("#111a1926")])
	if in_game:
		gradient.colors = PackedColorArray([Color("#101919e8"), Color("#101919db"), Color("#101919e8")])
	var texture := GradientTexture2D.new()
	texture.width = 512
	texture.height = 4
	texture.gradient = gradient
	return texture

func _menu_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 17
	for type in ["Button", "OptionButton"]:
		theme.set_color("font_color", type, PAPER)
		theme.set_color("font_hover_color", type, Color.WHITE)
		theme.set_color("font_focus_color", type, GOLD)
		theme.set_color("font_disabled_color", type, Color("#858777"))
		theme.set_stylebox("normal", type, _button_style(Color("#182321bd"), Color("#6e7463")))
		theme.set_stylebox("hover", type, _button_style(Color("#273530"), GOLD))
		theme.set_stylebox("pressed", type, _button_style(Color("#38443b"), GOLD))
		theme.set_stylebox("disabled", type, _button_style(Color("#18232184"), Color("#565e50")))
		theme.set_stylebox("focus", type, _button_style(Color.TRANSPARENT, GOLD))
	return theme

func _button_style(fill: Color, outline: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
