from memory import UnsafePointer, OwnedPointer

from MojoSerial.MojoBridge.DTypes import SizeType

alias nullptr = UnsafePointer[UInt32]()

@fieldwise_init
struct DeviceConstView(Movable):
    var _moduleStart: UnsafePointer[UInt32]
    var _clusInModule: UnsafePointer[UInt32]
    var _moduleId: UnsafePointer[UInt32]
    var _clusModuleStart: UnsafePointer[UInt32]
    var __destruct: Bool

    @always_inline
    fn __init__(out self):
        self._moduleStart = nullptr
        self._clusInModule = nullptr
        self._moduleId = nullptr
        self._clusModuleStart = nullptr
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
struct SiPixelClustersSoA(Movable):
    var view_d: OwnedPointer[DeviceConstView]
    var moduleStart_d: UnsafePointer[UInt32]
    var clusInModule_d: UnsafePointer[UInt32]
    var moduleId_d: UnsafePointer[UInt32]
    var clusModuleStart_d: UnsafePointer[UInt32]
    var nClusters_h: UInt32

    fn __init__(out self):
        self.view_d = OwnedPointer[](DeviceConstView())
        self.moduleStart_d = nullptr
        self.clusInModule_d = nullptr
        self.moduleId_d = nullptr
        self.clusModuleStart_d = nullptr
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

    fn __del__(owned self):
        if self.moduleStart_d != nullptr:
            self.moduleStart_d.free()
        if self.clusInModule_d != nullptr:
            self.clusInModule_d.free()
        if self.moduleId_d != nullptr:
            self.moduleId_d.free()
        if self.clusModuleStart_d != nullptr:
            self.clusModuleStart_d.free()

    fn view (self) -> Pointer[mut=False, DeviceConstView, __origin_of(self.view_d)]:
        return Pointer[](to=self.view_d[])

    fn nClusters(self) -> UInt32:
        return self.nClusters_h

    fn setNClusters(mut self, nClusters: UInt32):
        self.nClusters_h = nClusters

    fn moduleStart(ref self) -> ref [self.moduleStart_d] UnsafePointer[UInt32]:
        return self.moduleStart_d
    
    fn clusInModule(ref self) -> ref [self.clusInModule_d] UnsafePointer[UInt32]:
        return self.clusInModule_d

    fn moduleId(ref self) -> ref [self.moduleId_d] UnsafePointer[UInt32]:
        return self.moduleId_d

    fn clusModuleStart(ref self) -> ref [self.clusModuleStart_d] UnsafePointer[UInt32]:
        return self.clusModuleStart_d
    