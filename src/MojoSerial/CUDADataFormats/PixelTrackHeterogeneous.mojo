from MojoSerial.CUDACore.HistoContainer import OneToManyAssoc
from MojoSerial.MojoBridge.Matrix import Vector, Matrix

struct TrackQuality:
    alias bad: UInt8 = 0
    alias dup: UInt8 = 1
    alias loose: UInt8 = 2
    alias strict: UInt8 = 3
    alias tight: UInt8 = 4
    alias highPurity: UInt8 = 5

struct TrackSoAT[S: Int32]:
    alias Quality = UInt8
    alias HIndexType = DType.uint16
    alias HitContainer = OneToManyAssoc[S.cast[DType.uint32](), 5 * S.cast[DType.uint32](), Self.HIndexType]

    @staticmethod
    @always_inline
    fn stride() -> Int32:
        return S

