class_name UIStyle
extends RefCounted

## Palette e fabbriche di nodi condivise dal Calcio Mercato e dalle schermate di
## stato (GDD §12 - "lavagna tattica moderna").
##
## Utility interamente statica: non va istanziata. Nessun asset esterno, solo
## colori, StyleBoxFlat generati a runtime e nodi Control standard di Godot 4.
## Nessuna logica di gioco: le formule restano in scripts/core/.

## Risoluzione di riferimento del layout (GDD §12).
const DESIGN_SIZE := Vector2(1920.0, 1080.0)

const BACKDROP := Color(0.02, 0.06, 0.05, 0.96)
const MODAL_SHADE := Color(0.01, 0.03, 0.03, 0.72)
const PANEL_FILL := Color(0.03, 0.09, 0.08, 0.92)
const PANEL_EDGE := Color(0.27, 0.94, 0.75, 0.35)
const CARD_FILL := Color(0.04, 0.12, 0.11, 0.96)
const CARD_EDGE := Color(0.27, 0.94, 0.75, 0.45)
const CARD_SPENT := Color(0.05, 0.07, 0.07, 0.92)
const TEXT_MAIN := Color(0.94, 0.98, 0.96)
const TEXT_DIM := Color(0.62, 0.75, 0.71)
const ACCENT := Color("46f0c0")
const GOLD := Color("ffd166")
const WARN := Color("ffb703")
const DANGER := Color("ff5f6d")
const INFO := Color("8ecae6")

## Colori dei ruoli, dalla porta all'attacco (GDD §5).
const ROLE_COLORS := {
	"POR": Color("ffd166"),
	"DIF": Color("8ecae6"),
	"CEN": Color("46f0c0"),
	"ATT": Color("ff5f6d"),
}


## Colore associato al ruolo del cartellino, grigio per ruoli fuori catalogo.
static func role_color(role: String) -> Color:
	var picked: Color = ROLE_COLORS.get(role, TEXT_DIM)
	return picked


## Rarità in stelle come da GDD §6: 1, 2 oppure 3 simboli.
static func stars(rarity: int) -> String:
	return "*".repeat(clampi(rarity, 1, 3))


## Numero compatto per punti parata e potenze, che in Ante 6 arrivano a 60.000
## (GDD §7).
static func format_points(value: float) -> String:
	if value >= 10000.0:
		return "%.1fk" % (value / 1000.0)
	return "%.0f" % value


## Etichetta posizionata in coordinate di design, indipendente dal tema.
static func make_label(text: String, rect: Rect2, font_size: int = 20, color: Color = TEXT_MAIN, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Etichetta multiriga con ritorno a capo automatico, per le descrizioni.
static func make_paragraph(text: String, rect: Rect2, font_size: int = 15, color: Color = TEXT_DIM) -> Label:
	var label := make_label(text, rect, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.clip_text = false
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


## Pulsante piatto in stile lavagna tattica, con i quattro stati sovrascritti.
static func make_button(text: String, rect: Rect2, font_size: int = 20, tint: Color = ACCENT) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", tint)
	button.add_theme_color_override("font_hover_color", TEXT_MAIN)
	button.add_theme_color_override("font_pressed_color", TEXT_MAIN)
	button.add_theme_color_override("font_disabled_color", Color(TEXT_DIM.r, TEXT_DIM.g, TEXT_DIM.b, 0.45))
	button.add_theme_stylebox_override("normal", make_box(Color(tint.r, tint.g, tint.b, 0.14), tint))
	button.add_theme_stylebox_override("hover", make_box(Color(tint.r, tint.g, tint.b, 0.28), tint))
	button.add_theme_stylebox_override("pressed", make_box(Color(tint.r, tint.g, tint.b, 0.42), TEXT_MAIN))
	button.add_theme_stylebox_override("disabled", make_box(Color(0.08, 0.11, 0.11, 0.7), Color(TEXT_DIM.r, TEXT_DIM.g, TEXT_DIM.b, 0.3)))
	return button


## StyleBoxFlat con riempimento, bordo neon e angoli arrotondati.
static func make_box(fill: Color, edge: Color, corner: int = 6, border: int = 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(border)
	box.set_corner_radius_all(corner)
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	return box


## OptionButton coerente con i pulsanti, usato per scegliere il bersaglio
## dell'allenamento (GDD §10.3).
static func make_option(rect: Rect2, font_size: int = 17) -> OptionButton:
	var option := OptionButton.new()
	option.position = rect.position
	option.size = rect.size
	option.focus_mode = Control.FOCUS_NONE
	option.add_theme_font_size_override("font_size", font_size)
	option.add_theme_color_override("font_color", TEXT_MAIN)
	option.add_theme_stylebox_override("normal", make_box(Color(0.05, 0.13, 0.12, 0.95), PANEL_EDGE))
	option.add_theme_stylebox_override("hover", make_box(Color(0.07, 0.18, 0.16, 0.95), CARD_EDGE))
	option.add_theme_stylebox_override("pressed", make_box(Color(0.08, 0.22, 0.19, 0.95), ACCENT))
	return option


## Riquadro semitrasparente con bordo neon: va chiamata dentro un [method
## CanvasItem._draw] (GDD §12).
static func draw_panel(canvas: CanvasItem, rect: Rect2, fill: Color = PANEL_FILL, edge: Color = PANEL_EDGE, width: float = 2.0) -> void:
	canvas.draw_rect(rect, fill, true)
	canvas.draw_rect(rect, edge, false, width)


## Barra di avanzamento orizzontale, usata per punti parata e budget.
static func draw_bar(canvas: CanvasItem, rect: Rect2, ratio: float, fill: Color = ACCENT) -> void:
	canvas.draw_rect(rect, Color(0.09, 0.14, 0.13, 0.9), true)
	var clamped := clampf(ratio, 0.0, 1.0)
	if clamped <= 0.0:
		return
	canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clamped, rect.size.y)), fill, true)


## Riga di separazione sottile, in stile linea di gesso (GDD §12).
static func draw_rule(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color = PANEL_EDGE) -> void:
	canvas.draw_line(from, to, color, 1.0)
