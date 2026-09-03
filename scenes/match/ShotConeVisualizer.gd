class_name ShotConeVisualizer
extends Node2D

## Cono di tiro verso la porta avversaria, con le sagome che lo ostruiscono
## (GDD §4 e §4.1).
##
## Riproduce a schermo la geometria di [method ActionResolver.is_in_shot_cone]:
## semiapertura di 18 gradi dal tiratore verso la porta e nessuna sagoma più
## lontana della porta stessa. Le sagome dentro il cono vengono cerchiate e il
## malus complessivo di -15 punti per sagoma (GDD §4.1) è scritto in campo.

const ARC_SAMPLES: int = 18
const EDGE_DASH: float = 18.0
const EDGE_WIDTH: float = 2.5
const AXIS_WIDTH: float = 1.5
const MARKER_RADIUS: float = 40.0
const MARKER_WIDTH: float = 3.0
const LABEL_FONT_SIZE: int = 18
const LABEL_BOX_WIDTH: float = 300.0

const CONE_FILL := Color(1.0, 0.82, 0.4, 0.10)
const CONE_EDGE := Color("ffd166")
const CONE_AXIS := Color(1.0, 0.82, 0.4, 0.45)
const BLOCKED_COLOR := Color("ff2e57")
const LABEL_BACKDROP := Color(0.03, 0.08, 0.07, 0.75)

## Vertice del cono: la posizione del tiratore in coordinate pitch (GDD §9).
var origin: Vector2 = Vector2.ZERO

## Centro della porta avversaria verso cui punta l'asse del cono.
var goal_position: Vector2 = ActionResolver.get_goal_position()

## Semiapertura del cono in gradi, allineata a [ActionResolver].
var half_angle_deg: float = ActionResolver.SHOT_CONE_HALF_ANGLE_DEG

## Sagome difensive in campo, nel formato di [method ActionResolver.make_defender].
var obstacles: Array[Dictionary] = []

## Sagome che ostruiscono il cono, calcolate all'ultimo aggiornamento.
var blocking: Array[Dictionary] = []


## Accende il cono dal tiratore verso la porta e ricalcola le sagome ostruenti.
func show_cone(shooter_pos: Vector2, defenders: Array[Dictionary], goal_pos: Vector2 = ActionResolver.get_goal_position()) -> void:
	origin = shooter_pos
	goal_position = goal_pos
	obstacles = defenders
	blocking = _collect_blocking()
	visible = true
	queue_redraw()


## Spegne il cono.
func clear_cone() -> void:
	visible = false
	blocking = []
	queue_redraw()


## Cartellini delle sagome dentro il cono, per l'evidenziazione delle pedine.
func get_blocking_players() -> Array[PlayerData]:
	var players: Array[PlayerData] = []
	for entry in blocking:
		var card := entry.get("player") as PlayerData
		if card != null:
			players.append(card)
	return players


## Malus di Potenza Azione applicato dalle sagome nel cono (GDD §4.1).
func get_malus() -> float:
	return ActionResolver.OBSTACLE_POWER_MALUS * float(blocking.size())


func _draw() -> void:
	var axis := goal_position - origin
	if is_zero_approx(axis.length_squared()):
		return
	var length := axis.length()
	var base_angle := axis.angle()
	var half := deg_to_rad(half_angle_deg)
	var points := PackedVector2Array()
	points.append(origin)
	for index in ARC_SAMPLES + 1:
		var ratio := float(index) / float(ARC_SAMPLES)
		var angle := base_angle - half + ratio * half * 2.0
		points.append(origin + Vector2.from_angle(angle) * length)
	draw_colored_polygon(points, CONE_FILL)
	var edge_a := origin + Vector2.from_angle(base_angle - half) * length
	var edge_b := origin + Vector2.from_angle(base_angle + half) * length
	draw_dashed_line(origin, edge_a, CONE_EDGE, EDGE_WIDTH, EDGE_DASH)
	draw_dashed_line(origin, edge_b, CONE_EDGE, EDGE_WIDTH, EDGE_DASH)
	draw_arc(origin, length, base_angle - half, base_angle + half, ARC_SAMPLES * 2, Color(CONE_EDGE.r, CONE_EDGE.g, CONE_EDGE.b, 0.5), EDGE_WIDTH)
	draw_line(origin, goal_position, CONE_AXIS, AXIS_WIDTH)
	_draw_blocking_markers()


## Reticoli sulle sagome dentro il cono e malus complessivo (GDD §4.1).
func _draw_blocking_markers() -> void:
	if blocking.is_empty():
		return
	for entry in blocking:
		var field_pos: Vector2 = entry.get("position", Vector2.ZERO)
		draw_arc(field_pos, MARKER_RADIUS, 0.0, TAU, 32, BLOCKED_COLOR, MARKER_WIDTH)
		draw_line(field_pos + Vector2(-MARKER_RADIUS, 0.0), field_pos + Vector2(MARKER_RADIUS, 0.0), Color(BLOCKED_COLOR.r, BLOCKED_COLOR.g, BLOCKED_COLOR.b, 0.6), 1.5)
		draw_line(field_pos + Vector2(0.0, -MARKER_RADIUS), field_pos + Vector2(0.0, MARKER_RADIUS), Color(BLOCKED_COLOR.r, BLOCKED_COLOR.g, BLOCKED_COLOR.b, 0.6), 1.5)
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var text := "%d sagome nel cono  -%.0f potenza" % [blocking.size(), get_malus()]
	var anchor := origin.lerp(goal_position, 0.55) + Vector2(0.0, -46.0)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, LABEL_FONT_SIZE)
	var backdrop := Rect2(anchor - Vector2(text_size.x * 0.5 + 8.0, text_size.y * 0.8 + 4.0), text_size + Vector2(16.0, 10.0))
	draw_rect(backdrop, LABEL_BACKDROP, true)
	draw_string(font, anchor - Vector2(LABEL_BOX_WIDTH * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, LABEL_BOX_WIDTH, LABEL_FONT_SIZE, BLOCKED_COLOR)


## Sagome la cui posizione ricade nel cono di tiro (GDD §4).
func _collect_blocking() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry in obstacles:
		var card := entry.get("player") as PlayerData
		if card == null:
			continue
		var field_pos: Vector2 = entry.get("position", Vector2.ZERO)
		if ActionResolver.is_in_shot_cone(field_pos, origin, goal_position, half_angle_deg):
			found.append(entry)
	return found
