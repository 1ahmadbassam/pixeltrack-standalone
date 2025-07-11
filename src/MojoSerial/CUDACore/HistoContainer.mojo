from sys.info import sizeof

struct HistoContainer[T: DType, NBINS: UInt32, SIZE: UInt32, S: UInt32 = sizeof[T](), I: DType = DType.uint32, NHISTS: UInt32 = 1]:
    pass

alias OneToManyAssoc = HistoContainer[DType.uint32, _, _, I=_]
