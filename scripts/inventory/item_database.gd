class_name ItemDatabase
extends RefCounted

const ITEMS: Dictionary = {
	"throne_hall_key": {
		"id": "throne_hall_key",
		"title": "Ключ-печать Тронного зала",
		"description": "Тяжёлый золотой ключ с выгравированным королевским вензелем. Открывает массивные парадные врата Тронного зала.",
		"category": "item",
		"max_uses": 1,
		"icon_color": Color(0.95, 0.82, 0.35, 1.0)
	},
	"guard_captain_note": {
		"id": "guard_captain_note",
		"title": "Приказ капитана стражи",
		"description": "«Ввиду беспорядков в лесу и угрозы прорыва все внешние галереи запечатаны. Главный ключ от Тронного зала оставлен в оружейной казарм на столе. Часовым на башнях — следить за западным сектором и Башней мага.»",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.85, 0.78, 0.65, 1.0)
	},
	"chapel_lore_note": {
		"id": "chapel_lore_note",
		"title": "Молитва Незримому Наблюдателю",
		"description": "«О Наблюдатель, держащий нити всех миров... Мы слышим хруст твоих шагов и знаем: всякая запись может стать вечностью, но лишь немногие страницы заслуживают быть нетронутыми.»",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.65, 0.85, 0.95, 1.0)
	},
	"great_quill": {
		"id": "great_quill",
		"title": "Великое перо",
		"description": "Мистическое перо, способное переписать застывшие страницы истории. Каждое применение меняет ткань реальности и оставляет след в памяти Наблюдателя.",
		"category": "item",
		"max_uses": -1,
		"icon_color": Color(0.85, 0.45, 0.95, 1.0)
	}
}

static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})
