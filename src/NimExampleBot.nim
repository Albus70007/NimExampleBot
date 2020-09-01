import net, math, vmath, strutils
import RLNim/RLnim


type NimExampleBot* = ref object of Bot


method initalize_agent*(self: NimExampleBot) =
  self.team = if self.team == 0: 1 else: -1
  echo("initialized!")
  echo(self.team)


method get_output*(self: NimExampleBot, packet: GameTickPacket) =
  # We get game information from the socket, the tiny Nim "framework"
  # inside RLNim.nim handles this, while some functions inside
  # RLNimUtilities.nim convert blocks of data such as Vectors and Rotators
  # into proper Nim data types (also defined inside RLNimUtilities.nim)
  var
    index = packet.index.getInt()
    ballPosition = packet.game_ball.physics.location
    carPosition = packet.game_cars[self.index].physics.location
    carRotation = packet.game_cars[self.index].physics.rotation

    botToTargetAngle = math.arctan2(ballPosition.y - carPosition.y,
                                    ballPosition.x - carPosition.x)
    botFrontToTargetAngle = botToTargetAngle - carRotation.Yaw;

  if botFrontToTargetAngle < -math.PI:
      botFrontToTargetAngle += 2 * math.PI
  elif botFrontToTargetAngle < -math.PI:
      botFrontToTargetAngle -= 2 * math.PI

  # Here is where the bot logic resides
  # I recommend you to use another separate file to create your Bot Logic
  # once it gets more complex

  if botFrontToTargetAngle > 0:
      steer = 1
  elif botFrontToTargetAngle < 0:
      steer = -1

  throttle = 1
