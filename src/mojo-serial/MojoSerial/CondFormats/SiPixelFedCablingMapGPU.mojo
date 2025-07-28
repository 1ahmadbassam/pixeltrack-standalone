from sys import sizeof
from memory import UnsafePointer

from MojoSerial.CondFormats.PixelCPEforGPU import (
    CommonParams,
    DetParams,
    LayerGeometry,
    AverageGeometry,
    ParamsOnGPU,
)
from MojoSerial.MojoBridge.DTypes import UChar, Typeable


@nonmaterializable(NoneType)
struct PixelGPUDetails:
    # Maximum fed for phase1 is 150 but not all of them are filled
    # Update the number FED based on maximum fed found in the cabling map
    alias MAX_FED: UInt = 150
    alias MAX_LINK: UInt = 48  # maximum links/channels for Phase 1
    alias MAX_ROC: UInt = 8
    alias MAX_SIZE = Self.MAX_FED * Self.MAX_LINK * Self.MAX_ROC
    alias MAX_SIZE_BYTE_BOOL = Self.MAX_SIZE * sizeof[UChar]()


@fieldwise_init
struct SiPixelFedCablingMapGPU(Copyable, Defaultable, Movable, Typeable):
    alias _U = InlineArray[UInt32, PixelGPUDetails.MAX_SIZE]
    alias _C = InlineArray[UChar, PixelGPUDetails.MAX_SIZE]
    var fed: Self._U
    var link: Self._U
    var roc: Self._U
    var RawId: Self._U
    var rocInDet: Self._U
    var moduleId: Self._U
    var badRocs: Self._C
    var size: UInt

    @always_inline
    fn __init__(out self):
        self.fed = Self._U(0)
        self.link = Self._U(0)
        self.roc = Self._U(0)
        self.RawId = Self._U(0)
        self.rocInDet = Self._U(0)
        self.moduleId = Self._U(0)
        self.badRocs = Self._C(0)
        self.size = 0

    @always_inline
    fn __init__(
        out self,
        owned fed: Self._U,
        owned link: Self._U,
        owned roc: Self._U,
        owned RawId: Self._U,
        owned rocInDet: Self._U,
        owned moduleId: Self._U,
        owned badRocs: Self._C,
    ):
        self.fed = fed^
        self.link = link^
        self.roc = roc^
        self.RawId = RawId^
        self.rocInDet = rocInDet^
        self.moduleId = moduleId^
        self.badRocs = badRocs^
        self.size = 0

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self.fed = other.fed^
        self.link = other.link^
        self.roc = other.roc^
        self.RawId = other.RawId^
        self.rocInDet = other.rocInDet^
        self.moduleId = other.moduleId^
        self.badRocs = other.badRocs^
        self.size = other.size

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelFedCablingMapGPU"
