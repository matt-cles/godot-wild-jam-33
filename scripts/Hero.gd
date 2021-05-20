extends Spatial

signal health_changed
signal mana_changed
signal stamina_changed

onready var events:Node = get_tree().get_nodes_in_group("events")[0]
onready var weapon_slot = get_node("pivot/RightHand/WeaponSlot")

export var max_health:float = 100
export var max_mana:float = 100
export var max_stamina:float = 100

var walking = true
var dead = false
var health:float = 0
var mana:float = 0
var stamina:float = 0

func _ready():
	var _connected = events.connect('stop_moving', self, 'stop_walking')
	_connected = events.connect('start_moving', self, 'start_walking')
	_connected = events.connect('hero_turn', self, 'attack')
	_connected = events.connect('damage_hero', self, 'take_damage')
	$AnimationPlayer.play("walk")
	modify_health(max_health/2)
	modify_mana(max_mana/2)
	modify_stamina(max_stamina/2)

func _process(delta):
	if dead:
		return
	var current_item:Item = get_weapon()
	if health <= 0:
		dead = true
		$AnimationPlayer.play("die")
		events.emit_signal("hero_dead")
		events.emit_signal("stop_moving")
	if current_item:
		match current_item.restore_type:
			Item.RESTORE_TYPES.HEALTH:
				modify_health(current_item.restore_amount * delta)
			Item.RESTORE_TYPES.MANA:
				modify_mana(current_item.restore_amount * delta)
			Item.RESTORE_TYPES.STAMINA:
				modify_stamina(current_item.restore_amount * delta)

func get_weapon():
	var weapons = weapon_slot.get_children()
	if weapons:
		return weapons[0]
	return null

func take_damage(damage):
	modify_health(-damage)

func modify_health(amount):
	if not dead:
		health = clamp(health+amount, 0.0, max_health)
		emit_signal("health_changed", health)

func modify_mana(amount):
	if not dead:
		mana = clamp(mana+amount, 0.0, max_mana)
		emit_signal("mana_changed", mana)

func modify_stamina(amount):
	if not dead:
		stamina = clamp(stamina+amount, 0.0, max_stamina)
		emit_signal("stamina_changed", stamina)

func start_walking():
	if not dead:
		walking = true
		$AnimationPlayer.play("walk")

func stop_walking():
	if not dead:
		walking = false
		$AnimationPlayer.play("still")
		attack()
	
func attack():
	if dead:
		return
	var current_item:Item = get_weapon()
	if current_item:
		if current_item.damage_type != Item.DAMAGE_TYPES.NONE:
			if mana >= current_item.mana_cost and stamina >= current_item.stamina_cost:
				$AnimationPlayer.play("attack")
				yield($AnimationPlayer, "animation_finished")
				events.emit_signal("damage_enemy", current_item.damage)
				modify_mana(-current_item.mana_cost)
				modify_stamina(-current_item.stamina_cost)
			else:
				$AnimationPlayer.play("tired")
				yield($AnimationPlayer, "animation_finished")
		else:
			$AnimationPlayer.play("drink")
			yield($AnimationPlayer, "animation_finished")
	events.emit_signal("enemy_turn")
	
