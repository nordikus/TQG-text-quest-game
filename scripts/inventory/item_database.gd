class_name ItemDatabase
extends RefCounted

const ITEMS: Dictionary = {
	"throne_hall_key": {
		"id": "throne_hall_key",
		"title": "Печать капитана",
		"description": "Герб замкового караула из бронзы. Слегка потерт и поцарапан",
		"category": "item",
		"max_uses": -1,
		"icon_color": Color(0.95, 0.82, 0.35, 1.0)
	},
	"guard_captain_note": {
		"id": "guard_captain_note",
		"title": "Приказ капитана стражи",
		"description": "«Печать караула оставить на столе. Донесение я убрал под знак астроманта. До прихода каменщиков по крытому мосту ходить по одному».",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.85, 0.78, 0.65, 1.0)
	},
	"chapel_lore_note": {
		"id": "chapel_lore_note",
		"title": "Молитва Лецерусу",
		"description": "«О Лецерус, бог праведного света, спаси нас от последователей тьмы»",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.65, 0.85, 0.95, 1.0)
	},
	"great_quill": {
		"id": "great_quill",
		"title": "Великое перо",
		"description": "Мистическое перо переливающееся бирюзой, по преданиям позволяет менять судьбу.",
		"category": "item",
		"max_uses": -1,
		"icon_color": Color(0.85, 0.45, 0.95, 1.0)
	},
	"star_crystal_shard": {
		"id": "star_crystal_shard",
		"title": "Осколок Звездного Кристалла",
		"description": "Кристалл мягко переливается бирюзой, сквозь него виден космос.",
		"category": "item",
		"max_uses": -1,
		"icon_color": Color(0.35, 0.85, 0.95, 1.0)
	},
	"astromancer_journal": {
		"id": "astromancer_journal",
		"title": "Дневник Астроманта",
		"description": "«Кристалл который недавно привезли торговцы подпитывается под ночным небом, я внес в него заклинание открывающие магические замки».",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.40, 0.80, 0.95, 1.0)
	},
	"captains_sealed_report": {
		"id": "captains_sealed_report",
		"title": "Запечатанное донесение капитана",
		"description": "«Колодец пересох, стража говорит о неких корнях в глубине, король в последнее время вел себя странно».",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.62, 0.81, 0.87, 1.0)
	},
	"royal_order_draft": {
		"id": "royal_order_draft",
		"title": "Черновик королевского приказа",
		"description": "«Старый водовод засыпать сегодня, это поможет против шпионов».",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.86, 0.69, 0.49, 1.0)
	},
	"upper_guard_ledger": {
		"id": "upper_guard_ledger",
		"title": "Ведомость замкового караула",
		"description": "«Третий караул. Два воза тесаного камня приняли после отбоя. Кухне выдать провизию на шестерых. Людей, работавших под двором остерегаться».",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.84, 0.74, 0.54, 1.0)
	},
	"waterkeeper_note": {
		"id": "waterkeeper_note",
		"title": "Записка смотрителя водовода",
		"description": "«Под восточной кухней слышно, как вода идёт обратно. Утром в желобе нашёл светлый волосок корня. К вечеру он уже обвил задвижку. Чую король не просто так нервный все это время».",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.64, 0.78, 0.76, 1.0)
	},
	"chronicle_of_the_fire": {
		"id": "chronicle_of_the_fire",
		"title": "Дворцовая хроника",
		"description": "«Запись королевского архивариуса: Король ведет себя все страннее, он постоянно повторяет что-то про огонь, древо и шпионов, мне кажется он сходит с ума»",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.95, 0.70, 0.35, 1.0)
	}
}

static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})
