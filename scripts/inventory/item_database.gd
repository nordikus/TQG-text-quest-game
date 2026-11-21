class_name ItemDatabase
extends RefCounted

const ITEMS: Dictionary = {
	"throne_hall_key": {
		"id": "throne_hall_key",
		"title": "Печать капитана",
		"description": "На потемневшей бронзе — герб замкового караула. Ободок отполирован пальцами.",
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
	},
	"star_crystal_shard": {
		"id": "star_crystal_shard",
		"title": "Осколок Звездного Кристалла",
		"description": "На сколе холодно поблёскивают лазурные грани. Даже в тепле камень остаётся ледяным.",
		"category": "item",
		"max_uses": -1,
		"icon_color": Color(0.35, 0.85, 0.95, 1.0)
	},
	"astromancer_journal": {
		"id": "astromancer_journal",
		"title": "Дневник Астроманта",
		"description": "«Отделил от кристалла малый осколок. Поднёс к знаку на мосту — резьба отозвалась. Капитан просит поставить такой же знак на его сундуке».",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.40, 0.80, 0.95, 1.0)
	},
	"captains_sealed_report": {
		"id": "captains_sealed_report",
		"title": "Запечатанное донесение капитана",
		"description": "«Колодец пересох за три ночи до пожара. Каменщики нашли под западной стеной корни. Они шли к воде под двором. Приказ засыпать старый водовод я исполнил. Сведения о том, кто его отдал, велено из донесения вычеркнуть».",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.62, 0.81, 0.87, 1.0)
	},
	"royal_order_draft": {
		"id": "royal_order_draft",
		"title": "Черновик королевского приказа",
		"description": "«Старый водовод засыпать сегодня, пока роща ещё спит. Если капитан спросит, откуда взялись корни, велите ему взглянуть на печать. Приказ мой. Я знал, куда шла вода».",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.86, 0.69, 0.49, 1.0)
	},
	"chronicle_of_the_fire": {
		"id": "chronicle_of_the_fire",
		"title": "Хроника Великого Пламени",
		"description": "«Запись королевского архивариуса: Пламя поглотило восточную долину в считанные часы. Чародеи возвели рунные барьеры на переходах, а Тронный зал был закрыт на золотую печать. Если эти строки читает путник — помни: замок пал не от мечей, а от забвения древнего пакта с лесом.»",
		"category": "note",
		"max_uses": -1,
		"icon_color": Color(0.95, 0.70, 0.35, 1.0)
	}
}

static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})
