from sys.info import sizeof

from MojoSerial.MojoBridge.DTypes import Typeable


struct HistoContainer[
    T: DType,
    NBINS: UInt32,
    SIZE: UInt32,
    S: UInt32 = sizeof[T](),
    I: DType = DType.uint32,
    NHISTS: UInt32 = 1,
](Movable, Defaultable, Typeable):
    fn __init__(out self):
        pass

    @always_inline
    fn size(self, b: UInt32) -> UInt32:
        return 0

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "HistoContainer[" + T.__repr__() + ", " + String(NBINS) + ", " + String(SIZE) + ", " + String(S) + ", " + I.__repr__() + ", " + String(NHISTS) + "]"

    # TODO: Implement this stub


alias OneToManyAssoc = HistoContainer[DType.uint32, _, _, I=_]
