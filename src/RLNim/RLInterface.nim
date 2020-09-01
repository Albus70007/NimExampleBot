import RLTypes


proc string2Array(s: string): array[100, char] =
  for i in 0..<s.len:
    result[i] = s[i]

proc toBits*[T](x: T): ptr UncheckedArray[uint8] =
  result = cast[ptr array[GameInformation.sizeof, char]](unsafeAddr x)[]

proc packPacket*(pystr: var array[GameInformation.sizeof, char], packet: GameInformation) {.exportc, dynlib.} =
  pystr = packet.toBits()
  #stdout.writeLine(pystr)
