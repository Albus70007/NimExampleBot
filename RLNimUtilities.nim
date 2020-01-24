import packedjson, vmath


#Simple data classes / structures
type Rotator* = object 
    Yaw*: float64
    Pitch*: float64
    Roll*: float64


#will convert a JsonNode (received from the bridge bot), into a Vec3
func getVector3*(dobject: JsonNode): Vec3 =
    var vector: Vec3
    vector.x = dobject[0].getFloat()
    vector.y = dobject[1].getFloat()
    vector.z = dobject[2].getFloat()
    return vec3(vector)

#will convert a JsonNode (received from the bridge bot), into a Rotator
func getRotator*(dobject: JsonNode): Rotator =
    var rotator: Rotator
    rotator.Yaw = dobject[0].getFloat()
    rotator.Pitch = dobject[1].getFloat()
    rotator.Roll = dobject[2].getFloat()
    return rotator
