from MojoSerial.MojoBridge.DTypes import Float, Typeable


@fieldwise_init
struct ZVertexSoA(Copyable, Defaultable, Movable, Typeable):
    alias MAXTRACKS: Int32 = 32 * 1024
    alias MAXVTX: Int32 = 1024

    var idv: InlineArray[Int16, Int(Self.MAXTRACKS)]
    var zv: InlineArray[Float, Int(Self.MAXVTX)]
    var wv: InlineArray[Float, Int(Self.MAXVTX)]
    var chi2: InlineArray[Float, Int(Self.MAXVTX)]
    var ptv2: InlineArray[Float, Int(Self.MAXVTX)]
    var ndof: InlineArray[Int32, Int(Self.MAXTRACKS)]
    var sortInd: InlineArray[UInt16, Int(Self.MAXVTX)]
    var nvFinal: UInt32

    @always_inline
    fn __init__(out self):
        self.idv = InlineArray[Int16, Int(Self.MAXTRACKS)](fill=0)
        self.zv = InlineArray[Float, Int(Self.MAXVTX)](0.0)
        self.wv = InlineArray[Float, Int(Self.MAXVTX)](0.0)
        self.chi2 = InlineArray[Float, Int(Self.MAXVTX)](0.0)
        self.ptv2 = InlineArray[Float, Int(Self.MAXVTX)](0.0)
        self.ndof = InlineArray[Int32, Int(Self.MAXTRACKS)](fill=0)
        self.sortInd = InlineArray[UInt16, Int(Self.MAXVTX)](fill=0)
        self.nvFinal = 0

    @always_inline
    fn init(mut self):
        self.nvFinal = 0

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "ZVertexSoA"
