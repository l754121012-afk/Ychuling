class_name PlayerController
extends CharacterBody3D

signal sendoff_performed(target: Node)
signal health_changed(health: int, max_health: int)
signal momentum_changed(momentum: int, max_momentum: int)
signal defeated()
signal stamina_changed(stamina: float, max_stamina: float)
signal beans_changed(beans: int, max_beans: int)
signal enhanced_sweep_ready()
signal enhanced_sweep_used()
signal followup_available()

const MOVE_SPEED := 6.4
const ACCELERATION := 20.0
const AIR_ACCELERATION := 8.0
const GRAVITY := 24.0
const JUMP_VELOCITY := 8.5
const DASH_SPEED := 16.5
const DASH_TIME := 0.37
const DASH_COOLDOWN := 0.5
const ATTACK_TIME := 0.1
const ATTACK_COOLDOWN := 0.22
const FOLLOWUP_WINDOW_TIME := 2.0
const FOLLOWUP_WINDUP_TIME := 0.22
const FOLLOWUP_SPIN_TIME := 0.55
const FOLLOWUP_REAR_DISTANCE := 1.1
const FOLLOWUP_PHASE_WINDUP := 0
const FOLLOWUP_PHASE_BLINK := 1
const FOLLOWUP_PHASE_SPIN := 2
const HEAVY_TIME := 0.22
const HEAVY_COOLDOWN := 0.9
const HEAVY_BASE_RADIUS := 3.8
const HEAVY_RADIUS_PER_MOMENTUM := 0.75
const HEAVY_BASE_PUSH := 22.0
const HEAVY_PUSH_PER_MOMENTUM := 4.0
const Q_BACKSTEP_SPEED := 9.0
const Q_BACKSTEP_TIME := 0.12
const Q_PAUSE_TIME := 0.1
const Q_FORWARD_SPEED := 20.0
const Q_FORWARD_TIME := 0.26
const MAX_MOMENTUM := 3
const MAX_STAMINA := 15.0
const DASH_STAMINA_COST := 1.0
const HEAVY_STAMINA_COST := 3.0
const STAMINA_REGEN_DELAY := 0.75
const STAMINA_REGEN_RATE := 2.0
const MAX_BEANS := 3
const HEAL_HOLD_TIME := 0.8
const HEAL_INTERVAL := 0.65
const INTERACT_RANGE := 3.4
const MAX_HEALTH := 5
const HIT_INVULN_TIME := 1.0
const HITSTUN_TIME := 0.24
const WALL_BOUNCE_DAMPING := 0.78
const STEP_UP_HEIGHT := 0.42
const STEP_UP_MIN_RISE := 0.04
const STEP_UP_MIN_FORWARD := 0.42
const STEP_UP_DROP_PROBE := 0.12
const STEP_UP_MAX_OBSTACLE_NORMAL_Y := 0.5
const STEP_UP_MIN_FLOOR_NORMAL_Y := 0.55
const SPIN_TIME := 2.0
const SPIN_MOVE_SPEED := 4.8
const SPIN_ROTATION_SPEED := 12.0
const SPIN_DAMAGE_INTERVAL := 0.35
const SPIN_COOLDOWN := 0.8
const SPIN_CHARGE_TIME := 0.6
const SPIN_CHARGE_MOVE_SPEED := 4.0

enum State {
	NORMAL,
	ATTACK,
	DASH,
	SPIN_CHARGE,
	SPIN,
	FOLLOWUP,
	HEAVY,
	DASH_TECH,
}

var _state := State.NORMAL
var _attack_timer := 0.0
var _attack_cooldown := 0.0
var _dash_timer := 0.0
var _dash_cooldown := 0.0
var _dash_dir := Vector3.FORWARD
var _facing := Vector3.FORWARD
var _attack_hit_done := false
var _spin_time := 0.0
var _spin_interval := 0.0
var _spin_cooldown := 0.0
var _spin_charge_time := 0.0
var _spin_charge_ready := false
var _spin_held := false
var _spin_super_armor := false
var _followup_target: Node3D
var _followup_window := 0.0
var _followup_time := 0.0
var _followup_phase := FOLLOWUP_PHASE_WINDUP
var _followup_spin_interval := 0.0
var _momentum := 0
var _heavy_time := 0.0
var _heavy_cooldown := 0.0
var _heavy_hit_done := false
var _heavy_radius := HEAVY_BASE_RADIUS
var _heavy_push_speed := HEAVY_BASE_PUSH
var _q_phase := 0
var _q_timer := 0.0
var _q_dir := Vector3.FORWARD
var stamina := MAX_STAMINA
var _stamina_regen_timer := 0.0
var _defeated := false
var beans := 0
var _heal_hold_time := 0.0
var _heal_timer := 0.0
var health := MAX_HEALTH
var spawn_point := Vector3.ZERO
var _invuln_time := 0.0
var _hitstun_time := 0.0
var _hurt_timer := 0.0
var _bounce_time := 0.0
var _pre_move_velocity := Vector3.ZERO
var _bounce_cooldown := 0.0

var _broom_pivot: Node3D
var _slash_area: Area3D
var _spin_area: Area3D
var _spin_ring: MeshInstance3D
var _followup_flash: MeshInstance3D
var _body_visual: MeshInstance3D
var _broom_visuals: Array[MeshInstance3D] = []
var _broom_default_colors: Array[Color] = []
var _enhanced_sweep := false
var base_sweep_damage := 1


func _ready() -> void:
	add_to_group("player")
	_setup_collision()
	_setup_art()
	_setup_slash()
	_setup_spin()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_spin_held = event.pressed


func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_tick_timers(delta)
	_handle_state_input(delta)
	if Input.is_action_just_pressed("spin") and _followup_window > 0.0 and _try_start_followup():
		_pre_move_velocity = velocity
		move_and_slide()
		return

	if _hitstun_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 22.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 22.0 * delta)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		_pre_move_velocity = velocity
		move_and_slide()
		_bounce_and_bump_from_slides()
		return

	if _bounce_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	if _state == State.SPIN_CHARGE:
		_tick_spin_charge(delta)
		_pre_move_velocity = velocity
		move_and_slide()
		return

	if _state == State.SPIN:
		_tick_spin(delta)
		_pre_move_velocity = velocity
		move_and_slide()
		return

	if _state == State.FOLLOWUP:
		_tick_followup(delta)
		_pre_move_velocity = velocity
		move_and_slide()
		return

	if _state == State.HEAVY:
		_tick_heavy(delta)
		_pre_move_velocity = velocity
		move_and_slide()
		return

	if _state == State.DASH_TECH:
		_tick_q_tech(delta)
		_pre_move_velocity = velocity
		move_and_slide()
		return

	if _state != State.DASH:
		var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var wish := Vector3(input.x, 0.0, input.y)
		if wish.length_squared() > 0.001:
			_facing = wish.normalized()

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		if not is_on_floor():
			velocity.y -= GRAVITY * delta

		var target := wish * MOVE_SPEED
		var accel := ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, target.x, accel * delta)
		velocity.z = move_toward(velocity.z, target.z, accel * delta)

		if Input.is_action_just_pressed("dash") and _dash_cooldown <= 0.0 and wish.length_squared() > 0.001:
			_start_dash(wish.normalized())

		if Input.is_action_just_pressed("q_dash_tech"):
			_start_q_tech(_facing)

		if Input.is_action_just_pressed("attack") and _attack_cooldown <= 0.0:
			_start_attack()

		if Input.is_action_just_pressed("interact"):
			_try_send_off()

		if Input.is_action_just_pressed("spin"):
			_start_spin_charge()

		_update_facing()

	_pre_move_velocity = velocity
	move_and_slide()
	_bounce_and_bump_from_slides()


func _tick_timers(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_invuln_time = maxf(0.0, _invuln_time - delta)
	_hitstun_time = maxf(0.0, _hitstun_time - delta)
	_bounce_time = maxf(0.0, _bounce_time - delta)
	_bounce_cooldown = maxf(0.0, _bounce_cooldown - delta)
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0 and is_instance_valid(_body_visual):
			_body_visual.material_override = PlaceholderKit.material(Color("#cfe06a"))
	_spin_cooldown = maxf(0.0, _spin_cooldown - delta)
	_heavy_cooldown = maxf(0.0, _heavy_cooldown - delta)
	if _state == State.NORMAL and not _defeated and beans > 0 and health < MAX_HEALTH:
		var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var is_still := move_input.length_squared() < 0.001
		if is_still and Input.is_action_pressed("heal"):
			_heal_hold_time += delta
			if _heal_hold_time >= HEAL_HOLD_TIME:
				_heal_timer -= delta
				if _heal_timer <= 0.0:
					_heal_timer = HEAL_INTERVAL
					health = mini(MAX_HEALTH, health + 1)
					beans = maxi(0, beans - 1)
					health_changed.emit(health, MAX_HEALTH)
					beans_changed.emit(beans, MAX_BEANS)
			else:
				_heal_timer = 0.0
		else:
			_heal_hold_time = 0.0
			_heal_timer = 0.0
	else:
		_heal_hold_time = 0.0
		_heal_timer = 0.0
	if stamina < MAX_STAMINA:
		_stamina_regen_timer -= delta
		if _stamina_regen_timer <= 0.0:
			var previous_stamina := stamina
			stamina = minf(MAX_STAMINA, stamina + STAMINA_REGEN_RATE * delta)
			if stamina != previous_stamina:
				stamina_changed.emit(stamina, MAX_STAMINA)
	if _followup_window > 0.0:
		_followup_window -= delta
		if _followup_window <= 0.0:
			_followup_target = null
			if is_instance_valid(_followup_flash):
				_followup_flash.visible = false
	if _state == State.ATTACK:
		_attack_timer -= delta
		if _broom_pivot:
			_broom_pivot.rotation.y = lerpf(-1.2, 0.3, clampf(1.0 - _attack_timer / ATTACK_TIME, 0.0, 1.0))
		if _attack_timer <= 0.0:
			_state = State.NORMAL
			if _broom_pivot:
				_broom_pivot.rotation.y = 0.0
		elif not _attack_hit_done and _attack_timer <= ATTACK_TIME * 0.35:
			_apply_slash_damage()
			_attack_hit_done = true
	elif _state == State.DASH:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_state = State.NORMAL
			var flat_velocity := Vector2(velocity.x, velocity.z)
			if flat_velocity.length() > 8.5:
				var speed_scale := 8.5 / flat_velocity.length()
				velocity.x *= speed_scale
				velocity.z *= speed_scale


func _try_step_up(p_motion: Vector3) -> bool:
	var horizontal_motion := Vector3(p_motion.x, 0.0, p_motion.z)
	if horizontal_motion.length_squared() < 0.0001:
		return false
	var step_motion := horizontal_motion.normalized() * maxf(horizontal_motion.length(), STEP_UP_MIN_FORWARD)

	var obstacle := KinematicCollision3D.new()
	if not test_move(transform, step_motion, obstacle, 0.001, true, 4):
		return false
	var found_ledge := false
	for index in range(obstacle.get_collision_count()):
		if obstacle.get_collider(index) is CharacterBody3D:
			continue
		# Slopes are already handled by move_and_slide; only lift onto near-vertical ledges.
		if obstacle.get_normal(index).y <= STEP_UP_MAX_OBSTACLE_NORMAL_Y:
			found_ledge = true
			break
	if not found_ledge:
		return false

	var ceiling := KinematicCollision3D.new()
	if test_move(transform, Vector3.UP * STEP_UP_HEIGHT, ceiling):
		return false

	var elevated := transform.translated(Vector3.UP * STEP_UP_HEIGHT)
	var forward := KinematicCollision3D.new()
	if test_move(elevated, step_motion, forward):
		return false

	var landing := KinematicCollision3D.new()
	if not test_move(
		elevated.translated(step_motion),
		Vector3.DOWN * (STEP_UP_HEIGHT + STEP_UP_DROP_PROBE),
		landing
	):
		return false
	if landing.get_normal().y < STEP_UP_MIN_FLOOR_NORMAL_Y:
		return false

	var drop := -landing.get_travel().y
	var rise := STEP_UP_HEIGHT - drop
	if rise < STEP_UP_MIN_RISE or rise > STEP_UP_HEIGHT:
		return false

	global_position = elevated.translated(step_motion).origin + Vector3.DOWN * drop
	velocity.y = 0.0
	return true


func _handle_state_input(delta: float) -> void:
	if _state == State.DASH:
		if Input.is_action_just_pressed("attack") and _attack_cooldown <= 0.0:
			_start_attack()
			return
		var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var wish := Vector3(input.x, 0.0, input.y)
		if wish.length_squared() > 0.001:
			var desired := wish.normalized()
			var steer := clampf(18.0 * delta, 0.0, 0.55)
			var blended := _dash_dir.lerp(desired, steer)
			if blended.length_squared() < 0.001:
				blended = desired
			_dash_dir = blended.normalized()
			var alignment := maxf(_dash_dir.dot(desired), 0.0)
			var speed_factor := lerpf(0.72, 1.0, alignment)
			velocity.x = _dash_dir.x * DASH_SPEED * speed_factor
			velocity.z = _dash_dir.z * DASH_SPEED * speed_factor
		else:
			velocity.x = _dash_dir.x * DASH_SPEED
			velocity.z = _dash_dir.z * DASH_SPEED
		velocity.y = 0.0


func _start_dash(p_dir: Vector3) -> void:
	_state = State.DASH
	_dash_timer = DASH_TIME
	_dash_cooldown = DASH_COOLDOWN
	_dash_dir = p_dir
	velocity = Vector3(p_dir.x * DASH_SPEED, 0.0, p_dir.z * DASH_SPEED)


func _start_q_tech(p_dir: Vector3) -> void:
	if _state != State.NORMAL or not try_spend_stamina(DASH_STAMINA_COST):
		return
	var direction := p_dir
	if direction.length_squared() < 0.001:
		direction = _facing
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = Vector3.FORWARD
	_q_dir = direction.normalized()
	_q_phase = 0
	_q_timer = Q_BACKSTEP_TIME
	_state = State.DASH_TECH
	velocity = -_q_dir * Q_BACKSTEP_SPEED


func _tick_q_tech(delta: float) -> void:
	_q_timer -= delta
	if _q_phase == 0:
		velocity.x = -_q_dir.x * Q_BACKSTEP_SPEED
		velocity.z = -_q_dir.z * Q_BACKSTEP_SPEED
		if _q_timer <= 0.0:
			_q_phase = 1
			_q_timer = Q_PAUSE_TIME
			velocity.x = 0.0
			velocity.z = 0.0
	elif _q_phase == 1:
		velocity.x = 0.0
		velocity.z = 0.0
		if _q_timer <= 0.0:
			_q_phase = 2
			_q_timer = Q_FORWARD_TIME
			velocity.x = _q_dir.x * Q_FORWARD_SPEED
			velocity.z = _q_dir.z * Q_FORWARD_SPEED
	elif _q_phase == 2:
		velocity.x = _q_dir.x * Q_FORWARD_SPEED
		velocity.z = _q_dir.z * Q_FORWARD_SPEED
		if _q_timer <= 0.0:
			_state = State.NORMAL
			velocity.x = 0.0
			velocity.z = 0.0


func _start_spin_charge() -> void:
	if _state != State.NORMAL or _spin_cooldown > 0.0:
		return
	_state = State.SPIN_CHARGE
	_spin_charge_time = 0.0
	_spin_charge_ready = false
	_spin_ring.visible = true
	_spin_ring.scale = Vector3(0.45, 0.45, 0.45)
	_spin_ring.material_override = PlaceholderKit.material_alpha(Color("#ffe45e"), 0.5)


func set_spin_held(p_held: bool) -> void:
	_spin_held = p_held


func _tick_spin_charge(delta: float) -> void:
	if not _spin_held:
		_spin_ring.visible = false
		_state = State.NORMAL
		if _spin_charge_time >= SPIN_CHARGE_TIME or _spin_charge_ready:
			_start_spin()
		else:
			_start_heavy_sweep()
		return
	_spin_charge_time += delta
	var progress := clampf(_spin_charge_time / SPIN_CHARGE_TIME, 0.0, 1.0)
	_spin_ring.scale = Vector3(0.45 + progress * 1.2, 0.45 + progress * 1.2, 0.45 + progress * 1.2)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var wish := Vector3(input.x, 0.0, input.y)
	var target := wish * SPIN_CHARGE_MOVE_SPEED
	velocity.x = move_toward(velocity.x, target.x, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCELERATION * delta)
	if _spin_charge_time >= SPIN_CHARGE_TIME and not _spin_charge_ready:
		_spin_charge_ready = true
		_spin_super_armor = true
		_spin_ring.material_override = PlaceholderKit.material_alpha(Color("#ff7043"), 0.72)
		if is_instance_valid(_body_visual):
			_body_visual.material_override = PlaceholderKit.material(Color("#ffe08a"))


func _cancel_spin_charge() -> void:
	_state = State.NORMAL
	_spin_ring.visible = false
	_spin_super_armor = false
	if is_instance_valid(_body_visual):
		_body_visual.material_override = PlaceholderKit.material(Color("#cfe06a"))


func _start_spin() -> void:
	if _state != State.NORMAL and _state != State.SPIN_CHARGE:
		return
	_state = State.SPIN
	_spin_time = SPIN_TIME
	_spin_interval = 0.0
	_spin_cooldown = SPIN_COOLDOWN
	_spin_ring.scale = Vector3(1.0, 1.0, 1.0)
	_spin_ring.visible = true
	_spin_area.monitoring = true
	if is_instance_valid(_body_visual):
		_body_visual.material_override = PlaceholderKit.material(Color("#cfe06a"))


func _tick_spin(delta: float) -> void:
	_spin_time -= delta
	_spin_interval -= delta
	rotation.y += delta * SPIN_ROTATION_SPEED
	if _spin_interval <= 0.0:
		_apply_spin_damage()
		_spin_interval = SPIN_DAMAGE_INTERVAL

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var wish := Vector3(input.x, 0.0, input.y)
	var target := wish * SPIN_MOVE_SPEED
	velocity.x = move_toward(velocity.x, target.x, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCELERATION * delta)
	velocity.y = 0.0
	if _spin_time <= 0.0:
		_stop_spin()


func _apply_spin_damage() -> void:
	for body in _spin_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("on_cleaned"):
			body.on_cleaned(self)
			add_bean(1)


func _stop_spin() -> void:
	_state = State.NORMAL
	_spin_ring.visible = false
	_spin_super_armor = false
	_spin_area.monitoring = false
	velocity.x = 0.0
	velocity.z = 0.0


func _mark_followup_target(p_target: Node3D) -> void:
	if _is_followup_target_valid_for(p_target):
		_followup_target = p_target
		_followup_window = FOLLOWUP_WINDOW_TIME
		if is_instance_valid(_followup_flash):
			_followup_flash.visible = true
			_followup_flash.scale = Vector3(0.9, 0.9, 0.9)
			_followup_flash.material_override = PlaceholderKit.material_alpha(Color("#ffffff"), 0.72)
		followup_available.emit()


func _is_followup_target_valid_for(p_target: Node3D) -> bool:
	if not is_instance_valid(p_target):
		return false
	if p_target.has_method("can_be_followup_target") and p_target.can_be_followup_target():
		return true
	if p_target.has_method("is_send_off_ready") and p_target.is_send_off_ready():
		return true
	return false


func _try_start_followup() -> bool:
	if _followup_window <= 0.0 or not _followup_target:
		return false
	if not _is_followup_target_valid_for(_followup_target):
		_followup_target = null
		_followup_window = 0.0
		if is_instance_valid(_followup_flash):
			_followup_flash.visible = false
		return false
	_state = State.FOLLOWUP
	_followup_window = 0.0
	_followup_phase = FOLLOWUP_PHASE_WINDUP
	_followup_time = FOLLOWUP_WINDUP_TIME
	_followup_spin_interval = 0.0
	_attack_timer = 0.0
	_dash_timer = 0.0
	_spin_charge_ready = false
	_spin_ring.visible = false
	_followup_flash.visible = true
	_followup_flash.scale = Vector3(0.45, 0.45, 0.45)
	if is_instance_valid(_body_visual):
		_body_visual.scale = Vector3(0.82, 1.18, 0.82)
	_spin_area.monitoring = false
	velocity = Vector3.ZERO
	return true


func _tick_followup(delta: float) -> void:
	if not is_instance_valid(_followup_target):
		_end_followup()
		return
	if _followup_phase == FOLLOWUP_PHASE_WINDUP:
		if not _is_followup_target_valid_for(_followup_target):
			_end_followup()
			return
		_followup_time -= delta
		if _followup_flash:
			var prep_progress := clampf(1.0 - _followup_time / FOLLOWUP_WINDUP_TIME, 0.0, 1.0)
			_followup_flash.scale = Vector3.ONE * lerpf(0.45, 2.1, prep_progress)
		velocity = Vector3.ZERO
		if _followup_time <= 0.0:
			_blink_behind_target()
			_followup_phase = FOLLOWUP_PHASE_BLINK
	elif _followup_phase == FOLLOWUP_PHASE_BLINK:
		_followup_phase = FOLLOWUP_PHASE_SPIN
		_followup_time = FOLLOWUP_SPIN_TIME
		_followup_spin_interval = 0.0
		_spin_ring.visible = true
		_spin_ring.scale = Vector3(1.3, 1.3, 1.3)
		_spin_area.monitoring = true
		if is_instance_valid(_body_visual):
			_body_visual.scale = Vector3.ONE
	elif _followup_phase == FOLLOWUP_PHASE_SPIN:
		_followup_time -= delta
		_followup_spin_interval -= delta
		rotation.y += delta * 16.0
		if _followup_spin_interval <= 0.0:
			_apply_spin_damage()
			_followup_spin_interval = 0.14
		if _followup_time <= 0.0:
			_end_followup()


func _blink_behind_target() -> void:
	if not is_instance_valid(_followup_target):
		return
	var before_position := global_position
	var offset := _followup_target.global_position - global_position
	offset.y = 0.0
	var approach_dir := _facing if offset.length() < 0.05 else offset.normalized()
	var behind_position := _followup_target.global_position + approach_dir * FOLLOWUP_REAR_DISTANCE
	behind_position.y = global_position.y
	global_position = behind_position
	_followup_flash.visible = false
	_spawn_blink_effect(before_position, Color("#ffffff"))
	_spawn_blink_effect(global_position, Color("#ffe08a"))


func _spawn_blink_effect(p_position: Vector3, p_color: Color) -> void:
	if not is_inside_tree():
		return
	var effect := PlaceholderKit.ground_quad("art_key_followup_blink", p_color, Vector2(1.8, 1.8))
	get_parent().add_child(effect)
	effect.global_position = p_position
	effect.global_position.y = 0.08
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector3(2.6, 2.6, 2.6), 0.2)
	tween.tween_callback(effect.queue_free)


func _end_followup() -> void:
	_state = State.NORMAL
	_spin_ring.visible = false
	if is_instance_valid(_followup_flash):
		_followup_flash.visible = false
	_spin_area.monitoring = false
	if is_instance_valid(_body_visual):
		_body_visual.scale = Vector3.ONE
	_followup_target = null
	_followup_window = 0.0
	velocity.x = 0.0
	velocity.z = 0.0


func _start_heavy_sweep() -> void:
	if _state != State.NORMAL or _heavy_cooldown > 0.0:
		return
	if not try_spend_stamina(HEAVY_STAMINA_COST):
		return
	_state = State.HEAVY
	_heavy_time = HEAVY_TIME
	_heavy_cooldown = HEAVY_COOLDOWN
	_heavy_hit_done = false
	_heavy_radius = HEAVY_BASE_RADIUS + _momentum * HEAVY_RADIUS_PER_MOMENTUM
	_heavy_push_speed = HEAVY_BASE_PUSH + _momentum * HEAVY_PUSH_PER_MOMENTUM
	_spend_momentum(_momentum)
	_spin_ring.visible = false
	_spin_area.monitoring = false
	velocity = Vector3.ZERO
	_spawn_heavy_sweep_visual()


func _tick_heavy(delta: float) -> void:
	_heavy_time -= delta
	if not _heavy_hit_done:
		rotation.y += 1.0
		_apply_heavy_damage()
		_heavy_hit_done = true
	if _heavy_time <= 0.0:
		_end_heavy()


func _apply_heavy_damage() -> void:
	for ghost in get_tree().get_nodes_in_group("ghosts"):
		if ghost == self:
			continue
		if not ghost.has_method("on_cleaned"):
			continue
		var ghost_position: Vector3 = ghost.global_position
		var offset := ghost_position - global_position
		offset.y = 0.0
		if offset.length() > _heavy_radius:
			continue
		ghost.on_cleaned(self)
		add_bean(1)
		if ghost.has_method("push_away_from"):
			ghost.push_away_from(self, _heavy_push_speed)
		_mark_followup_target(ghost)


func _end_heavy() -> void:
	_state = State.NORMAL
	_spin_ring.visible = false
	velocity.x = 0.0
	velocity.z = 0.0


func _spawn_heavy_sweep_visual() -> void:
	if not is_inside_tree():
		return
	var effect := PlaceholderKit.ground_quad("art_key_player_heavy_sweep", Color("#eaffc9"), Vector2(_heavy_radius * 2.0, _heavy_radius * 2.0))
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.global_position.y = 0.07
	effect.scale = Vector3(0.2, 0.2, 0.2)
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector3.ONE, 0.18)
	tween.tween_callback(effect.queue_free)


func add_momentum(p_amount: int = 1) -> void:
	var next := clampi(_momentum + p_amount, 0, MAX_MOMENTUM)
	if next == _momentum:
		return
	var previous := _momentum
	_momentum = next
	momentum_changed.emit(_momentum, MAX_MOMENTUM)
	_update_broom_momentum_visual()
	if previous < MAX_MOMENTUM and next >= MAX_MOMENTUM:
		enhanced_sweep_ready.emit()


func add_bean(p_count: int = 1) -> void:
	var next := clampi(beans + p_count, 0, MAX_BEANS)
	if next == beans:
		return
	beans = next
	beans_changed.emit(beans, MAX_BEANS)


func get_momentum() -> int:
	return _momentum


func reset_momentum() -> void:
	if _momentum != 0:
		_momentum = 0
		momentum_changed.emit(0, MAX_MOMENTUM)
	_update_broom_momentum_visual()


func _spend_momentum(p_amount: int) -> void:
	if p_amount <= 0:
		return
	_momentum = clampi(_momentum - p_amount, 0, MAX_MOMENTUM)
	momentum_changed.emit(_momentum, MAX_MOMENTUM)
	_update_broom_momentum_visual()


func _update_broom_momentum_visual() -> void:
	for index in range(_broom_visuals.size()):
		var color := Color("#ff4a45") if _momentum >= MAX_MOMENTUM else _broom_default_colors[index]
		_broom_visuals[index].material_override = PlaceholderKit.material(color)


func try_spend_stamina(p_amount: float) -> bool:
	if stamina + 0.001 < p_amount:
		return false
	stamina = maxf(0.0, stamina - p_amount)
	_stamina_regen_timer = STAMINA_REGEN_DELAY
	stamina_changed.emit(stamina, MAX_STAMINA)
	return true


func _start_attack() -> void:
	if _momentum >= MAX_MOMENTUM:
		_enhanced_sweep = true
		_spend_momentum(MAX_MOMENTUM)
		enhanced_sweep_used.emit()
	_state = State.ATTACK
	_attack_timer = ATTACK_TIME
	_attack_cooldown = ATTACK_COOLDOWN
	_attack_hit_done = false
	_spawn_attack_visual()


func take_hit(p_from: Node3D) -> void:
	if _defeated or _invuln_time > 0.0 or _state == State.DASH or health <= 0:
		return
	if _spin_super_armor:
		health = maxi(0, health - 1)
		_invuln_time = HIT_INVULN_TIME
		_heal_hold_time = 0.0
		_heal_timer = 0.0
		health_changed.emit(health, MAX_HEALTH)
		if health <= 0:
			_defeated = true
			set_physics_process(false)
			defeated.emit()
		return
	health = maxi(0, health - 1)
	_invuln_time = HIT_INVULN_TIME
	_heal_hold_time = 0.0
	_heal_timer = 0.0
	_hitstun_time = HITSTUN_TIME
	if _state == State.SPIN:
		_stop_spin()
	elif _state == State.SPIN_CHARGE:
		_cancel_spin_charge()
	elif _state == State.FOLLOWUP:
		_end_followup()
	elif _state == State.HEAVY:
		_end_heavy()
	elif _state == State.DASH_TECH:
		_state = State.NORMAL
		velocity.x = 0.0
		velocity.z = 0.0
	_state = State.NORMAL
	_attack_timer = 0.0
	_dash_timer = 0.0
	_hurt_timer = 0.16
	if is_instance_valid(_body_visual):
		_body_visual.material_override = PlaceholderKit.material(Color("#ffffff"))

	var direction := global_position - p_from.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = -_facing
	direction = direction.normalized()
	velocity = direction * 13.0 + Vector3.UP * 3.5
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		_defeated = true
		set_physics_process(false)
		defeated.emit()


func revive(p_position: Vector3) -> void:
	_defeated = false
	set_physics_process(true)
	_state = State.NORMAL
	_attack_timer = 0.0
	_dash_timer = 0.0
	_hitstun_time = 0.0
	_bounce_time = 0.0
	_bounce_cooldown = 0.0
	_hurt_timer = 0.0
	if is_instance_valid(_body_visual):
		_body_visual.material_override = PlaceholderKit.material(Color("#cfe06a"))
	global_position = p_position
	velocity = Vector3.ZERO
	health = MAX_HEALTH
	stamina = MAX_STAMINA
	beans = 0
	_stamina_regen_timer = 0.0
	_heal_hold_time = 0.0
	_heal_timer = 0.0
	_invuln_time = 1.4
	_spin_ring.visible = false
	_spin_area.monitoring = false
	health_changed.emit(health, MAX_HEALTH)
	stamina_changed.emit(stamina, MAX_STAMINA)
	beans_changed.emit(beans, MAX_BEANS)


func _bounce_and_bump_from_slides() -> void:
	var flat_velocity := Vector2(_pre_move_velocity.x, _pre_move_velocity.z)
	if _bounce_cooldown > 0.0 or flat_velocity.length() < 0.1:
		return
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("ghosts") and collider.has_method("bump_from"):
			collider.bump_from(self, velocity)
			if _hitstun_time <= 0.0:
				_mark_followup_target(collider)
				add_momentum(1)
		var normal := collision.get_normal()
		normal.y = 0.0
		if normal.length() < 0.5:
			continue
		normal = normal.normalized()
		if _state == State.NORMAL and _hitstun_time <= 0.0 and is_on_floor():
			if _try_step_up(Vector3(flat_velocity.x, 0.0, flat_velocity.y)):
				_state = State.NORMAL
				return
		_show_bounce_effect(collision.get_position())
		var normal_flat := Vector2(normal.x, normal.z)
		if flat_velocity.dot(normal_flat) >= 0.0:
			continue
		var reflected := flat_velocity.bounce(normal_flat) * WALL_BOUNCE_DAMPING
		_state = State.NORMAL
		_dash_timer = 0.0
		_bounce_time = 0.13
		_bounce_cooldown = 0.28
		velocity.x = reflected.x
		velocity.z = reflected.y
		flat_velocity = reflected


func _show_bounce_effect(p_position: Vector3) -> void:
	var effect := PlaceholderKit.ground_quad("art_key_bounce_ring", Color("#c9ffd2"), Vector2(1.8, 1.8))
	get_parent().add_child(effect)
	effect.global_position = p_position
	effect.global_position.y = 0.08
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector3(2.4, 2.4, 2.4), 0.16)
	tween.tween_callback(effect.queue_free)


func _apply_slash_damage() -> void:
	var sweep_damage := base_sweep_damage * (2 if _enhanced_sweep else 1)
	for body in _slash_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("on_cleaned"):
			body.on_cleaned(self, true, sweep_damage)
			add_bean(1)
			_mark_followup_target(body)
	_enhanced_sweep = false


func set_base_sweep_damage(p_damage: int) -> void:
	base_sweep_damage = maxi(1, p_damage)


func _try_send_off() -> void:
	var best_target: Node3D = null
	var best_distance := INF
	for ghost in get_tree().get_nodes_in_group("ghosts"):
		if not ghost.has_method("is_send_off_ready"):
			continue
		if not ghost.is_send_off_ready():
			continue
		var distance := global_position.distance_to(ghost.global_position)
		if distance < INTERACT_RANGE and distance < best_distance:
			best_distance = distance
			best_target = ghost
	if best_target and best_target.has_method("start_send_off"):
		best_target.start_send_off(self)
		sendoff_performed.emit(best_target)


func _update_facing() -> void:
	if _state == State.DASH:
		return
	if _facing.length_squared() > 0.001:
		look_at(global_position + _facing, Vector3.UP)


func _setup_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.45
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)


func _setup_art() -> void:
	var host := Node3D.new()
	host.name = "ArtHost"
	add_child(host)

	var body := PlaceholderKit.box("art_key_player_body", Color("#cfe06a"), Vector3(0.72, 0.9, 0.72))
	body.position.y = 0.82
	host.add_child(body)
	_body_visual = body

	var broom_pivot := Node3D.new()
	broom_pivot.name = "BroomPivot"
	broom_pivot.position = Vector3(0.0, 1.05, -0.3)
	host.add_child(broom_pivot)

	var broom := PlaceholderKit.box("art_key_broom", Color("#b96b3b"), Vector3(0.14, 0.14, 1.8))
	broom.position.z = -0.75
	broom_pivot.add_child(broom)
	_broom_visuals.append(broom)
	_broom_default_colors.append(Color("#b96b3b"))

	var bristles := PlaceholderKit.box("art_key_broom_bristles", Color("#e6c86f"), Vector3(0.22, 0.22, 0.34))
	bristles.position.z = -1.48
	broom_pivot.add_child(bristles)
	_broom_visuals.append(bristles)
	_broom_default_colors.append(Color("#e6c86f"))
	_broom_pivot = broom_pivot


func _setup_slash() -> void:
	_slash_area = Area3D.new()
	_slash_area.name = "SlashArea"
	_slash_area.position = Vector3(0.0, 0.45, -1.05)
	_slash_area.collision_layer = 0
	_slash_area.collision_mask = 1
	_slash_area.monitorable = false
	add_child(_slash_area)

	var shape := BoxShape3D.new()
	shape.size = Vector3(4.4, 1.8, 2.2)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	_slash_area.add_child(collision)


func _setup_spin() -> void:
	_spin_area = Area3D.new()
	_spin_area.name = "SpinArea"
	_spin_area.collision_layer = 0
	_spin_area.collision_mask = 1
	_spin_area.monitoring = false
	add_child(_spin_area)
	var spin_shape := SphereShape3D.new()
	spin_shape.radius = 2.0
	var spin_collision := CollisionShape3D.new()
	spin_collision.shape = spin_shape
	spin_collision.position.y = 0.9
	_spin_area.add_child(spin_collision)

	_spin_ring = PlaceholderKit.ground_quad("art_key_player_spin_ring", Color("#ffe45e"), Vector2(3.6, 3.6))
	_spin_ring.position = Vector3(0.0, 0.06, 0.0)
	_spin_ring.visible = false
	add_child(_spin_ring)

	_followup_flash = PlaceholderKit.ground_quad("art_key_player_followup_flash", Color("#e8f7ff"), Vector2(1.7, 1.7))
	_followup_flash.position = Vector3(0.0, 0.07, 0.0)
	_followup_flash.visible = false
	add_child(_followup_flash)


func _spawn_attack_visual() -> void:
	var visual := PlaceholderKit.ground_quad("art_key_player_slash_arc", Color("#eaff9e"), Vector2(4.6, 2.7))
	visual.position = Vector3(0.0, 0.06, -1.3)
	visual.scale = Vector3(0.5, 0.5, 0.5)
	add_child(visual)
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3(1.25, 1.25, 1.0), ATTACK_TIME)
	tween.tween_callback(visual.queue_free)
