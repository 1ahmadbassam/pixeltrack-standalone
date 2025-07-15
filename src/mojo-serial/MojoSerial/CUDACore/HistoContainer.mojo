from sys.info import sizeof

struct HistoContainer[T: DType, NBINS: UInt32, SIZE: UInt32, S: UInt32 = sizeof[T](), I: DType = DType.uint32, NHISTS: UInt32 = 1](Movable, Defaultable):
    fn __init__(out self):
        pass

    @always_inline
    fn size(self, b: UInt32) -> UInt32:
        return 0
    # TODO: Implement this stub

alias OneToManyAssoc = HistoContainer[DType.uint32, _, _, I=_]
