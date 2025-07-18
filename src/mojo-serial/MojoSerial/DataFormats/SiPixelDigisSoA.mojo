from memory import UnsafePointer

from MojoSerial.MojoBridge.DTypes import SizeType


@fieldwise_init
struct SiPixelDigisSoA(Copyable, Defaultable, Movable, Sized):
    var _pdigi: List[UInt32]
    var _rawIdArr: List[UInt32]
    var _adc: List[UInt16]
    var _clus: List[Int32]

    # default constructor
    fn __init__(out self):
        self._pdigi = List[UInt32]()
        self._rawIdArr = List[UInt32]()
        self._adc = List[UInt16]()
        self._clus = List[Int32]()

    # unsafe constructor for constructing the SoA object from C-style arrays
    fn __init__(
        out self,
        nDigis: SizeType,
        pdigi: UnsafePointer[UInt32],
        rawIdArr: UnsafePointer[UInt32],
        adc: UnsafePointer[UInt16],
        clus: UnsafePointer[Int32],
    ):
        self._pdigi = List[UInt32](capacity=nDigis)
        self._rawIdArr = List[UInt32](capacity=nDigis)
        self._adc = List[UInt16](capacity=nDigis)
        self._clus = List[Int32](capacity=nDigis)
        for i in range(nDigis):
            self._pdigi[i] = pdigi[i]
            self._rawIdArr[i] = rawIdArr[i]
            self._adc[i] = adc[i]
            self._clus[i] = clus[i]
        debug_assert(self._pdigi.__len__() == nDigis)

    fn __len__(self) -> Int:
        return self._pdigi.__len__()

    fn pdigi(self, i: SizeType) -> UInt32:
        return self._pdigi[i]

    fn rawIdArr(self, i: SizeType) -> UInt32:
        return self._rawIdArr[i]

    fn adc(self, i: SizeType) -> UInt16:
        return self._adc[i]

    fn clus(self, i: SizeType) -> Int32:
        return self._clus[i]

    fn pdigiList(self) -> ref [self._pdigi] List[UInt32]:
        return self._pdigi

    fn rawIdArrList(self) -> ref [self._rawIdArr] List[UInt32]:
        return self._rawIdArr

    fn adcList(self) -> ref [self._adc] List[UInt16]:
        return self._adc

    fn clusList(self) -> ref [self._clus] List[Int32]:
        return self._clus
