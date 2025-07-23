from CondFormats.SiPixelFedCablingMapGPU import SiPixelFedCablingMapGPU
from memory import Pointer

struct SiPixelFedCablingMapGPUWrapper(Movable & Copyable):
    var modToUnpDefault: List[UInt8]
    var hasQuality_: Bool
    var cablingMapHost: SiPixelFedCablingMapGPU


    fn hasQuality(self) -> Bool:
        return self.hasQuality_
    
    fn getCPUProduct(self) -> Pointer(origin: self)[mut = False, SiPixelFedCablingMapGPU]:
        return self.cablingMapHost
