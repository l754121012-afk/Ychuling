class_name TestGhost
extends CharacterBody3D

signal sent_off(ghost: TestGhost)
signal chain_triggered(target: TestGhost, source: TestGhost)

enum State {
	ACTIVE,
	STAGGERED,
	SENDING,
}

enum AttackStyle {
	NONE,
	SWIPE,
	POOL,
	LUNGE,
	SHOT,
	SHOCKWAVE,
	BOSS,
}

enum Action {
	NONE,
	SWIPE_WINDUP,
	POOL_WAIT,
	LUNGE_CHARGE,
	LUNGE_MOVE,
	SHOT_CAST,
	SHOCKWAVE_CAST,
}

const CHASE_SPEED := 2.0
const KNOCKBACK_TIME := 0.24
const KNOCKBACK_SPEED := 9.0
const CHAIN_TAG_DURATION := 0.7
const COLLISION_DAMAGE_WINDOW := 2.0
const COLLISION_DAMAGE_RATIO := 0.5
const COLLISION_STACK_STEP := 0.5
const COLLISION_DAMAGE_CD := 0.3

const SWIPE_RANGE := 2.8
const SWIPE_WINDUP := 0.42
const POOL_RANGE := 7.0
const POOL_WAIT := 0.95
const POOL_RADIUS := 1.5
const LUNGE_RANGE := 8.0
const LUNGE_CHARGE := 0.6
const LUNGE_MOVE_TIME := 0.32
const LUNGE_SPEED := 9.5
const SHOT_RANGE := 9.5
const SHOT_WINDUP := 0.5
const SHOCKWAVE_RADIUS := 5.0
const SHOCKWAVE_WINDUP := 0.7

const SpiritOrbScript := preload("res://scripts/actors/SpiritOrb.gd")

@export var hits_to_stagger := 4
@export var art_scale := 1.0
@export var attack_style := AttackStyle.NONE
@export var can_use_pool := false

var state := State.ACTIVE
var _hits_remaining := 2
var _body_visual: MeshInstance3D

var _action := Action.NONE
var _action_timer := 0.0
var _attack_cooldown := 0.0
var _pool_center := Vector3.ZERO
var _pool_marker: MeshInstance3D
var _lunge_dir := Vector3.FORWARD
var _lunge_hit_done := false
var _knockback_time := 0.0
var _knockback_dir := Vector3.FORWARD
var _melee_arc: MeshInstance3D
var _stagger_ring: MeshInstance3D
var _arm_left_pivot: Node3D
var _arm_right_pivot: Node3D
var _leg_left_pivot: Node3D
var _leg_right_pivot: Node3D
var _weapon_visual: MeshInstance3D
var _weapon_orb: MeshInstance3D
var _sendoff_chunk: MeshInstance3D
var _chain_tag_time := 0.0
var _recent_player_damage := 0
var _damage_window_time := 0.0
var _collision_stack := 0
var _collision_damage_cd := 0.0
var _shockwave_marker: MeshInstance3D
var _boss_combo_pending := AttackStyle.NONE
var _step_time := 0.0


func _ready() -> void:
	add_to_group("ghosts")
	_hits_remaining = hits_to_stagger
	_setup_collision()
	_setup_art()
	_setup_attack_visual()


func configure_attack_style(p_style: String) -> void:
	match p_style:
		"swipe":
			attack_style = AttackStyle.SWIPE
		"pool":
			attack_style = AttackStyle.POOL
		"lunge":
			attack_style = AttackStyle.LUNGE
		"shot":
			attack_style = AttackStyle.SHOT
		"boss":
			attack_style = AttackStyle.BOSS
		_:
			attack_style = AttackStyle.NONE


func _physics_process(delta: float) -> void:
	if state == State.SENDING:
		return
	if _chain_tag_time > 0.0:
		_chain_tag_time = maxf(0.0, _chain_tag_time - delta)
	if _damage_window_time > 0.0:
		_damage_window_time -= delta
		if _damage_window_time <= 0.0:
			_recent_player_damage = 0
			_collision_stack = 0
	_collision_damage_cd = maxf(0.0, _collision_damage_cd - delta)
	_animate_legs(delta)
	if _knockback_time > 0.0:
		_knockback_time -= delta
		var falloff := clampf(_knockback_time / KNOCKBACK_TIME, 0.0, 1.0)
		velocity.x = _knockback_dir.x * KNOCKBACK_SPEED * falloff
		velocity.z = _knockback_dir.z * KNOCKBACK_SPEED * falloff
	elif state == State.STAGGERED:
		velocity.x = 0.0
		velocity.z = 0.0
	elif state == State.ACTIVE:
		_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
		var player := _get_player()
		if _action != Action.NONE:
			_advance_action(delta, player)
		elif player:
			_try_start_attack(player)
			if _action == Action.NONE:
				_chase_player(player)

	move_and_slide()
	_resolve_ghost_bumps()
	_bounce_off_slide_collisions()


func on_cleaned(p_by: Node, p_is_sweep: bool = false, p_damage: int = 1) -> void:
	if state != State.ACTIVE:
		return
	_cancel_action()
	_hits_remaining -= p_damage
	if p_by and p_by.is_in_group("player"):
		_recent_player_damage = p_damage
		_damage_window_time = COLLISION_DAMAGE_WINDOW
		_collision_stack = 0
	if p_is_sweep:
		_chain_tag_time = CHAIN_TAG_DURATION

	var source_position := global_position + Vector3.FORWARD
	if p_by:
		source_position = p_by.global_position
	var direction := global_position - source_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = Vector3.RIGHT
	_knockback_dir = direction.normalized()
	_knockback_time = KNOCKBACK_TIME
	velocity = _knockback_dir * KNOCKBACK_SPEED

	if _hits_remaining <= 0:
		_enter_staggered()
	else:
		_flash_hit()


func on_chain_hit(p_source: TestGhost) -> void:
	if state != State.ACTIVE or _collision_damage_cd > 0.0:
		return
	_cancel_action()
	_collision_damage_cd = COLLISION_DAMAGE_CD
	var base_damage := maxi(p_source._recent_player_damage, _recent_player_damage)
	if base_damage <= 0:
		base_damage = 1
	_recent_player_damage = base_damage
	_damage_window_time = COLLISION_DAMAGE_WINDOW
	_collision_stack += 1
	var stack_multiplier := 1.0 + COLLISION_STACK_STEP * float(maxi(0, _collision_stack - 1))
	var damage := maxi(1, ceili(float(base_damage) * COLLISION_DAMAGE_RATIO * stack_multiplier))
	_hits_remaining -= damage
	_chain_tag_time = CHAIN_TAG_DURATION
	var direction := global_position - p_source.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = Vector3.RIGHT
	_knockback_dir = direction.normalized()
	_knockback_time = KNOCKBACK_TIME
	velocity = _knockback_dir * KNOCKBACK_SPEED
	chain_triggered.emit(self, p_source)
	if _hits_remaining <= 0:
		_enter_staggered()
	else:
		_flash_hit()


func is_send_off_ready() -> bool:
	return state == State.STAGGERED


func can_be_followup_target() -> bool:
	return state == State.ACTIVE


func start_send_off(_by: Node) -> void:
	if state != State.STAGGERED:
		return
	state = State.SENDING
	sent_off.emit(self)
	_cancel_action()
	_hide_stagger_ring()
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	var tween := create_tween()
	tween.set_parallel(true)
	var visual_target: MeshInstance3D = _sendoff_chunk if is_instance_valid(_sendoff_chunk) else _body_visual
	tween.tween_property(visual_target, "scale", Vector3(0.15, 2.2, 0.15), 0.16)
	tween.tween_property(visual_target, "position:y", 2.0, 0.16)
	tween.chain().tween_callback(queue_free)


func _advance_action(delta: float, p_player: Node3D) -> void:
	_action_timer -= delta
	match _action:
		Action.SWIPE_WINDUP:
			velocity.x = 0.0
			velocity.z = 0.0
			if _action_timer <= 0.0:
				_execute_swipe(p_player)
		Action.POOL_WAIT:
			velocity.x = 0.0
			velocity.z = 0.0
			if _action_timer <= 0.0:
				_explode_pool(p_player)
		Action.LUNGE_CHARGE:
			velocity.x = 0.0
			velocity.z = 0.0
			if _action_timer <= 0.0:
				_start_lunge_move(p_player)
		Action.LUNGE_MOVE:
			velocity.x = _lunge_dir.x * LUNGE_SPEED
			velocity.z = _lunge_dir.z * LUNGE_SPEED
			if p_player and not _lunge_hit_done and global_position.distance_to(p_player.global_position) < 1.5:
				_hit_player(p_player)
				_lunge_hit_done = true
			if _action_timer <= 0.0:
				_action = Action.NONE
				_attack_cooldown = 1.8
				velocity.x = 0.0
				velocity.z = 0.0
		Action.SHOT_CAST:
			velocity.x = 0.0
			velocity.z = 0.0
			if _action_timer <= 0.0:
				_fire_shot(p_player)
		Action.SHOCKWAVE_CAST:
			velocity.x = 0.0
			velocity.z = 0.0
			if _action_timer <= 0.0:
				_explode_shockwave(p_player)


func _try_start_attack(p_player: Node3D) -> void:
	if _attack_cooldown > 0.0 or attack_style == AttackStyle.NONE:
		return
	var distance := _flat_distance(global_position, p_player.global_position)
	match attack_style:
		AttackStyle.SWIPE:
			if distance <= SWIPE_RANGE:
				_start_swipe_windup()
		AttackStyle.POOL:
			if distance <= POOL_RANGE:
				_start_pool(p_player)
		AttackStyle.LUNGE:
			if distance <= LUNGE_RANGE:
				_start_lunge_charge()
		AttackStyle.SHOT:
			if distance <= SHOT_RANGE:
				_start_shot_cast()
		AttackStyle.BOSS:
			_try_boss_attack(p_player, distance)
	if can_use_pool and _action == Action.NONE and _flat_distance(global_position, p_player.global_position) <= POOL_RANGE and randf() > 0.45:
		_start_pool(p_player)


func _start_swipe_windup() -> void:
	_action = Action.SWIPE_WINDUP
	_action_timer = SWIPE_WINDUP
	_show_telegraph()
	_show_melee_arc()


func _execute_swipe(p_player: Node3D) -> void:
	_action = Action.NONE
	_hide_telegraph()
	_attack_cooldown = 1.4
	_flash_melee_arc()
	if p_player and _flat_distance(global_position, p_player.global_position) <= SWIPE_RANGE + 0.7:
		_hit_player(p_player)


func _start_pool(p_player: Node3D) -> void:
	_action = Action.POOL_WAIT
	_action_timer = POOL_WAIT
	_pool_center = p_player.global_position
	_pool_center.y = 0.0
	_spawn_pool_marker()
	_show_telegraph()


func _explode_pool(p_player: Node3D) -> void:
	_action = Action.NONE
	_attack_cooldown = 2.1
	_hide_telegraph()
	_spawn_falling_impact(_pool_center)
	_spawn_light_pillar(_pool_center)
	_spawn_ring_burst(Color("#ffe08a"))
	if p_player:
		var hit_position := p_player.global_position
		hit_position.y = 0.0
		var marker_radius := POOL_RADIUS * maxf(1.0, art_scale)
		if hit_position.distance_to(_pool_center) <= marker_radius:
			_hit_player(p_player)
	_clear_pool_marker()


func _start_lunge_charge() -> void:
	_action = Action.LUNGE_CHARGE
	_action_timer = LUNGE_CHARGE
	_show_telegraph()


func _start_lunge_move(p_player: Node3D) -> void:
	_action = Action.LUNGE_MOVE
	_action_timer = LUNGE_MOVE_TIME
	_lunge_hit_done = false
	_hide_telegraph()
	var direction := Vector3.FORWARD
	if p_player:
		direction = global_position.direction_to(p_player.global_position)
		direction.y = 0.0
		if direction.length_squared() < 0.001:
			direction = Vector3.FORWARD
	_lunge_dir = direction.normalized()


func _start_shot_cast() -> void:
	_action = Action.SHOT_CAST
	_action_timer = SHOT_WINDUP
	_show_telegraph()


func _fire_shot(p_player: Node3D) -> void:
	_action = Action.NONE
	_hide_telegraph()
	_attack_cooldown = 2.2
	if not p_player:
		return
	var direction := global_position.direction_to(p_player.global_position)
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = Vector3.FORWARD
	var orb: Node3D = SpiritOrbScript.new()
	orb.set("art_scale", maxf(1.0, art_scale))
	get_parent().add_child(orb)
	orb.scale = Vector3.ONE * maxf(1.0, art_scale)
	orb.global_position = global_position + Vector3.UP * 1.1
	orb.launch(direction)


func _try_boss_attack(p_player: Node3D, p_distance: float) -> void:
	var scale := maxf(1.0, art_scale)
	var options: Array[int] = []
	if p_distance <= SWIPE_RANGE * scale:
		options.append(AttackStyle.SWIPE)
	if p_distance <= POOL_RANGE * scale:
		options.append(AttackStyle.POOL)
	if p_distance <= LUNGE_RANGE * scale:
		options.append(AttackStyle.LUNGE)
	if p_distance <= SHOT_RANGE * scale:
		options.append(AttackStyle.SHOT)
	if p_distance <= SHOCKWAVE_RADIUS * scale + 1.5:
		options.append(AttackStyle.SHOCKWAVE)
	if options.is_empty():
		options.append(AttackStyle.SHOT)

	var current_style := AttackStyle.NONE
	if _boss_combo_pending != AttackStyle.NONE:
		current_style = _boss_combo_pending
		_boss_combo_pending = AttackStyle.NONE
	else:
		current_style = options[randi_range(0, options.size() - 1)]
		if options.size() > 1 and randf() < 0.35:
			var next_options := options.duplicate()
			next_options.erase(current_style)
			_boss_combo_pending = next_options[randi_range(0, next_options.size() - 1)]

	_start_boss_style(current_style, p_player)
	if _boss_combo_pending != AttackStyle.NONE:
		_attack_cooldown = 0.12


func _start_boss_style(p_style: AttackStyle, p_player: Node3D) -> void:
	match p_style:
		AttackStyle.SWIPE:
			_start_swipe_windup()
		AttackStyle.POOL:
			_start_pool(p_player)
		AttackStyle.LUNGE:
			_start_lunge_charge()
		AttackStyle.SHOT:
			_start_shot_cast()
		AttackStyle.SHOCKWAVE:
			_start_shockwave()
		_:
			_start_swipe_windup()


func _start_shockwave() -> void:
	_action = Action.SHOCKWAVE_CAST
	_action_timer = SHOCKWAVE_WINDUP
	_show_telegraph()
	_spawn_shockwave_marker()


func _explode_shockwave(p_player: Node3D) -> void:
	_action = Action.NONE
	_attack_cooldown = 1.8
	_hide_telegraph()
	_clear_shockwave_marker()
	_spawn_ring_burst(Color("#ff5a4e"))
	if p_player:
		var radius := SHOCKWAVE_RADIUS * maxf(1.0, art_scale)
		if _flat_distance(global_position, p_player.global_position) <= radius:
			_hit_player(p_player)


func _hit_player(p_player: Node3D) -> void:
	if p_player and p_player.has_method("take_hit"):
		p_player.take_hit(self)


func bump_from(p_from: Node3D, p_incoming_velocity: Vector3) -> void:
	if state != State.ACTIVE:
		return
	if p_from and p_from.is_in_group("player"):
		_recent_player_damage = maxi(_recent_player_damage, 1)
		_damage_window_time = COLLISION_DAMAGE_WINDOW
		_collision_stack = 0
	var direction := global_position - p_from.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = Vector3.RIGHT
	var incoming_speed := p_incoming_velocity.length()
	var speed := clampf(incoming_speed * 1.0, 7.0, 19.0)
	_apply_knockback(direction.normalized(), speed)


func push_away_from(p_from: Node3D, p_speed: float) -> void:
	if state != State.ACTIVE:
		return
	var direction := global_position - p_from.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = Vector3.RIGHT
	_apply_knockback(direction.normalized(), p_speed)


func _apply_knockback(p_direction: Vector3, p_speed: float) -> void:
	_cancel_action()
	_knockback_dir = p_direction.normalized()
	_knockback_time = KNOCKBACK_TIME
	velocity = _knockback_dir * p_speed


func _resolve_ghost_bumps() -> void:
	for other in get_tree().get_nodes_in_group("ghosts"):
		if other == self or not is_instance_valid(other):
			continue
		var other_body: CharacterBody3D = other
		if other_body.get("state") != TestGhost.State.ACTIVE:
			continue
		var offset: Vector3 = global_position - other_body.global_position
		offset.y = 0.0
		var other_scale: float = other_body.get("art_scale")
		var min_distance: float = (0.62 * art_scale + 0.62 * other_scale) * 1.35
		if offset.length() >= min_distance or offset.length_squared() < 0.0001:
			continue
		var normal: Vector3 = offset.normalized()
		var separation: float = (min_distance - offset.length()) * 0.5
		global_position += normal * separation
		other_body.global_position -= normal * separation
		var relative_velocity: Vector3 = velocity - other_body.velocity
		var approach: float = relative_velocity.dot(normal)
		if approach < 0.0:
			var impulse: float = -approach * 0.9
			velocity += normal * impulse
			other_body.velocity -= normal * impulse
			if _recent_player_damage > 0 and _damage_window_time > 0.0 and other_body.has_method("on_chain_hit"):
				other_body.on_chain_hit(self)


func _bounce_off_slide_collisions() -> void:
	var flat_velocity := Vector2(velocity.x, velocity.z)
	if flat_velocity.length() < 3.5:
		return
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player"):
			continue
		var normal := collision.get_normal()
		normal.y = 0.0
		if normal.length() < 0.5:
			continue
		normal = normal.normalized()
		var normal_flat := Vector2(normal.x, normal.z)
		if flat_velocity.dot(normal_flat) >= 0.0:
			continue
		var reflected := flat_velocity.bounce(normal_flat) * 0.82
		velocity.x = reflected.x
		velocity.z = reflected.y
		flat_velocity = reflected
		_apply_wall_collision_damage()


func _apply_wall_collision_damage() -> void:
	if state != State.ACTIVE or _collision_damage_cd > 0.0 or _recent_player_damage <= 0 or _damage_window_time <= 0.0:
		return
	_collision_damage_cd = COLLISION_DAMAGE_CD
	_collision_stack += 1
	var stack_multiplier := 1.0 + COLLISION_STACK_STEP * float(maxi(0, _collision_stack - 1))
	var damage := maxi(1, ceili(float(_recent_player_damage) * COLLISION_DAMAGE_RATIO * stack_multiplier))
	_hits_remaining -= damage
	_flash_hit()
	if _hits_remaining <= 0:
		_enter_staggered()


func _chase_player(p_player: Node3D) -> void:
	var direction := global_position.direction_to(p_player.global_position)
	direction.y = 0.0
	velocity.x = direction.x * CHASE_SPEED
	velocity.z = direction.z * CHASE_SPEED
	rotation.y = atan2(velocity.x, velocity.z)


func _cancel_action() -> void:
	_action = Action.NONE
	_action_timer = 0.0
	_boss_combo_pending = AttackStyle.NONE
	_hide_telegraph()
	_clear_pool_marker()
	_clear_shockwave_marker()
	_hide_melee_arc()


func _animate_legs(delta: float) -> void:
	if not is_instance_valid(_leg_left_pivot) or not is_instance_valid(_leg_right_pivot):
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if state == State.ACTIVE and _action == Action.NONE and _knockback_time <= 0.0 and horizontal_speed > 0.4:
		_step_time += horizontal_speed * delta * 0.18
		_leg_left_pivot.rotation.x = sin(_step_time) * 0.42 - 0.05
		_leg_right_pivot.rotation.x = sin(_step_time + PI) * 0.42 - 0.05
	else:
		_leg_left_pivot.rotation.x = lerpf(_leg_left_pivot.rotation.x, 0.08, 0.2)
		_leg_right_pivot.rotation.x = lerpf(_leg_right_pivot.rotation.x, -0.08, 0.2)


func _show_telegraph() -> void:
	_pose_for_current_attack()


func _hide_telegraph() -> void:
	_reset_attack_pose()


func _pose_for_current_attack() -> void:
	match _action:
		Action.SWIPE_WINDUP, Action.LUNGE_CHARGE:
			_arm_left_pivot.rotation.x = -0.9
			_arm_right_pivot.rotation.x = -0.9
		Action.SHOT_CAST:
			_arm_right_pivot.rotation.x = -2.1
			_arm_left_pivot.rotation.x = 0.35
		Action.POOL_WAIT, Action.SHOCKWAVE_CAST:
			_arm_left_pivot.rotation.x = -2.3
			_arm_right_pivot.rotation.x = -2.3
		_:
			_reset_attack_pose()


func _reset_attack_pose() -> void:
	if not is_instance_valid(_arm_left_pivot) or not is_instance_valid(_arm_right_pivot):
		return
	_arm_left_pivot.rotation.x = 0.45
	_arm_left_pivot.rotation.z = 0.12
	_arm_right_pivot.rotation.x = 0.45
	_arm_right_pivot.rotation.z = -0.12


func _show_melee_arc() -> void:
	if is_instance_valid(_melee_arc):
		_melee_arc.visible = true


func _flash_melee_arc() -> void:
	if not is_instance_valid(_melee_arc):
		return
	_melee_arc.visible = true
	_melee_arc.scale = Vector3(0.7, 0.7, 0.7)
	var tween := create_tween()
	tween.tween_property(_melee_arc, "scale", Vector3(2.1, 2.1, 1.0), 0.1)
	tween.tween_callback(_hide_melee_arc)


func _hide_melee_arc() -> void:
	if is_instance_valid(_melee_arc):
		_melee_arc.visible = false


func _spawn_pool_marker() -> void:
	if _pool_marker:
		return
	var marker_radius := POOL_RADIUS * maxf(1.0, art_scale)
	var marker := PlaceholderKit.box("art_key_ghost_pool_marker", Color("#ff4141"), Vector3(marker_radius * 2.0, 0.08, marker_radius * 2.0))
	marker.position = _pool_center + Vector3(0.0, 0.04, 0.0)
	_pool_marker = marker
	if is_inside_tree():
		get_parent().add_child(marker)


func _clear_pool_marker() -> void:
	if is_instance_valid(_pool_marker):
		_pool_marker.queue_free()
	_pool_marker = null


func _spawn_falling_impact(p_position: Vector3) -> void:
	if not is_inside_tree():
		return
	var impact := MeshInstance3D.new()
	impact.name = "art_key_ghost_pool_impact"
	var impact_radius := 1.3 * maxf(1.0, art_scale)
	impact.mesh = PlaceholderKit.sphere_mesh(impact_radius, impact_radius * 2.0)
	impact.material_override = PlaceholderKit.emissive_material(Color("#ffd166"), 2.6)
	get_parent().add_child(impact)
	impact.global_position = p_position + Vector3(0.0, 5.0, 0.0)
	var tween := create_tween()
	tween.tween_property(impact, "global_position", p_position + Vector3(0.0, 0.4, 0.0), 0.2)
	tween.chain().tween_callback(impact.queue_free)


func _spawn_light_pillar(p_position: Vector3) -> void:
	if not is_inside_tree():
		return
	var pillar := MeshInstance3D.new()
	pillar.name = "art_key_ghost_pool_pillar"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.4 * maxf(1.0, art_scale)
	cylinder.bottom_radius = 1.4 * maxf(1.0, art_scale)
	cylinder.height = 10.0
	pillar.mesh = cylinder
	pillar.material_override = PlaceholderKit.material_alpha(Color("#fff0b0"), 0.85)
	get_parent().add_child(pillar)
	pillar.global_position = p_position + Vector3(0.0, 5.0, 0.0)
	pillar.scale = Vector3(0.05, 0.05, 0.05)
	var tween := create_tween()
	tween.tween_property(pillar, "scale", Vector3.ONE, 0.18)
	tween.chain().tween_interval(0.24)
	tween.chain().tween_callback(pillar.queue_free)


func _spawn_shockwave_marker() -> void:
	if _shockwave_marker:
		return
	var radius := SHOCKWAVE_RADIUS * maxf(1.0, art_scale)
	_shockwave_marker = PlaceholderKit.ground_quad("art_key_ghost_shockwave_marker", Color("#ff4a45"), Vector2(radius * 2.0, radius * 2.0))
	if is_inside_tree():
		get_parent().add_child(_shockwave_marker)
	_shockwave_marker.global_position = global_position
	_shockwave_marker.global_position.y = 0.05
	_shockwave_marker.scale = Vector3(0.05, 0.05, 0.05)
	var tween := create_tween()
	tween.tween_property(_shockwave_marker, "scale", Vector3.ONE, SHOCKWAVE_WINDUP)


func _clear_shockwave_marker() -> void:
	if is_instance_valid(_shockwave_marker):
		_shockwave_marker.queue_free()
	_shockwave_marker = null


func _spawn_ring_burst(p_color: Color) -> void:
	if not is_inside_tree():
		return
	var effect := PlaceholderKit.ground_quad("art_key_ghost_ring_burst", p_color, Vector2(4.0, 4.0) * maxf(1.0, art_scale))
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.global_position.y = 0.08
	effect.scale = Vector3(0.2, 0.2, 0.2)
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector3(3.5, 3.5, 3.5), 0.28)
	tween.tween_callback(effect.queue_free)


func _flat_distance(p_a: Vector3, p_b: Vector3) -> float:
	var a := p_a
	var b := p_b
	a.y = 0.0
	b.y = 0.0
	return a.distance_to(b)


func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _enter_staggered() -> void:
	state = State.STAGGERED
	_cancel_action()
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	_burst_into_sendoff_chunk()
	_show_stagger_ring()


func _burst_into_sendoff_chunk() -> void:
	if is_instance_valid(_arm_left_pivot):
		_arm_left_pivot.visible = false
	if is_instance_valid(_arm_right_pivot):
		_arm_right_pivot.visible = false
	if is_instance_valid(_leg_left_pivot):
		_leg_left_pivot.visible = false
	if is_instance_valid(_leg_right_pivot):
		_leg_right_pivot.visible = false
	if is_instance_valid(_weapon_visual):
		_weapon_visual.visible = false
	if is_instance_valid(_weapon_orb):
		_weapon_orb.visible = false

	if not is_inside_tree():
		return
	var parent := get_parent()
	var burst_center := global_position + Vector3(0.0, 0.75 * art_scale, 0.0)

	if is_instance_valid(_body_visual):
		_set_body_color(Color("#ffffff"))
		var body_tween := create_tween()
		body_tween.tween_property(_body_visual, "scale", Vector3(1.7, 1.7, 1.7), 0.07)
		body_tween.tween_callback(_hide_burst_body)

	var flash := PlaceholderKit.ground_quad("art_key_ghost_burst_flash", Color("#fff0b0"), Vector2(1.8, 1.8) * art_scale)
	parent.add_child(flash)
	flash.global_position = burst_center
	flash.global_position.y = 0.08
	var flash_tween := create_tween()
	flash_tween.tween_property(flash, "scale", Vector3(3.2, 3.2, 3.2), 0.14)
	flash_tween.tween_callback(flash.queue_free)

	var fragment_colors: Array[Color] = [Color("#6f7d9c"), Color("#9aa6bb"), Color("#ffe08a")]
	var fragment_count := randi_range(2, 3)
	for index in range(fragment_count):
		var fragment_size := randf_range(0.16, 0.32) * art_scale
		var fragment := PlaceholderKit.box("art_key_ghost_burst_%d" % index, fragment_colors[index % fragment_colors.size()], Vector3.ONE * fragment_size)
		parent.add_child(fragment)
		fragment.global_position = burst_center + Vector3(randf_range(-0.25, 0.25), 0.0, randf_range(-0.25, 0.25))
		fragment.scale = Vector3.ZERO
		var direction := Vector3(randf_range(-1.0, 1.0), randf_range(0.35, 1.0), randf_range(-1.0, 1.0)).normalized()
		var target_position := fragment.global_position + direction * randf_range(1.8, 3.2) * art_scale
		var fragment_tween := create_tween()
		fragment_tween.set_parallel(true)
		fragment_tween.tween_property(fragment, "global_position", target_position, 0.24)
		fragment_tween.tween_property(fragment, "rotation_degrees", Vector3(randf_range(-180.0, 180.0), randf_range(-180.0, 180.0), randf_range(-180.0, 180.0)), 0.24)
		fragment_tween.tween_property(fragment, "scale", Vector3.ONE, 0.16)
		fragment_tween.chain().tween_property(fragment, "scale", Vector3.ZERO, 0.08)
		fragment_tween.chain().tween_callback(fragment.queue_free)

	_sendoff_chunk = PlaceholderKit.box("art_key_ghost_sendoff_chunk", Color("#ffe08a"), Vector3(0.62, 0.5, 0.62) * art_scale)
	_sendoff_chunk.position = Vector3(0.0, 0.32 * art_scale, 0.0)
	_sendoff_chunk.scale = Vector3(0.1, 0.1, 0.1)
	add_child(_sendoff_chunk)
	var chunk_tween := create_tween()
	chunk_tween.tween_interval(0.1)
	chunk_tween.tween_property(_sendoff_chunk, "scale", Vector3.ONE, 0.14)


func _hide_burst_body() -> void:
	if is_instance_valid(_body_visual):
		_body_visual.visible = false


func _show_stagger_ring() -> void:
	if is_instance_valid(_stagger_ring):
		_stagger_ring.visible = true


func _hide_stagger_ring() -> void:
	if is_instance_valid(_stagger_ring):
		_stagger_ring.visible = false


func _flash_hit() -> void:
	var material := PlaceholderKit.material(Color("#f4f7ff"))
	_body_visual.material_override = material
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(_body_visual) and state == State.ACTIVE:
		_set_body_color(Color("#6f7d9c"))


func _set_body_color(p_color: Color) -> void:
	if is_instance_valid(_body_visual):
		_body_visual.material_override = PlaceholderKit.material(p_color)


func _setup_collision() -> void:
	var shape := SphereShape3D.new()
	shape.radius = 0.62 * art_scale
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.7 * art_scale
	add_child(collision)


func _setup_art() -> void:
	var host := Node3D.new()
	host.name = "ArtHost"
	add_child(host)
	var body := PlaceholderKit.box("art_key_ghost_body", Color("#6f7d9c"), Vector3(0.86, 1.12, 0.86) * art_scale)
	body.position.y = 0.74 * art_scale
	host.add_child(body)
	var eye_left := PlaceholderKit.box("art_key_ghost_eye_l", Color("#ffffff"), Vector3(0.16, 0.16, 0.12) * art_scale)
	eye_left.position = Vector3(-0.18, 1.02, -0.44) * art_scale
	host.add_child(eye_left)
	var eye_right := PlaceholderKit.box("art_key_ghost_eye_r", Color("#ffffff"), Vector3(0.16, 0.16, 0.12) * art_scale)
	eye_right.position = Vector3(0.18, 1.02, -0.44) * art_scale
	host.add_child(eye_right)
	_body_visual = body

	_arm_left_pivot = Node3D.new()
	_arm_left_pivot.name = "ArmLeftPivot"
	_arm_left_pivot.position = Vector3(-0.46, 1.08, -0.05) * art_scale
	host.add_child(_arm_left_pivot)
	var arm_left := PlaceholderKit.box("art_key_ghost_arm_l", Color("#5d6882"), Vector3(0.15, 0.72, 0.15) * art_scale)
	arm_left.position = Vector3(0.0, -0.3, -0.18) * art_scale
	_arm_left_pivot.add_child(arm_left)

	_arm_right_pivot = Node3D.new()
	_arm_right_pivot.name = "ArmRightPivot"
	_arm_right_pivot.position = Vector3(0.46, 1.08, -0.05) * art_scale
	host.add_child(_arm_right_pivot)
	var arm_right := PlaceholderKit.box("art_key_ghost_arm_r", Color("#5d6882"), Vector3(0.15, 0.72, 0.15) * art_scale)
	arm_right.position = Vector3(0.0, -0.3, -0.18) * art_scale
	_arm_right_pivot.add_child(arm_right)
	_setup_legs(host)
	_build_weapon()
	_reset_attack_pose()


func _setup_legs(p_host: Node3D) -> void:
	_leg_left_pivot = Node3D.new()
	_leg_left_pivot.name = "LegLeftPivot"
	_leg_left_pivot.position = Vector3(-0.25, 0.42, -0.02) * art_scale
	p_host.add_child(_leg_left_pivot)
	var leg_left := PlaceholderKit.box("art_key_ghost_leg_l", Color("#4b546a"), Vector3(0.17, 0.56, 0.18) * art_scale)
	leg_left.position = Vector3(0.0, -0.28, 0.0) * art_scale
	_leg_left_pivot.add_child(leg_left)

	_leg_right_pivot = Node3D.new()
	_leg_right_pivot.name = "LegRightPivot"
	_leg_right_pivot.position = Vector3(0.25, 0.42, -0.02) * art_scale
	p_host.add_child(_leg_right_pivot)
	var leg_right := PlaceholderKit.box("art_key_ghost_leg_r", Color("#4b546a"), Vector3(0.17, 0.56, 0.18) * art_scale)
	leg_right.position = Vector3(0.0, -0.28, 0.0) * art_scale
	_leg_right_pivot.add_child(leg_right)
	_leg_left_pivot.rotation.x = 0.08
	_leg_right_pivot.rotation.x = -0.08


func _build_weapon() -> void:
	if not is_instance_valid(_arm_right_pivot):
		return
	var scale := maxf(1.0, art_scale)
	var length := 1.5 * scale
	var blade_size := Vector3(0.16, 0.16, length)
	match attack_style:
		AttackStyle.SWIPE:
			blade_size = Vector3(0.62, 0.2, 1.25) * scale
		AttackStyle.LUNGE:
			blade_size = Vector3(0.16, 0.16, 2.3) * scale
		AttackStyle.SHOT:
			blade_size = Vector3(0.16, 0.16, 1.7) * scale
		AttackStyle.POOL, AttackStyle.SHOCKWAVE, AttackStyle.BOSS:
			blade_size = Vector3(0.62, 0.24, 0.9) * scale
	_weapon_visual = PlaceholderKit.box("art_key_ghost_weapon", Color("#4c5566"), blade_size)
	_weapon_visual.position = Vector3(0.0, -0.2 * scale, -blade_size.z * 0.55)
	_arm_right_pivot.add_child(_weapon_visual)
	if attack_style == AttackStyle.SHOT:
		_weapon_orb = PlaceholderKit.box("art_key_ghost_weapon_orb", Color("#b7e7ff"), Vector3.ONE * 0.34 * scale)
		_weapon_orb.position = Vector3(0.0, -0.2 * scale, -1.45 * scale)
		_arm_right_pivot.add_child(_weapon_orb)


func _setup_attack_visual() -> void:
	var visual_scale := maxf(1.0, art_scale)
	_melee_arc = PlaceholderKit.ground_quad("art_key_ghost_melee_arc", Color("#ff5347"), Vector2(3.2, 2.4) * visual_scale)
	_melee_arc.position = Vector3(0.0, 0.04, -2.3 * visual_scale)
	_melee_arc.visible = false
	add_child(_melee_arc)

	_stagger_ring = PlaceholderKit.ground_quad("art_key_ghost_sendoff_ring", Color("#ffe08a"), Vector2(2.0, 2.0) * visual_scale)
	_stagger_ring.position = Vector3(0.0, 0.035, 0.0)
	_stagger_ring.visible = false
	add_child(_stagger_ring)
