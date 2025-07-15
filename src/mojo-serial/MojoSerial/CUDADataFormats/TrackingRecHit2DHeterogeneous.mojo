from sys import sizeof
from memory import UnsafePointer

from MojoSerial.CondFormats.PixelCPEforGPU import ParamsOnGPU
from MojoSerial.CUDACore.CudaCompat import CudaStreamType, cudaStreamDefault
from MojoSerial.CUDADataFormats.HeterogeneousSoA import Traits, CPUTraits
from MojoSerial.CUDADataFormats.TrackingRecHit2DSOAView import Hist, TrackingRecHit2DSOAView
from MojoSerial.Geometry.Phase1PixelTopology import Phase1PixelTopology, AverageGeometry
from MojoSerial.MojoBridge.DTypes import Float

# even though Traits are deprecated, the syntax is compatible for compatibility purposes

struct TrackingRecHit2DHeterogeneous[T: Movable & Copyable, //, Tr: Traits = CPUTraits[T]](Movable, Defaultable):
    alias UniquePointer = Tr.UniquePointer

    alias n16: UInt32 = 4
    alias n32: UInt32 = 9

    alias __d = debug_assert(sizeof[UInt32]() == sizeof[Float]()) # idk why this exists

    var m_store16: List[UInt16]
    var m_store32: List[Float]

    var m_HistStore: Hist
    var m_AverageGeometryStore: AverageGeometry

    var m_view: TrackingRecHit2DSOAView

    var m_nHits: UInt32
    var m_hitsModuleStart: UnsafePointer[UInt32]

    var m_hist: UnsafePointer[Hist]
    var m_hitsLayerStart: UnsafePointer[UInt32]
    var m_iphi: UnsafePointer[Int16]

    @always_inline
    fn __init__(out self):
        self.m_store16 = []
        self.m_store32 = []
        self.m_HistStore = Hist()
        self.m_AverageGeometryStore = AverageGeometry()
        self.m_view = TrackingRecHit2DSOAView()

        self.m_nHits = 0
        self.m_hitsModuleStart = UnsafePointer[UInt32]()
        self.m_hist = UnsafePointer(to=self.m_HistStore)

        self.m_hitsLayerStart = UnsafePointer[UInt32]()
        self.m_iphi = UnsafePointer[Int16]()

    fn __init__(out self, nHits: UInt32, cpeParams: ParamsOnGPU, hitsModuleStart: UnsafePointer[UInt32], stream: CudaStreamType = cudaStreamDefault):
        self.m_store16 = []
        self.m_store32 = []
        self.m_HistStore = Hist()
        self.m_AverageGeometryStore = AverageGeometry()
        self.m_view = TrackingRecHit2DSOAView()

        self.m_nHits = nHits
        self.m_hitsModuleStart = hitsModuleStart
        self.m_hist = UnsafePointer(to=self.m_HistStore)
        # cannot wrap self in an @parameter function without having all fields initialized
        self.m_hitsLayerStart = UnsafePointer[UInt32]()
        self.m_iphi = UnsafePointer[Int16]()

        @parameter
        fn get16 (i: Int) -> UnsafePointer[UInt16]:
            return (self.m_store16.unsafe_ptr() + i * nHits)

        @parameter
        fn get32 (i: Int) -> UnsafePointer[Float]:
            return (self.m_store32.unsafe_ptr() + i * nHits)

        self.m_hitsLayerStart = get32(Int(Self.n32)).bitcast[UInt32]()
        self.m_iphi = get16(0).bitcast[Int16]()

        # if empy do not bother
        if nHits == 0:
            return
        
        self.m_view.m_nHits = UnsafePointer(to=self.m_nHits)
        self.m_view.m_averageGeometry = UnsafePointer(to=self.m_AverageGeometryStore)
        self.m_view.m_cpeParams = cpeParams
        self.m_view.m_hitsModuleStart = self.m_hitsModuleStart

        self.m_view.m_hist = self.m_hist

        self.m_view.m_xl = get32(0)
        self.m_view.m_yl = get32(1)
        self.m_view.m_xerr = get32(2)
        self.m_view.m_yerr = get32(3)

        self.m_view.m_xg = get32(4)
        self.m_view.m_yg = get32(5)
        self.m_view.m_zg = get32(6)
        self.m_view.m_rg = get32(7)

        self.m_view.m_iphi = self.m_iphi

        self.m_view.m_charge = get32(8).bitcast[Int32]()
        self.m_view.m_xsize = get16(2).bitcast[Int16]()
        self.m_view.m_ysize = get16(3).bitcast[Int16]()
        self.m_view.m_detInd = get16(1)

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self.m_store16 = other.m_store16^ 
        self.m_store32 = other.m_store32^ 
        self.m_HistStore = other.m_HistStore^ 
        self.m_AverageGeometryStore = other.m_AverageGeometryStore^ 
        self.m_view = other.m_view^ 

        self.m_nHits = other.m_nHits 
        self.m_hitsModuleStart = other.m_hitsModuleStart 
        self.m_hist = other.m_hist 

        self.m_hitsLayerStart = other.m_hitsLayerStart
        self.m_iphi = other.m_iphi 

    @always_inline
    fn view[
        is_mutable: Bool, //, origin: Origin[is_mutable]
    ](ref [origin] self) -> Pointer[TrackingRecHit2DSOAView, __origin_of(self.m_view)]:
        return Pointer[](to=self.m_view)

    @always_inline
    fn nHits(self) -> UInt32:
        return self.m_nHits

    @always_inline
    fn hitsModuleStart(self) -> UnsafePointer[UInt32]:
        return self.m_hitsModuleStart

    @always_inline
    fn hitsLayerStart(self) -> UnsafePointer[UInt32]:
        return self.m_hitsLayerStart

    @always_inline
    fn phiBinner(self) -> UnsafePointer[Hist]:
        return self.m_hist

    @always_inline
    fn iphi(self) -> UnsafePointer[Int16]:
        return self.m_iphi


alias TrackingRecHit2DCPU = TrackingRecHit2DHeterogeneous
