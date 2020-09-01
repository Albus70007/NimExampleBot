from net import Socket
import msgpack4nim
import math, vmath
export math, vmath


const
  MAX_PLAYERS* = 64
  MAX_NAME_LENGTH* = 32
  MAX_BOOSTS* = 50
  MAX_TILES* = 200
  MAX_TEAMS* = 2
  MAX_GOALS* = 200
  NUM_SLICES* = 360


type Vector3* = Vec3

type Rotator* = Vector3

func pitch*(this: Rotator): float32 = this[0]
func `pitch=`*(this: var Rotator, p: float32) = this[0] = p
func yaw*(this: Rotator): float32 = this[1]
func `yaw=`*(this: var Rotator, y: float32) = this[1] = y
func roll*(this: Rotator): float32 = this[2]
func `roll=`*(this: var Rotator, r: float32) = this[2] = r


type Controller* {.exportc, pure, bycopy, packed.} = object
  steer*: cfloat
  throttle*: cfloat
  roll*: cfloat
  pitch*: cfloat
  yaw*: cfloat
  jump*: bool
  boost*: bool
  handbrake*: bool
  use_item*: bool
  #debug*: seq[array[0..2, float]]

proc unpack_type*[ByteStream](s: ByteStream, x: var Controller) =
  s.unpack(x.steer)
  s.unpack(x.throttle)
  s.unpack(x.roll)
  s.unpack(x.pitch)
  s.unpack(x.yaw)
  s.unpack(x.jump)
  s.unpack(x.boost)
  s.unpack(x.boost)
  s.unpack(x.handbrake)
  s.unpack(x.use_item)

#[
func newController*(): Controller =
  result.steer = 0
  result.throttle = 0
  result.roll = 0
  result.pitch = 0
  result.yaw = 0
  result.jump = false
  result.boost = false
  result.handbrake = false
  result.use_item = false
]#
type Physics* = object
  location*: Vector3
  rotation*: Rotator
  velocity*: Vector3
  angular_velocity*: Vector3
#[
type CarPhysics* = object
  location*: Vector3
  rotation*: Rotator
  velocity*: Vector3
  angular_velocity*: Vector3
  boost*: cint
  #state*: cstring
]#
type Touch* = object
  player_name*: array[MAX_NAME_LENGTH, Utf16Char]
  time_seconds*: cfloat
  hit_location*: Vector3
  hit_normal*: Vector3
  team*: cint
  player_index*: cint

type ScoreInfo* = object
  score*: cint
  goals*: cint
  own_goals*: cint
  assists*: cint
  saves*: cint
  shots*: cint
  demolitions*: cint

type BoxShape* = object
  length*: cfloat
  width*: cfloat
  height*: cfloat

type SphereShape* = object
  diameter*: cfloat

type CylinderShape* = object
  diameter*: cfloat
  height*: cfloat

type ShapeType* = enum
  box = 0
  sphere = 1
  cylinder = 2

type CollisionShape* = object
  `type`*: cint
  box*: BoxShape
  sphere*: SphereShape
  cylinder*: CylinderShape

type PlayerInfo* = object
  physics*: Physics
  score_info*: ScoreInfo
  is_demolished*: bool
  has_wheel_contact*: bool
  is_super_sonic*: bool
  is_bot*: bool
  jumped*: bool
  double_jumped*: bool
  name*: array[MAX_NAME_LENGTH, Utf16Char]
  team*: byte
  boost*: cint
  hitbox*: BoxShape
  hitbox_offset*: Vector3
  spawn_id*: cint

type DropShotInfo* = object
  absorbed_force*: cfloat
  damage_index*: cint
  force_accum_recent*: cfloat

type BallInfo* = object
  physics*: Physics
  latest_touch*: Touch
  drop_shot_info*: DropShotInfo
  collision_shape*: CollisionShape

type BoostPadState* = object
  is_active*: bool
  timer*: cfloat

type TileInfo* = object
  tile_state*: cint

type TeamInfo* = object
  team_index*: cint
  score*: cint

type GameInfo* = object
  seconds_elapsed*: cfloat
  game_time_remaining*: cfloat
  is_overtime*: bool
  is_unlimited_time*: bool
  is_round_active*: bool
  is_kickoff_pause*: bool
  is_match_ended*: bool
  world_gravity_z*: cfloat
  game_speed*: cfloat

#[
type newGameTickPacket* = object
  `type`*: cstring
  frame*: cint
  time_left*: cint
  score*: array[2, cint]
  ball*: Physics
  cars*: seq[CarPhysics]
  boost_pads*: seq[bool]
]#

type Slice* = object
  physics*: Physics
  game_seconds*: cfloat

type BallPrediction* = object
  slices*: array[NUM_SLICES, Slice]
  num_slices*: cint

type GameTickPacket* = object
  game_cars*: array[MAX_PLAYERS, PlayerInfo]
  num_cars*: cint
  game_boosts*: array[MAX_BOOSTS, BoostPadState]
  num_boost*: cint
  game_ball*: BallInfo
  game_info*: GameInfo
  dropshot_tiles*: array[MAX_TILES, TileInfo]
  num_tiles*: cint
  teams*: array[MAX_TEAMS, TeamInfo]
  num_teams*: cint

type GameInformation* {.exportc, pure, bycopy, packed.} = object
  packet*: GameTickPacket
  ballPrediction*: BallPrediction


type Bot* = ref object of RootObj
  name*: string
  team*: int
  index*: int
  rootsocket*: Socket
  inputs*: Controller
  get_ball_prediction*: BallPrediction