from sys.info import sizeof
from CondFormats.pixelCPEforGPU import CommonParams, DetParams, LayerGeometry, AverageGeometry, ParamsOnGPU
from memory import UnsafePointer
#from buffer import DimList

alias MAX_FED: UInt32 = 150
alias MAX_LINK: UInt32 = 48
alias MAX_ROC: UInt32 = 8
alias MAX_SIZE: UInt32 = MAX_FED * MAX_LINK * MAX_ROC
alias MAX_SIZE_BYTE_BOOL: UInt32 = MAX_SIZE * sizeof[UInt8]()


@fieldwise_init
struct SiPixelFedCablingMapGPU (Copyable, Movable):
    var fed: InlineArray[UInt32, Int(MAX_SIZE)]
    var link: InlineArray[UInt32, Int(MAX_SIZE)] 
    var roc: InlineArray[UInt32, Int(MAX_SIZE)]
    var RawId: InlineArray[UInt32, Int(MAX_SIZE)]
    var rocInDet: InlineArray[UInt32, Int(MAX_SIZE)]
    var moduleId: InlineArray[UInt32, Int(MAX_SIZE)]
    var badRocs: InlineArray[UInt8, Int(MAX_SIZE)] 
    var size: UInt32
