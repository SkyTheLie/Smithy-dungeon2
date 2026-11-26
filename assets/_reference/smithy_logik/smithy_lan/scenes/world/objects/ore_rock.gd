class_name OreRock
extends StaticBody2D
## Mineable rock. Stand next to it and press (or hold) E: each hit needs the player's
## mining cooldown to be over and deals PlayerStats.mining_damage. When the health reaches 0,
## the rock's drop goes into the inventory (overflow: loot chest) and the rock disappears. Also used for trees and
## plants (other RockData). Damage and destruction are written into `field_entry`
## (see ResourceFields), so they last for the rest of the day.

## The rock was destroyed (the spawner removes it from today's list).
signal broken

## Set before the rock enters the tree (e.g. by the RockSpawner).
@export var data: RockData
## Entry of today's resource list ("health" is kept up to date). Empty = not stored.
var field_entry: Dictionary = {}

const COLOR_HIT_FLASH: Color = Color(1.8, 1.8, 1.8)
## Loaded by path, so the rock still works while the editor has not registered the class yet.
const HitChipsScript: GDScript = preload("res://scenes/world/objects/hit_chips.gd")
const NO_AXE_MESSAGE: String = "Ohne Axt wird das schwer."
const INVENTORY_FULL_MESSAGE: String = "Inventar voll: %d %s liegt in der Loot-Kiste."
## Sounds (audio.json) per tool: each hit, and when the rock / tree / plant is gone.
const HIT_SOUNDS: Dictionary = {RockData.Tool.PICKAXE: "pickaxe_hit", RockData.Tool.AXE: "axe_hit"}
const BREAK_SOUNDS: Dictionary = {RockData.Tool.PICKAXE: "rock_break", RockData.Tool.AXE: "wood_break", RockData.Tool.HAND: "plant_pick"}
const CHEST_FULL_MESSAGE: String = "Inventar und Loot-Kiste voll: %d %s verloren."

var _health: int = 0
## Player standing in the interaction area (null = nobody).
var _player: Player

@onready var _visual: CanvasItem = $Visual
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _health_bar: Control = $HealthBar
@onready var _health_fill: ColorRect = $HealthBar/Fill


func _ready() -> void:
	_health = data.max_health
	var saved_health: int = int(field_entry.get("health", -1))
	if saved_health > 0:
		_health = mini(saved_health, data.max_health)
	if data.texture:
		_sprite.texture = data.texture
		# Bottom edge on the node origin, health bar just above the sprite (rocks 32 px, trees 64 px).
		var height: float = data.texture.get_height()
		_sprite.offset = Vector2(0, -height / 2.0 + 2.0)
		_health_bar.position.y = -height - 2.0
		_visual.hide()
		_visual = _sprite
	else:
		($Visual as ColorRect).color = data.color
		_sprite.hide()
	_health_bar.hide()
	if _health < data.max_health:
		_update_health_bar()


func _process(_delta: float) -> void:
	if not _player:
		return
	# Trees can only be felled with an axe in the tool slot.
	if data.tool == RockData.Tool.AXE and not GameState.player_stats.get_tool(PlayerStats.ToolSlot.AXE):
		if Input.is_action_just_pressed("interact"):
			GameState.show_message(Language.translate(NO_AXE_MESSAGE))
		return
	if not Input.is_action_pressed("interact"):
		return
	# With the pickaxe or the lumber axe the hit lands when the swung tool strikes (Player._swing_pickaxe).
	var pickaxe: bool = data.tool == RockData.Tool.PICKAXE
	var axe: bool = data.tool == RockData.Tool.AXE
	if _player.try_mine(global_position, pickaxe or axe, "axe" if axe else "pickaxe"):
		if pickaxe or axe:
			get_tree().create_timer(_player.get_swing_hit_delay(), false).timeout.connect(_take_hit.bind(_get_damage()))
		else:
			_take_hit(_get_damage())


## Damage of one hit with the right tool for this resource.
func _get_damage() -> int:
	match data.tool:
		RockData.Tool.AXE:
			return GameState.player_stats.get_chopping_damage()
		RockData.Tool.HAND:
			return data.max_health
	return GameState.player_stats.get_mining_damage()


func _take_hit(damage: int) -> void:
	_health = maxi(_health - damage, 0)
	if _health > 0:
		AudioManager.play_sound(HIT_SOUNDS.get(data.tool, ""), randf_range(0.92, 1.08))
	if not field_entry.is_empty():
		field_entry["health"] = _health
	_update_health_bar()
	_visual.modulate = COLOR_HIT_FLASH
	create_tween().tween_property(_visual, "modulate", Color.WHITE, 0.15)
	if data.tool == RockData.Tool.PICKAXE:
		HitChipsScript.spawn(self, _visual, data.color)
	if _health == 0:
		_break()


func _break() -> void:
	AudioManager.play_sound(BREAK_SOUNDS.get(data.tool, ""), randf_range(0.95, 1.05))
	GameState.player_stats.add_experience(GameState.player_stats.experience_per_rock)
	if data.tool == RockData.Tool.PICKAXE:
		GameState.achievements.count("rock")
	var drop: ItemData = data.get_drop_item()
	# Skill "Glücksfund": rare finds (rarer ore, crystals) when mining with the pickaxe.
	var luck: float = 0.0
	if data.tool == RockData.Tool.PICKAXE:
		luck = GameState.player_stats.get_skill_bonus(PlayerStats.Stat.RARE_FIND)
	var better: bool = data.better_rarity_chance > 0.0 and randf() < data.better_rarity_chance + luck
	var rolled: int = data.roll_rarity()
	var rarity: int = (rolled if rolled >= 0 else drop.base_rarity) + (1 if better else 0)
	_give(drop, data.drop_amount, mini(rarity, Rarity.Tier.MYTHIC))
	var bonus: ItemData = data.get_bonus_drop_item()
	if bonus and randf() < data.bonus_drop_chance:
		_give(bonus, 1)
	if not data.rare_drop_item_ids.is_empty() and randf() < data.rare_drop_chance + luck:
		_give(ContentDB.item(data.rare_drop_item_ids.pick_random()), 1)
	broken.emit()
	queue_free()


## What does not fit into the inventory goes into the loot chest (only lost if that is full too).
func _give(item: ItemData, amount: int, rarity: int = -1) -> void:
	var leftover: int = GameState.inventory.add_item(item, amount, 0, rarity)
	if leftover <= 0:
		return
	var lost: int = GameState.put_into_reward_chest(item, leftover, rarity)
	if lost < leftover:
		GameState.show_message(Language.translate(INVENTORY_FULL_MESSAGE) % [leftover - lost, item.display_name])
	if lost > 0:
		GameState.show_message(Language.translate(CHEST_FULL_MESSAGE) % [lost, item.display_name])


func _update_health_bar() -> void:
	_health_bar.show()
	_health_fill.size.x = _health_bar.size.x * _health / data.max_health


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
