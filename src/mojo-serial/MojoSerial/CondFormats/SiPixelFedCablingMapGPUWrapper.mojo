from MojoSerial.CondFormats.SiPixelFedCablingMapGPU import (
    SiPixelFedCablingMapGPU,
)
from MojoSerial.MojoBridge.DTypes import UChar, Typeable


struct SiPixelFedCablingMapGPUWrapper(Defaultable, Movable, Typeable):
    var modToUnpDefault: List[UChar]
    var _hasQuality: Bool
    var cablingMapHost: SiPixelFedCablingMapGPU

    @always_inline
    fn __init__(out self):
        self.modToUnpDefault = []
        self._hasQuality = False
        self.cablingMapHost = SiPixelFedCablingMapGPU()

    @always_inline
    fn __init__(
        out self,
        var cablingMap: SiPixelFedCablingMapGPU,
        var modToUnp: List[UChar],
    ):
        self.modToUnpDefault = modToUnp^
        self._hasQuality = True
        self.cablingMapHost = cablingMap^

    @always_inline
    fn __moveinit__(out self, var other: Self):
        self.modToUnpDefault = other.modToUnpDefault^
        self._hasQuality = other._hasQuality
        self.cablingMapHost = other.cablingMapHost^

    fn hasQuality(self) -> Bool:
        return self._hasQuality

    fn getCPUProduct(self) -> UnsafePointer[SiPixelFedCablingMapGPU, mut=False]:
        return UnsafePointer(to=self.cablingMapHost)

    fn getModToUnpAll(self) -> UnsafePointer[UChar, mut=False]:
        return self.modToUnpDefault.unsafe_ptr()

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelFedCablingMapGPUWrapper"
