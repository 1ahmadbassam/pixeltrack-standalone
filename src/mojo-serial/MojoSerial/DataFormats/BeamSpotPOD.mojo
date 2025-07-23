from MojoSerial.MojoBridge.DTypes import Float

@fieldwise_init
struct BeamSpotPOD(Copyable, Movable):
    var x: Float  # position
    var y: Float
    var z: Float

    var sigmaZ: Float

    var beamWidthX: Float
    var beamWidthY: Float

    var dxdz: Float
    var dydz: Float

    var emittanceX: Float
    var emittanceY: Float

    var betaStar: Float