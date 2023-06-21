extends KinematicBody2D

const PLAYERHURTSOUND = preload("res://Player/PlayerHurtSound.tscn")

export var FRIC = 900
export var ACC = 10000
export var MAXSPEED = 100
export var ROLLSPEED = 125


enum { MOVE, ROLL, ATTACK }
var state = MOVE
var velocity = Vector2.ZERO
var rollVec = Vector2.DOWN
var stats = PlayerStats


onready var aniPlayer = $AnimationPlayer
onready var aniTree = $AnimationTree
onready var aniState = aniTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAniamtionPlayer

#==================================================================

func _ready():
	randomize()
	stats.connect("no_health", self, "queue_free")
	aniTree.active = true
	swordHitbox.knockbackVec = rollVec


func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		
		ROLL:
			roll_state()
			
		ATTACK:
			attack_state()



#Character Movement
func move_state(delta):
	
	var inVec = Vector2.ZERO
	inVec.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	inVec.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	inVec = inVec.normalized()
	
	if inVec != Vector2.ZERO:
		rollVec = inVec
		swordHitbox.knockbackVec = inVec	# Knockback is in the same direction as movement
		
		aniTree.set("parameters/Idle/blend_position", inVec)
		aniTree.set("parameters/Run/blend_position", inVec)
		aniTree.set("parameters/Attack/blend_position", inVec)
		aniTree.set("parameters/Roll/blend_position", inVec)
		aniState.travel("Run")
		velocity = velocity.move_toward(inVec * MAXSPEED, ACC * delta)
	
	else:
		aniState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRIC * delta)
	
	move()
	
	if Input.is_action_just_pressed("roll"):
		state = ROLL
		
	if Input.is_action_just_pressed("attack"):
		state = ATTACK

	

func move():
	velocity = move_and_slide(velocity)


#Character Attack
func attack_state():
	velocity = Vector2.ZERO
	aniState.travel("Attack")


func attack_animation_finish():
	velocity = velocity * 0.001
	state = MOVE


func roll_state():
	velocity = rollVec * ROLLSPEED
	aniState.travel("Roll")
	move()


func roll_animation_finish():
	state = MOVE


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.6)
	hurtbox.create_hit_effect()
	
	var playerHurtSound = PLAYERHURTSOUND.instance()
	get_tree().current_scene.add_child(playerHurtSound)


func _on_Hurtbox_invincibility_start():
	blinkAnimationPlayer.play("Start")


func _on_Hurtbox_invincibility_end():
	blinkAnimationPlayer.play("Stop")
