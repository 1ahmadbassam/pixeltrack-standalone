from memory import UnsafePointer

from MojoSerial.MojoBridge.DTypes import SizeType

@fieldwise_init
struct DeviceConstView(Movable):
    var _xx: UnsafePointer[UInt16]
    var _yy: UnsafePointer[UInt16]
    var _adc: UnsafePointer[UInt16]
    var _moduleInd: UnsafePointer[UInt16]
    var _clus: UnsafePointer[Int32]

    @always_inline
    fn __init__(out self):
        self._xx = UnsafePointer[UInt16]()
        self._yy = UnsafePointer[UInt16]()
        self._adc = UnsafePointer[UInt16]()
        self._moduleInd = UnsafePointer[UInt16]()
        self._clus = UnsafePointer[Int32]()

    @always_inline
    fn xx(self, i: Int) -> UInt16:
        return self._xx[i]
    
    @always_inline
    fn yy(self, i: Int) -> UInt16:
        return self._yy[i]

    @always_inline
    fn adc(self, i: Int) -> UInt16:
        return self._adc[i]
    
    @always_inline
    fn moduleInd(self, i: Int) -> UInt16:
        return self._moduleInd[i]

    @always_inline
    fn clus(self, i: Int) -> Int32:
        return self._clus[i]
    

struct SiPixelDigisSoA(Movable):
    var xx_d: List[UInt16]
    var yy_d: List[UInt16]
    var adc_d: List[UInt16]
    var moduleInd_d: List[UInt16]
    var clus_d: List[Int32]
    var view_d: DeviceConstView

    var pdigi_d: List[UInt32]
    var rawIdArr_d: List[UInt32]

    var nModules_h: UInt32
    var nDigis_h: UInt32

    @always_inline
    fn __init__(out self):
        self.xx_d = []
        self.yy_d = []
        self.adc_d = []
        self.moduleInd_d = []
        self.clus_d = []
        self.view_d = DeviceConstView()

        self.pdigi_d = []
        self.rawIdArr_d = []

        self.nModules_h = 0
        self.nDigis_h = 0

    @always_inline
    fn __init__(out self, maxFedWords: SizeType):
        self.xx_d = List[UInt16](capacity=maxFedWords)
        self.yy_d = List[UInt16](capacity=maxFedWords)
        self.adc_d = List[UInt16](capacity=maxFedWords)
        self.moduleInd_d = List[UInt16](capacity=maxFedWords)
        self.clus_d = List[Int32](capacity=maxFedWords)
        self.view_d = DeviceConstView(self.xx_d.unsafe_ptr(), self.yy_d.unsafe_ptr(), self.adc_d.unsafe_ptr(), self.moduleInd_d.unsafe_ptr(), self.clus_d.unsafe_ptr())

        self.pdigi_d = List[UInt32](capacity=maxFedWords)
        self.rawIdArr_d = List[UInt32](capacity=maxFedWords)

        self.nModules_h = 0
        self.nDigis_h = 0

    @always_inline
    fn view (self) -> Pointer[mut=False, DeviceConstView, __origin_of(self.view_d)]:
        return Pointer[](to=self.view_d)

    @always_inline
    fn setNModulesDigis(mut self, nModules: UInt32, nDigis: UInt32):
        self.nModules_h = nModules
        self.nDigis_h = nDigis
    
    @always_inline
    fn nModules(self) -> UInt32:
        return self.nModules_h

    @always_inline
    fn nDigis(self) -> UInt32:
        return self.nDigis_h

    @always_inline
    fn xx(ref self) -> UnsafePointer[UInt16]:
        return self.xx_d.unsafe_ptr()

    @always_inline
    fn yy(ref self) -> UnsafePointer[UInt16]:
        return self.yy_d.unsafe_ptr()

    @always_inline
    fn adc(ref self) -> UnsafePointer[UInt16]:
        return self.adc_d.unsafe_ptr()

    @always_inline
    fn moduleInd(ref self) -> UnsafePointer[UInt16]:
        return self.moduleInd_d.unsafe_ptr()

    @always_inline
    fn clus(ref self) -> UnsafePointer[Int32]:
        return self.clus_d.unsafe_ptr()

    @always_inline
    fn pdigi(ref self) -> UnsafePointer[UInt32]:
        return self.pdigi_d.unsafe_ptr()

    @always_inline
    fn rawIdArr(ref self) -> UnsafePointer[UInt32]:
        return self.rawIdArr_d.unsafe_ptr()

    @always_inline
    fn c_xx(self) -> UnsafePointer[UInt16]:
        return self.xx_d.unsafe_ptr()

    @always_inline
    fn c_yy(self) -> UnsafePointer[UInt16]:
        return self.yy_d.unsafe_ptr()

    @always_inline
    fn c_adc(self) -> UnsafePointer[UInt16]:
        return self.adc_d.unsafe_ptr()

    @always_inline
    fn c_moduleInd(self) -> UnsafePointer[UInt16]:
        return self.moduleInd_d.unsafe_ptr()

    @always_inline
    fn c_clus(self) -> UnsafePointer[Int32]:
        return self.clus_d.unsafe_ptr()

    @always_inline
    fn c_pdigi(self) -> UnsafePointer[UInt32]:
        return self.pdigi_d.unsafe_ptr()

    @always_inline
    fn c_rawIdArr(self) -> UnsafePointer[UInt32]:
        return self.rawIdArr_d.unsafe_ptr()
