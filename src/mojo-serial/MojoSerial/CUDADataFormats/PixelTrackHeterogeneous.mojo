from memory import UnsafePointer

from MojoSerial.CUDACore.HistoContainer import OneToManyAssoc
from MojoSerial.CUDACore.EigenSoA import ScalarSoA
from MojoSerial.CUDADataFormats.TrajectoryStateSoA import TrajectoryStateSoA
from MojoSerial.MojoBridge.Matrix import Vector, Matrix
from MojoSerial.MojoBridge.DTypes import Float

struct TrackQuality:
    alias bad: UInt8 = 0
    alias dup: UInt8 = 1
    alias loose: UInt8 = 2
    alias strict: UInt8 = 3
    alias tight: UInt8 = 4
    alias highPurity: UInt8 = 5

@fieldwise_init
struct TrackSoAT[S: Int32](Movable, Defaultable):
    alias Quality = UInt8
    alias HIndexType = DType.uint16
    alias HitContainer = OneToManyAssoc[S.cast[DType.uint32](), 5 * S.cast[DType.uint32](), Self.HIndexType]

    var m_quality: ScalarSoA[DType.uint8, Int(S)]
    var hitIndicies: Self.HitContainer
    var detIndices: Self.HitContainer
    var m_nTracks: UInt32

    var chi2: ScalarSoA[DType.float32, Int(S)]

    var stateAtBS: TrajectoryStateSoA[S]
    var eta: ScalarSoA[DType.float32, Int(S)]
    var pt: ScalarSoA[DType.float32, Int(S)]

    @always_inline
    fn __init__(out self):
        self.m_quality = ScalarSoA[DType.uint8, Int(S)]()
        self.hitIndicies = Self.HitContainer()
        self.detIndices = Self.HitContainer()
        self.m_nTracks = 0

        self.chi2 = ScalarSoA[DType.float32, Int(S)]()

        self.stateAtBS = TrajectoryStateSoA[S]()
        self.eta = ScalarSoA[DType.float32, Int(S)]()
        self.pt = ScalarSoA[DType.float32, Int(S)]()

    @staticmethod
    @always_inline
    fn stride() -> Int32:
        return S

    @always_inline
    fn quality(ref self, i: Int) -> ref [self.m_quality._data] UInt8:
        return self.m_quality[i]

    @always_inline
    fn qualityData(ref self) -> UnsafePointer[Self.Quality]:
        return self.m_quality.data()

    @always_inline
    fn nHits(self, i: Int) -> Int:
        return Int(self.detIndices.size(i))

    @always_inline
    fn charge(self, i: Int32) -> Float:
        return Float(1.) if self.stateAtBS.state[i][2] >= 0 else Float(-1.)
    
    @always_inline
    fn phi(self, i: Int32) -> Float:
        return self.stateAtBS.state[i][0]

    @always_inline
    fn tip(self, i: Int32) -> Float:
        return self.stateAtBS.state[i][1]

    @always_inline
    fn zip(self, i: Int32) -> Float:
        return self.stateAtBS.state[i][4]
