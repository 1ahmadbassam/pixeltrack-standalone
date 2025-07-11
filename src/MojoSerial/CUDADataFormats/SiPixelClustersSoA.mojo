from memory import UnsafePointer

@fieldwise_init
struct DeviceConstView(Movable, Copyable):
    var _moduleStart: UnsafePointer[UInt32]
    var _clusInModule: UnsafePointer[UInt32]
    var _moduleId: UnsafePointer[UInt32]
    var _clusModuleStart: UnsafePointer[UInt32]
    var _destruct: Bool

    fn __init__(out self, owned moduleStart: UnsafePointer[UInt32], owned clusInModule: UnsafePointer[UInt32], owned moduleId: UnsafePointer[UInt32], owned clusModuleStart: UnsafePointer[UInt32]):
        self._moduleStart = moduleStart
        self._clusInModule = clusInModule
        self._moduleId = moduleId
        self._clusModuleStart = clusModuleStart
        self._destruct = False

    fn __init__(out self, owned moduleStart: UInt32, owned clusInModule: UInt32, owned moduleId: UInt32, owned clusModuleStart: UInt32):
        self._moduleStart = UnsafePointer[UInt32].alloc(1)
        self._moduleStart.init_pointee_move(moduleStart)
        self._clusInModule = UnsafePointer[UInt32].alloc(1)
        self._clusInModule.init_pointee_move(clusInModule)
        self._moduleId = UnsafePointer[UInt32].alloc(1)
        self._moduleId.init_pointee_move(moduleId)
        self._clusModuleStart = UnsafePointer[UInt32].alloc(1)
        self._clusModuleStart.init_pointee_move(clusModuleStart)

        self._destruct = True

    fn __del__(owned self):
        if self._destruct:
            # no need to destroy trivial type UInt32
            self._moduleStart.free()
            self._clusInModule.free()
            self._moduleId.free()
            self._clusModuleStart.free()

