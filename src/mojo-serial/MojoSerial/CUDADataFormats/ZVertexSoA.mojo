from MojoSerial.MojoBridge.Array import Array
from MojoSerial.MojoBridge.DTypes import Float, Typeable


@fieldwise_init
struct ZVertexSoA(Copyable, Defaultable, Movable, Typeable):
    alias MAXTRACKS: Int32 = 32 * 1024
    alias MAXVTX: Int32 = 1024

    var idv: Array[Int16, Int(Self.MAXTRACKS)]
    var zv: Array[Float, Int(Self.MAXTRACKS)]
    var wv: Array[Float, Int(Self.MAXTRACKS)]
    var chi2: Array[Float, Int(Self.MAXTRACKS)]
    var ptv2: Array[Float, Int(Self.MAXTRACKS)]
    var ndof: Array[Int32, Int(Self.MAXTRACKS)]
    var sortInd: Array[UInt16, Int(Self.MAXTRACKS)]
    var nvFinal: UInt32

    @always_inline
    fn __init__(out self):
        self.idv = Array[Int16, Int(Self.MAXTRACKS)](0)
        self.zv = Array[Float, Int(Self.MAXTRACKS)](0.0)
        self.wv = Array[Float, Int(Self.MAXTRACKS)](0.0)
        self.chi2 = Array[Float, Int(Self.MAXTRACKS)](0.0)
        self.ptv2 = Array[Float, Int(Self.MAXTRACKS)](0.0)
        self.ndof = Array[Int32, Int(Self.MAXTRACKS)](0)
        self.sortInd = Array[UInt16, Int(Self.MAXTRACKS)](0)
        self.nvFinal = 0

    @always_inline
    fn init(mut self):
        self.nvFinal = 0

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "ZVertexSoA"
