extends CanvasLayer

@onready var tab_items_btn: Button = $PanelContainer/VBoxContainer/Header/TabItemsBtn
@onready var tab_notes_btn: Button = $PanelContainer/VBoxContainer/Header/TabNotesBtn
@onready var close_btn: Button = $PanelContainer/VBoxContainer/Header/CloseButton
@onready var items_grid: GridContainer = $PanelContainer/VBoxContainer/Body/LeftCol/GridScroll/ItemsGrid
@onready var prev_page_btn: Button = $PanelContainer/VBoxContainer/Body/LeftCol/PageControls/PrevBtn
@onready var next_page_btn: Button = $PanelContainer/VBoxContainer/Body/LeftCol/PageControls/NextBtn
@onready var page_label: Label = $PanelContainer/VBoxContainer/Body/LeftCol/PageControls/PageLabel
@onready var detail_title: Label = $PanelContainer/VBoxContainer/Body/RightCol/DetailTitle
@onready var detail_desc: RichTextLabel = $PanelContainer/VBoxContainer/Body/RightCol/DescScroll/DetailDesc
@onready var empty_label: Label = $PanelContainer/VBoxContainer/Body/LeftCol/EmptyLabel

const ITEMS_PER_PAGE: int = 8

var current_tab: String = "items" # "items" or "notes"
var current_page: int = 0
var selected_item_data: Dictionary = {}

func _ready():
	GameManager.inventory_panel = self
	visible = false
	tab_items_btn.pressed.connect(_on_tab_changed.bind("items"))
	tab_notes_btn.pressed.connect(_on_tab_changed.bind("notes"))
	close_btn.pressed.connect(close_inventory)
	prev_page_btn.pressed.connect(_on_prev_page)
	next_page_btn.pressed.connect(_on_next_page)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()

func toggle_inventory():
	if visible:
		close_inventory()
	else:
		open_inventory()

func open_inventory():
	if GameManager.ui_open and not visible:
		return
	visible = true
	GameManager.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_page = 0
	_refresh_ui()

func close_inventory():
	visible = false
	GameManager.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_tab_changed(tab: String):
	current_tab = tab
	current_page = 0
	selected_item_data.clear()
	_refresh_ui()

func _on_prev_page():
	if current_page > 0:
		current_page -= 1
		_refresh_ui()

func _on_next_page():
	current_page += 1
	_refresh_ui()

func _on_inventory_changed():
	if visible:
		_refresh_ui()

func _refresh_ui():
	tab_items_btn.disabled = (current_tab == "items")
	tab_notes_btn.disabled = (current_tab == "notes")

	var list: Array[Dictionary] = InventoryManager.get_items() if current_tab == "items" else InventoryManager.get_notes()
	var total_items := list.size()
	var max_page: int = maxi(1, int(ceil(float(total_items) / float(ITEMS_PER_PAGE))))
	current_page = clampi(current_page, 0, max_page - 1)

	page_label.text = "Стр. %d / %d" % [current_page + 1, max_page]
	prev_page_btn.disabled = (current_page == 0)
	next_page_btn.disabled = (current_page >= max_page - 1)

	for child in items_grid.get_children():
		child.queue_free()

	if total_items == 0:
		empty_label.visible = true
		empty_label.text = "Нет вещей" if current_tab == "items" else "Нет записок"
		detail_title.text = "Ничего не выбрано"
		detail_desc.text = ""
		return

	empty_label.visible = false

	var start_idx: int = current_page * ITEMS_PER_PAGE
	var end_idx: int = mini(start_idx + ITEMS_PER_PAGE, total_items)

	var selected_still_valid := false

	for i in range(start_idx, end_idx):
		var it: Dictionary = list[i]
		var btn := Button.new()
		btn.text = it.get("title", "")
		btn.custom_minimum_size = Vector2(160, 48)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.clip_text = true

		var icon_col: Color = it.get("icon_color", Color.WHITE)
		btn.modulate = icon_col.lerp(Color.WHITE, 0.4)

		var cur_it: Dictionary = it
		btn.pressed.connect(func(): _select_item(cur_it))
		items_grid.add_child(btn)

		if selected_item_data.get("id") == it.get("id"):
			selected_still_valid = true

	if not selected_still_valid:
		if end_idx > start_idx:
			_select_item(list[start_idx])
		else:
			detail_title.text = "Ничего не выбрано"
			detail_desc.text = ""

func _select_item(item_data: Dictionary):
	selected_item_data = item_data
	detail_title.text = item_data.get("title", "")
	var category_str: String = "Предмет" if item_data.get("category") == "item" else "Записка"
	var text_content: String = "[color=#bba87c][b]%s[/b][/color]\n\n%s" % [category_str, item_data.get("description", "")]
	detail_desc.text = text_content
