import net, math, vmath, strutils, packedjson 
import RLNim
import RLNimUtilities


# Initialising all the variables we need

var 
    index: int

    ballPosition: Vec3
    carPosition: Vec3
    carRotation: Rotator

    botToTargetAngle: float64
    botFrontToTargetAngle: float64

proc process_game(game_info: JsonNode): PlayerInputs =
    # Initialising all the output variables to their default values
    var 
        steer: float = 0.0
        throttle: float = 0.0
        roll: float = 0.0
        pitch: float = 0.0
        yaw: float = 0.0
        jump: bool = false
        boost: bool = false
        handbrake: bool = false
        use_item: bool = false
    
    # We get game information from the socket, the tiny Nim "framework" 
    # inside RLNim.nim handles this, while some functions inside
    # RLNimUtilities.nim convert blocks of data such as Vectors and Rotators
    # into proper Nim data types (also defined inside RLNimUtilities.nim)
    index = game_info[0]["index"].getInt()
    ballPosition = game_info[0]["ball"]["position"].getVector3()
    carPosition = game_info[0]["cars"][index]["position"].getVector3()
    carRotation = game_info[0]["cars"][index]["euler_angles"].getRotator()

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

    # We pack all the inputs into a PlayerInputs structure (defined in
    # RLNim.nim), and we return it.
    var inputs: PlayerInputs = PlayerInputs(ntype: "PlayerInput",
                                            steer: steer, 
                                            throttle: throttle, 
                                            roll: roll, 
                                            pitch: pitch, 
                                            yaw: yaw, 
                                            jump: jump, 
                                            boost: boost, 
                                            handbrake: handbrake,
                                            use_item: use_item)
    return inputs


# We initialise our Bot.
var Mybot: Bot = Bot(name: "Nimbot")
# We will read the port we should connect to from "PythonBridge/src/port.cfg"
# ¡THIS IS NOT THE GAME SERVER PORT, BUT THE PYTHON BRIDGE BOT ONE!
var port: Port = Port(parseInt(open("PythonBridge/src/port.cfg").readAll()))
# We initialise our bot's root socket
Mybot.rootsocket = newSocket(AF_INET, SOCK_STREAM)
# We initialise our bot's game inputs
MyBot.inputs = PlayerInputs(ntype: "PlayerInput",
                            steer: 0.0, 
                            throttle: 0.0, 
                            roll: 0.0, 
                            pitch: 0.0, 
                            yaw: 0.0, 
                            jump: false, 
                            boost: false, 
                            handbrake: false,
                            use_item: false)

# We try to connect to the port we defined above
#[ To get an in-depth look at what this 
 function does, have a look at RLNim.nim ]#
Mybot.try_connect(port = port)

# We will recieve data from our bridge bot and send back inputs
# until the game finishes, (this is handled by the "framework").
#[ To get an in-depth look at what this 
 function does, have a look at RLNim.nim ]#
while true:
    Mybot.receive_and_respond(process_game)
