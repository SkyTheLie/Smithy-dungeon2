class_name Socket
extends Resource
## One filled socket of an item: a SocketBonus (sockets.json) at a level.
## Masterworks: well built equipment can come with a socket (try_masterwork, economy.json "masterwork_socket").

@export var bonus: SocketBonus
@export var level: int = 1
## Share of the value that counts (parts of a combo bonus, see InventorySlot.get_active_sockets).
var factor: float = 1.0


static func create(socket_bonus: SocketBonus, socket_level: int) -> Socket:
	var socket := Socket.new()
	socket.bonus = socket_bonus
	socket.level = clampi(socket_level, 1, socket_bonus.get_max_level())
	return socket


## A random bonus that fits `item`, at a level rolled by its chances. null if none fits.
static func roll_for(item: ItemData) -> Socket:
	var fitting: Array[SocketBonus] = ContentDB.get_socket_bonuses_for(item)
	if fitting.is_empty():
		return null
	var picked: SocketBonus = fitting.pick_random()
	return create(picked, picked.roll_level())


## A piece from the workbench of at least "min_rarity" has a "chance" of one random socket
## (plus `extra_chance` from the skill "Meisterwerk", PlayerStats.get_socket_chance_bonus).
static func try_masterwork(stack: InventorySlot, extra_chance: float = 0.0) -> void:
	var rules: Dictionary = ContentDB.economy("masterwork_socket")
	if not stack.item.is_equipment() or stack.rarity < int(rules.get("min_rarity", 3)):
		return
	if randf() < get_masterwork_chance(extra_chance):
		stack.add_socket(roll_for(stack.item))


## Chance (0-1) of a masterwork socket: economy.json "masterwork_socket" chance + `extra_chance`.
static func get_masterwork_chance(extra_chance: float = 0.0) -> float:
	var base: float = float(ContentDB.economy("masterwork_socket").get("chance", 0.0))
	return clampf(base + extra_chance, 0.0, 1.0)


func get_value() -> float:
	return bonus.get_value(level) * factor


## e.g. "Wucht 3: +12 % Stumpf-Schaden".
func get_text() -> String:
	return "%s %d: %s" % [bonus.display_name, level, bonus.get_effect_text(level)]


func to_save_data() -> Array:
	return [String(bonus.id), level]


## null if the bonus no longer exists.
static func from_save_data(data: Array) -> Socket:
	if data.size() < 2 or not ContentDB.has_socket_bonus(str(data[0])):
		return null
	return create(ContentDB.socket_bonus(str(data[0])), int(data[1]))
