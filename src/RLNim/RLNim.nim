import net, sugar, math, json, msgpack4nim, base64, strutils, sequtils
import RLTypes
export RLTypes

type RenderObj* = object
  name*: string
  field*: float
#[
type RenderingInfo* = object
  ntype*: string
  things_to_render*: tuple[obj: RenderObj]
]#

  #rendering_info: RenderingInfo

method initalize_agent*(self: Bot) {.base.} = echo("Not implemented")
method get_output*(self: Bot, game_packet: GameTickPacket) {.base.} = echo("Not implemented")

proc rollBytes(bs : string) : uint16 =
  let shifts: seq[uint16] = @[0'u16, 8'u16]
  var n: uint16
  for pair in zip(shifts, bs):
    n = n or pair[1].uint16 shl pair[0]
  return n

proc unrollBytes(n : uint16): string =
  let shifts: seq[uint16] = @[0'u16, 8'u16]
  map(shifts, shift => $char((n shr shift) and 0x000000ff)).join

proc try_connect*(self: Bot, add: string = "localhost", port: Port) =
  while true: 
    try:
      self.rootsocket.connect(add, port)
      echo("Bot: ", self.name, " connected to server on address: localhost, on port: ", port)
      break
    except:
      discard
  let start_msg: string = """[{"type": "Ready", "name": """ & "\"" & self.name & "\"" & """, "team": 0, "id": 0, "multiplicity": 1}]"""
  let start_header: string = (start_msg.len).uint16.unrollBytes[0..1]
  self.rootsocket.send(start_header & start_msg)
  let server_msg: string = self.rootsocket.recv(15)
  self.index = parseInt($server_msg[6])
  self.team = parseInt($server_msg[^1])
  self.initalize_agent()

proc receivePacket(self: Bot): GameInformation =
  let received: string = self.rootsocket.recv(GameInformation.sizeof)
  var packet: GameInformation = cast[ptr GameInformation](unsafeaddr received[0])[]
  #received.unpack(packet) #, parseJson(received)[1])
  return packet

proc send_inputs(self: Bot) =
  var strinputs: string = $(%*self.inputs)
  let header: string = (strinputs.len + 2).uint16.unrollBytes[0..1]
  let buffer: string = header & "[" & strinputs & "]"
  self.rootsocket.send(buffer)
#[
proc send_extra_info(self: Bot) =
  let info: string = $(self.rendering_info)
  self.rootsocket.send(info)
]#
proc receive_and_respond*(self: Bot) =
  while true:
    let game_info: GameInformation = self.receivePacket()
    self.get_ball_prediction = game_info.ballPrediction
    self.get_output(game_info.packet)
    self.send_inputs()


proc rotate_game_tick_packet_boost_omitted*(packet: GameTickpacket): GameTickPacket =
  # Negate all x,y values for ball
  result.game_ball.physics.location.x = -1 * packet.game_ball.physics.location.x
  result.game_ball.physics.location.y = -1 * packet.game_ball.physics.location.y
  result.game_ball.physics.velocity.x = -1 * packet.game_ball.physics.velocity.x
  result.game_ball.physics.velocity.y = -1 * packet.game_ball.physics.velocity.y
  # Angular velocity is stored on global axis so negating on x and y does make sense!
  result.game_ball.physics.angular_velocity.x = -1 * packet.game_ball.physics.angular_velocity.x
  result.game_ball.physics.angular_velocity.y = -1 * packet.game_ball.physics.angular_velocity.y

  # Rotate yaw 180 degrees is all that is necessary.
  let ball_yaw = packet.game_ball.physics.rotation.yaw
  result.game_ball.physics.rotation.yaw = if ball_yaw < 0: ball_yaw + math.PI else: ball_yaw - math.PI

  for i in 0..packet.game_cars.len - 1:
    {.unroll.}
    result.game_cars[i].physics.location.x = -1 * packet.game_cars[i].physics.location.x
    result.game_cars[i].physics.location.y = -1 * packet.game_cars[i].physics.location.y
    result.game_cars[i].physics.velocity.x = -1 * packet.game_cars[i].physics.velocity.x
    result.game_cars[i].physics.velocity.y = -1 * packet.game_cars[i].physics.velocity.y
    result.game_cars[i].physics.angular_velocity.x = -1 * packet.game_cars[i].physics.angular_velocity.x
    result.game_cars[i].physics.angular_velocity.y = -1 * packet.game_cars[i].physics.angular_velocity.y

    let car_yaw = packet.game_cars[i].physics.rotation.yaw
    result.game_cars[i].physics.rotation.yaw = if car_yaw < 0: car_yaw + math.PI else: car_yaw - math.PI
