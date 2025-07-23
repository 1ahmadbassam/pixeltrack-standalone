from  memory import UnsafePointer
from CondFormats.SiPixelGainForHLTonGPU import SiPixelGainForHLTonGPU, SiPixelGainForHLTonGPU_DecodingStructure

struct SiPixelGainCalibrationForHLTGPU(Movable & Copyable):
    var gainForHLTonHost_: UnsafePointer[SiPixelGainForHLTonGPU]
    var gainData_: List[UInt8]

    fn __init__(out self):
        self.gainForHLTonHost_ = UnsafePointer[SiPixelGainForHLTonGPU]()
        self.gainData_ = List[UInt8](capacity = 0)
    '''
    fn __init__(out self, gain: SiPixelGainForHLTonGPU, gainData: List[UInt8]):
        self.gainForHLTonHost_ = SiPixelGainForHLTonGPU(gain)
        self.gainData_ = gainData'''

    fn __init__(out self, gain: SiPixelGainForHLTonGPU, gainData: List[UInt8]):
        self.gainData_ = gainData
        self.gainForHLTonHost_ = SiPixelGainForHLTonGPU(gain)
