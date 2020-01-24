import net, sugar, packedjson, strutils, sequtils, packedjson


# Player inputs class / structure
type PlayerInputs* = object
    ntype*: string
    steer*: float
    throttle*: float
    roll*: float
    pitch*: float
    yaw*: float
    jump*: bool
    boost*: bool
    handbrake*: bool
    use_item*: bool

# Bot class / structure
type Bot* = object
    name*: string
    rootsocket*: Socket
    inputs*: PlayerInputs

#[ Note that this is how Object Oriented programming works in Nim,
 functions are defined separately of the actual class, but it is passed
 as an argument. ]#

# You dont need to understand this functions if you are just a bot maker,
# but if you are here to support a new language with sockets, this is 
# this is important, basically, python organizes bytes in a different
# way to how Nim interprets them, this is called an endian problem,
# more information at https://en.wikipedia.org/wiki/Endianness
# just check it your language interprets bytes as python does before 
# replicating this functions in your language.
func rollBytes(bs : string) : uint16 =
    let shifts : seq[uint16] = @[0'u16, 8'u16]
    var n : uint16
    for pair in zip(shifts, bs):
        n = n or pair.b.uint16 shl pair.a
    return n
func unrollBytes(n : uint16) : string =
    let shifts : seq[uint16] = @[0'u16, 8'u16]
    map(shifts, shift => $char((n shr shift) and 0x000000ff)).join

# We will try to connect to a port until we achieve it, ignoring possible
# errors that might occur if there is no server to host us.
proc try_connect*(self: Bot, add: string = "localhost", port: Port) =
    while true: 
        try:
            self.rootsocket.connect(add, port)
            echo("Bot: ", self.name, " connected to server on address: localhost, on port: ", port)
            break
        except:
            discard

# This is the most important function if you are trying to support a new 
# language, we basically get the header the bridge bot sent us and then
# proceed to receive that exact ammount of data.
proc receivePacket(self: Bot): JsonNode =
    let header: uint16 = rollBytes(self.rootsocket.recv(2))
    let received: string = self.rootsocket.recv(header.int)
    let packet: JsonNode = packedjson.parseJson("{\"Game\":" & received & "}")
    return packet

# This function returns the bot's outputs to the bridge bot.
proc send_inputs(self: Bot, game_info: JsonNode, process_game: proc(game_info: JsonNode): PlayerInputs) =
    var inputs: PlayerInputs = process_game(game_info)
    var strinputs: string = $(%inputs)
    let header: string = (strinputs.len).uint16.unrollBytes[0..1]
    let buffer: string = header & strinputs
    self.rootsocket.send(buffer)

# This will make use of the above functions to, well... receive and send
# our bot's inputs back (until the mtach is ended, this is optional,
# but I decided to do it this way (its up to you to handle this from your 
# bot or not, if you want to get more information of how the
# bridge bot handles that data, have a look at 
# PythonBridge/src/BridgeBot.py (not commented)
proc receive_and_respond*(self: Bot, process_game: proc(game_info: JsonNode): PlayerInputs) =
    let game_info: JsonNode = self.receivePacket()
    if game_info["Game"][0]["is_match_ended"].getBool() == true:
        raise newException(Exception, "Match Eneded")
    else:
        self.send_inputs(game_info, process_game)
