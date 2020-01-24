import packedjson


#Simple data classes / structures
type Vector2* = object 
    X*: float64
    Y*: float64

type Vector3* = object 
    X*: float64
    Y*: float64
    Z*: float64

type Vector4* = object 
    X*: float64
    Y*: float64
    Z*: float64
    A*: float64

type Rotator* = object 
    Yaw*: float64
    Pitch*: float64
    Roll*: float64


#will convert a JsonNode (received from the bridge bot), into a Vector3
func getVector3*(dobject: JsonNode): Vector3 =
    var vector: Vector3
    vector.X = dobject[0].getFloat()
    vector.Y = dobject[1].getFloat()
    vector.Z = dobject[2].getFloat()
    return vector

#will convert a JsonNode (received from the bridge bot), into a Rotator
func getRotator*(dobject: JsonNode): Rotator =
    var rotator: Rotator
    rotator.Yaw = dobject[0].getFloat()
    rotator.Pitch = dobject[1].getFloat()
    rotator.Roll = dobject[2].getFloat()
    return rotator

#[ all the functions below will allow the usage of simple operations 
 between Vectors and Vectors or numbers (they are named the same as the
 language does, but this wont matter, they will just extend the current
 declared functions, and each of them will get called if the arguments
 passed match with the ones expected by any of the functions (that are 
 named the same way) ]#
proc `*`*(X: Vector3, Y: Vector3): Vector3 =
    var vector: Vector3
    vector.X = X.X * Y.X
    vector.Y = X.Y * Y.Y
    vector.Z = X.Z * Y.Z
    return vector
proc `*`*(X: float, Y: Vector3): Vector3 =
    var vector: Vector3
    vector.X = Y.X * X
    vector.Y = Y.Y * X
    vector.Z = Y.Z * X
    return vector
proc `*`*(X: Vector3, Y: float): Vector3 =
    var vector: Vector3
    vector.X = X.X * Y
    vector.Y = X.Y * Y
    vector.Z = X.Z * Y
    return vector
#PLUS
proc `+`*(X: Vector3, Y: Vector3): Vector3 =
    var vector: Vector3
    vector.X = X.X + Y.X
    vector.Y = X.Y + Y.Y
    vector.Z = X.Z + Y.Z
    return vector
#MINUS
proc `-`*(X: Vector3, Y: Vector3): Vector3 =
    var vector: Vector3
    vector.X = X.X - Y.X
    vector.Y = X.Y - Y.Y
    vector.Z = X.Z - Y.Z
    return vector
proc `-`*(X: Vector3, Y: float): Vector3 =
    var vector: Vector3
    vector.X = X.X - Y
    vector.Y = X.Y - Y
    vector.Z = X.Z - Y
    return vector
proc `-`*(X: float, Y: Vector3): Vector3 =
    var vector: Vector3
    vector.X = X - Y.X
    vector.Y = X - Y.Y
    vector.Z = X - Y.Z
    return vector
#Smaller than
proc `<`*(X: Vector3, Y: float64): bool =
    if X.X >= Y:
        return false
    elif X.Y >= Y:
        return false
    elif X.Z >= Y:
        return false
    else:
        return true
proc `<`*(X: float64, Y: Vector3): bool =
    if X >= Y.X:
        return false
    elif X >= Y.Y:
        return false
    elif X >= Y.Z:
        return false
    else:
        return true
#Smaller or equal to
proc `<=`*(X: Vector3, Y: float64): bool =
    if X.X > Y:
        return false
    elif X.Y > Y:
        return false
    elif X.Z > Y:
        return false
    else:
        return true
proc `<=`*(X: float64, Y: Vector3): bool =
    if X > Y.X:
        return false
    elif X > Y.Y:
        return false
    elif X > Y.Z:
        return false
    else:
        return true
#Greater than
proc `>`*(X: Vector3, Y: float64): bool =
    if X.X <= Y:
        return false
    elif X.Y <= Y:
        return false
    elif X.Z <= Y:
        return false
    else:
        return true
proc `>`*(X: float64, Y: Vector3): bool =
    if X <= Y.X:
        return false
    elif X <= Y.Y:
        return false
    elif X <= Y.Z:
        return false
    else:
        return true
#Greater or equal to
proc `>=`*(X: Vector3, Y: float64): bool =
    if X.X < Y:
        return false
    elif X.Y < Y:
        return false
    elif X.Z < Y:
        return false
    else:
        return true
proc `>=`*(X: float64, Y: Vector3): bool =
    if X < Y.X:
        return false
    elif X < Y.Y:
        return false
    elif X < Y.Z:
        return false
    else:
        return true
#Equals to
proc `==`*(X: Vector3, Y: Vector3): bool =
    if X.X == Y.X:
        return false
    elif X.Y == Y.Y:
        return false
    elif X.Z == Y.Z:
        return false
    else:
        return true
proc `==`*(X: float64, Y: Vector3): bool =
    if X == Y.X:
        return false
    elif X == Y.Y:
        return false
    elif X == Y.Z:
        return false
    else:
        return true
