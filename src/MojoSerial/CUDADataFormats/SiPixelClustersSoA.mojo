from memory import UnsafePointer, OwnedPointer

from MojoSerial.MojoBridge.DTypes import SizeType

@fieldwise_init
struct DeviceConstView(Movable, Copyable, EqualityComparable):
    var _moduleStart: UnsafePointer[UInt32]
    var _clusInModule: UnsafePointer[UInt32]
    var _moduleId: UnsafePointer[UInt32]
    var _clusModuleStart: UnsafePointer[UInt32]
    var __destruct: Bool

    @always_inline
    fn __init__(out self):
        self._moduleStart = UnsafePointer[UInt32]()
        self._clusInModule = UnsafePointer[UInt32]()
        self._moduleId = UnsafePointer[UInt32]()
        self._clusModuleStart = UnsafePointer[UInt32]()
        self.__destruct = True

    fn __init__(out self, maxClusters: SizeType):
        self._moduleStart = UnsafePointer[UInt32].alloc(maxClusters + 1)
        self._clusInModule = UnsafePointer[UInt32].alloc(maxClusters)
        self._moduleId = UnsafePointer[UInt32].alloc(maxClusters)
        self._clusModuleStart = UnsafePointer[UInt32].alloc(maxClusters + 1)
        for i in range(maxClusters):
            (self._moduleStart + i).init_pointee_move(0)
            (self._clusInModule + i).init_pointee_move(0)
            (self._moduleId + i).init_pointee_move(0)
            (self._clusModuleStart + i).init_pointee_move(0)
        self.__destruct = True

    @always_inline
    fn __init__(out self, owned moduleStart: UnsafePointer[UInt32], owned clusInModule: UnsafePointer[UInt32], owned moduleId: UnsafePointer[UInt32], owned clusModuleStart: UnsafePointer[UInt32]):
        self._moduleStart = moduleStart
        self._clusInModule = clusInModule
        self._moduleId = moduleId
        self._clusModuleStart = clusModuleStart
        self.__destruct = False

    @always_inline
    fn __init__(out self, owned moduleStart: UInt32, owned clusInModule: UInt32, owned moduleId: UInt32, owned clusModuleStart: UInt32):
        self._moduleStart = UnsafePointer[UInt32].alloc(1)
        self._moduleStart.init_pointee_move(moduleStart)
        self._clusInModule = UnsafePointer[UInt32].alloc(1)
        self._clusInModule.init_pointee_move(clusInModule)
        self._moduleId = UnsafePointer[UInt32].alloc(1)
        self._moduleId.init_pointee_move(moduleId)
        self._clusModuleStart = UnsafePointer[UInt32].alloc(1)
        self._clusModuleStart.init_pointee_move(clusModuleStart)
        self.__destruct = True        

    @always_inline
    fn __del__(owned self):
        if self.__destruct:
            # no need to destroy trivial type UInt32
            self._moduleStart.free()
            self._clusInModule.free()
            self._moduleId.free()
            self._clusModuleStart.free()

    fn __eq__(self, other: Self) -> Bool:
        return self._moduleStart == other._moduleStart and self._clusInModule == other._clusInModule and self._moduleId == other._moduleId and self._clusModuleStart == other._clusModuleStart

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    fn moduleStart (self, i: Int) -> UInt32:
        return self._moduleStart[i]

    @always_inline
    fn clusInModule (self, i: Int) -> UInt32:
        return self._clusInModule[i]

    @always_inline
    fn moduleId (self, i: Int) -> UInt32:
        return self._moduleId[i]

    @always_inline
    fn clusModuleStart (self, i: Int) -> UInt32:
        return self._clusModuleStart[i]

@fieldwise_init
struct SiPixelClustersSoA(Movable, EqualityComparable):
    var view_d: OwnedPointer[DeviceConstView]
    var moduleStart_d: UnsafePointer[UInt32]
    var clusInModule_d: UnsafePointer[UInt32]
    var moduleId_d: UnsafePointer[UInt32]
    var clusModuleStart_d: UnsafePointer[UInt32]
    var nClusters_h: UInt32

    fn __init__(out self):
        self.view_d = OwnedPointer[](DeviceConstView())
        self.moduleStart_d = UnsafePointer[UInt32]()
        self.clusInModule_d = UnsafePointer[UInt32]()
        self.moduleId_d = UnsafePointer[UInt32]()
        self.clusModuleStart_d = UnsafePointer[UInt32]()
        self.nClusters_h = 0

    fn __init__(out self, maxClusters: SizeType):
        self.moduleStart_d = UnsafePointer[UInt32].alloc(maxClusters + 1)
        self.clusInModule_d = UnsafePointer[UInt32].alloc(maxClusters)
        self.moduleId_d = UnsafePointer[UInt32].alloc(maxClusters)
        self.clusModuleStart_d = UnsafePointer[UInt32].alloc(maxClusters + 1)
        for i in range(maxClusters):
            (self.moduleStart_d + i).init_pointee_move(0)
            (self.clusInModule_d + i).init_pointee_move(0)
            (self.moduleId_d + i).init_pointee_move(0)
            (self.clusModuleStart_d + i).init_pointee_move(0)
        (self.moduleStart_d + maxClusters + 1).init_pointee_move(0)
        (self.clusModuleStart_d + maxClusters + 1).init_pointee_move(0)
        self.nClusters_h = 0
        self.view_d = OwnedPointer[](DeviceConstView(self.moduleStart_d, self.clusInModule_d, self.moduleId_d, self.clusModuleStart_d))

    fn view (self) -> Pointer[mut=False, DeviceConstView, __origin_of(self.view_d)]:
        return Pointer[](to=self.view_d[])

    fn __eq__(self, other: Self) -> Bool:
        return self.view_d[] == other.view_d[] and self.moduleStart_d == other.moduleStart_d and self.clusInModule_d == other.clusInModule_d and self.moduleId_d == other.moduleId_d and self.clusModuleStart_d == other.clusModuleStart_d and self.nClusters_h == other.nClusters_h

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


