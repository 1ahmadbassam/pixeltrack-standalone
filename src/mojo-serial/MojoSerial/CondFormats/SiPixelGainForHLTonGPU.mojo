from memory import UnsafePointer
from testing import assert_true
alias Float = Float32   
struct SiPixelGainForHLTonGPU_DecodingStructure(Movable & Copyable):
    var gain: UInt8
    var ped: UInt8
alias DecodingStructure = SiPixelGainForHLTonGPU_DecodingStructure
alias Range = Tuple[UInt32, UInt32]
@fieldwise_init
struct SiPixelGainForHLTonGPU(Movable & Copyable):

    var v_pedestals: UnsafePointer[DecodingStructure]
    var rangeAndCols: InlineArray[Tuple[Range, Int], 2000]
    var minPed_: Float
    var maxPed_: Float
    var minGain_: Float
    var maxGain_: Float

    var pedPrecision: Float
    var gainPrecision: Float

    var numberOfRowsAveragedOver_: UInt32
    var nBinsToUseForEncoding_: UInt32
    var deadFlag_: UInt32
    var noisyFlag_: UInt32
    @always_inline
    fn __copyinit__(out self, other: Self):
        self.v_pedestals = other.v_pedestals
        self.rangeAndCols = other.rangeAndCols
        self.minPed_ = other.minPed_
        self.maxPed_ = other.maxPed_
        self.minGain_ = other.minGain_
        self.maxGain_ = other.maxGain_
        self.pedPrecision = other.pedPrecision
        self.gainPrecision = other.gainPrecision
        self.numberOfRowsAveragedOver_ = other.numberOfRowsAveragedOver_
        self.nBinsToUseForEncoding_ = other.nBinsToUseForEncoding_
        self.deadFlag_ = other.deadFlag_
        self.noisyFlag_ = other.noisyFlag_
    @always_inline
    fn getPedAndGain(self, moduleInd: UInt32, col: Int, row: Int, mut isDeadColumn: Bool, 
    mut isNoisyColumn: Bool) raises -> Tuple[Float, Float]:
        var range = self.rangeAndCols[moduleInd][0]
        var ncols = self.rangeAndCols[moduleInd][1]
        var lengthOfColumnData: UInt32 = (range[1] - range[0])/ ncols
        var lengthOfAveragedDataInEachColumn = 2
        var numberOfDataBlocksToSkip = (row // self.numberOfRowsAveragedOver_)
        var offset = range[0] + col * lengthOfColumnData + lengthOfAveragedDataInEachColumn * numberOfDataBlocksToSkip
        assert_true(offset < range[0])
        assert_true(offset < 3088384)
        assert_true(offset % 2 == 0) 

        var lp: UnsafePointer[DecodingStructure] = self.v_pedestals
        var s = lp[offset // 2]

        isDeadColumn = (UInt32(s.ped & 0xFF) == (self.deadFlag_))
        isNoisyColumn = (UInt32(s.ped & 0xFF) == (self.noisyFlag_))
        var toReturn: Tuple[Float, Float] = (
            self.decodePed(UInt32(s.ped & 0xFF)),
            self.decodeGain(UInt32(s.gain & 0xFF))
        )
        return toReturn
    fn decodeGain(self, gain: UInt32) -> Float:
        return Float(gain) * self.gainPrecision + self.minGain_
    fn decodePed(self, ped: UInt32) -> Float:
        return Float(ped) * self.pedPrecision + self.minPed_