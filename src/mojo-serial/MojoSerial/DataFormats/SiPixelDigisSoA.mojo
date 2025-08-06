from MojoSerial.MojoBridge.DTypes import SizeType, Typeable


@fieldwise_init
struct SiPixelDigisSoA(Copyable, Defaultable, Movable, Sized, Typeable):
    var _pdigi: List[UInt32]
    var _rawIdArr: List[UInt32]
    var _adc: List[UInt16]
    var _clus: List[Int32]

    # default constructor
    @always_inline
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
        debug_assert(nDigis > 0)
        self._pdigi = List[UInt32](capacity=UInt(nDigis))
        self._rawIdArr = List[UInt32](capacity=UInt(nDigis))
        self._adc = List[UInt16](capacity=UInt(nDigis))
        self._clus = List[Int32](capacity=UInt(nDigis))
        for i in range(UInt(nDigis)):
            self._pdigi[i] = pdigi[i]
            self._rawIdArr[i] = rawIdArr[i]
            self._adc[i] = adc[i]
            self._clus[i] = clus[i]
        debug_assert(self._pdigi.__len__() == UInt(nDigis))

    @always_inline
    fn __len__(self) -> Int:
        return self._pdigi.__len__()

    @always_inline
    fn pdigi(self, i: SizeType) -> UInt32:
        return self._pdigi[i]

    @always_inline
    fn rawIdArr(self, i: SizeType) -> UInt32:
        return self._rawIdArr[i]

    @always_inline
    fn adc(self, i: SizeType) -> UInt16:
        return self._adc[i]

    @always_inline
    fn clus(self, i: SizeType) -> Int32:
        return self._clus[i]

    @always_inline
    fn pdigiList(self) -> ref [self._pdigi] List[UInt32]:
        return self._pdigi

    @always_inline
    fn rawIdArrList(self) -> ref [self._rawIdArr] List[UInt32]:
        return self._rawIdArr

    @always_inline
    fn adcList(self) -> ref [self._adc] List[UInt16]:
        return self._adc

    @always_inline
    fn clusList(self) -> ref [self._clus] List[Int32]:
        return self._clus

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelDigisSoA"
