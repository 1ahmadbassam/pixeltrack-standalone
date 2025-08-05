from memory import UnsafePointer

from MojoSerial.MojoBridge.Array import Array
from MojoSerial.MojoBridge.DTypes import Float, Typeable


@fieldwise_init
@register_passable("trivial")
struct SiPixelGainForHLTonGPU_DecodingStructure(
    Copyable, Defaultable, Movable, Typeable
):
    var gain: UInt8
    var ped: UInt8

    @always_inline
    fn __init__(out self):
        self.gain = 0
        self.ped = 0

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelGainForHLTonGPU_DecodingStructure"


@fieldwise_init
struct SiPixelGainForHLTonGPU(Copyable, Defaultable, Movable, Typeable):
    alias DecodingStructure = SiPixelGainForHLTonGPU_DecodingStructure
    alias Range = Tuple[UInt32, UInt32]

    var v_pedestals: UnsafePointer[Self.DecodingStructure]
    var rangeAndCols: Array[
        Tuple[Self.Range, Int], 2000, run_destructors=True
    ]
    var _minPed: Float
    var _maxPed: Float
    var _minGain: Float
    var _maxGain: Float

    var pedPrecision: Float
    var gainPrecision: Float

    var _numberOfRowsAveragedOver: UInt32  # this is 80!!!!
    var _nBinsToUseForEncoding: UInt32
    var _deadFlag: UInt32
    var _noisyFlag: UInt32

    @always_inline
    fn __init__(out self):
        self.v_pedestals = UnsafePointer[Self.DecodingStructure]()
        self.rangeAndCols = Array[
            Tuple[Self.Range, Int], 2000, run_destructors=True
        ](Tuple[Self.Range, Int](Self.Range(0, 0), 0))
        self._minPed = 0.0
        self._maxPed = 0.0
        self._minGain = 0.0
        self._maxGain = 0.0

        self.pedPrecision = 0.0
        self.gainPrecision = 0.0

        self._numberOfRowsAveragedOver = 0
        self._nBinsToUseForEncoding = 0
        self._deadFlag = 0
        self._noisyFlag = 0

    @always_inline
    fn getPedAndGain(
        self,
        moduleInd: UInt32,
        col: Int32,
        row: Int32,
        mut isDeadColumn: Bool,
        mut isNoisyColumn: Bool,
    ) -> Tuple[Float, Float]:
        var range = self.rangeAndCols[moduleInd][0]
        var ncols = self.rangeAndCols[moduleInd][1]

        # determine what averaged data block we are in (there should be 1 or 2 of these depending on if plaquette is 1 by X or 2 by X
        var lengthOfColumnData: UInt32 = (range[1] - range[0]) / ncols
        # we always only have two values per column averaged block
        var lengthOfAveragedDataInEachColumn = 2
        var numberOfDataBlocksToSkip = row.cast[DType.uint32]() // self._numberOfRowsAveragedOver
        var offset = (
            range[0]
            + col.cast[DType.uint32]() * lengthOfColumnData
            + lengthOfAveragedDataInEachColumn * numberOfDataBlocksToSkip
        )
        debug_assert(offset < range[1])
        debug_assert(offset < 3088384)
        debug_assert(offset % 2 == 0)

        var lp = self.v_pedestals
        var s = lp[offset // 2]

        isDeadColumn = (s.ped.cast[DType.uint32]() & 0xFF) == (self._deadFlag)
        isNoisyColumn = (s.ped.cast[DType.uint32]() & 0xFF) == (self._noisyFlag)
        return (
            self.decodePed(s.ped.cast[DType.uint32]() & 0xFF),
            self.decodeGain(s.gain.cast[DType.uint32]() & 0xFF),
        )

    @always_inline
    fn decodeGain(self, gain: UInt32) -> Float:
        return Float(gain) * self.gainPrecision + self._minGain

    @always_inline
    fn decodePed(self, ped: UInt32) -> Float:
        return Float(ped) * self.pedPrecision + self._minPed

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelGainForHLTonGPU"
