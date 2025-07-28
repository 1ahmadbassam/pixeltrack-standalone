from memory import UnsafePointer, memcpy, memset

from MojoSerial.MojoBridge.DTypes import UChar, Double, Float, Typeable
from MojoSerial.CUDADataFormats.SiPixelDigisSoA import SiPixelDigisSoA
from MojoSerial.CUDADataFormats.SiPixelDigiErrorsSoA import SiPixelDigiErrorsSoA
from MojoSerial.CUDADataFormats.SiPixelClustersSoA import SiPixelClustersSoA
from MojoSerial.CondFormats.SiPixelFedCablingMapGPU import (
    SiPixelFedCablingMapGPU,
)
from MojoSerial.PluginSiPixelClusterizer.PixelGPUDetails import PixelGPUDetails


@fieldwise_init
@register_passable("trivial")
struct DetIdGPU(Copyable, Defaultable, Movable, Typeable):
    var RawId: UInt32
    var rocInDet: UInt32
    var moduleId: UInt32

    @always_inline
    fn __init__(out self):
        self.RawId = 0
        self.rocInDet = 0
        self.moduleId = 0

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "DetIdGPU"


@fieldwise_init
@register_passable("trivial")
struct Pixel(Copyable, Defaultable, Movable, Typeable):
    var row: UInt32
    var col: UInt32

    @always_inline
    fn __init__(out self):
        self.row = 0
        self.col = 0

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "Pixel"


@fieldwise_init
struct Packing(Copyable, Defaultable, Movable, Typeable):
    alias PackedDigiType = UInt32

    var row_width: UInt32
    var column_width: UInt32
    var adc_width: UInt32

    var row_shift: UInt32
    var column_shift: UInt32
    var time_shift: UInt32
    var adc_shift: UInt32

    var row_mask: Self.PackedDigiType
    var column_mask: Self.PackedDigiType
    var time_mask: Self.PackedDigiType
    var adc_mask: Self.PackedDigiType
    var rowcol_mask: Self.PackedDigiType

    var max_row: UInt32
    var max_column: UInt32
    var max_adc: UInt32

    @always_inline
    fn __init__(out self):
        self.row_width = 0
        self.column_width = 0
        self.adc_width = 0

        self.row_shift = 0
        self.column_shift = 0
        self.time_shift = 0
        self.adc_shift = 0

        self.row_mask = 0
        self.column_mask = 0
        self.time_mask = 0
        self.adc_mask = 0
        self.rowcol_mask = 0

        self.max_row = 0
        self.max_column = 0
        self.max_adc = 0

    @always_inline
    fn __init__(
        out self,
        owned row_w: UInt32,
        owned column_w: UInt32,
        owned time_w: UInt32,
        owned adc_w: UInt32,
    ):
        self.row_width = row_w
        self.column_width = column_w
        self.adc_width = adc_w
        self.row_shift = 0
        self.column_shift = self.row_shift + row_w
        self.time_shift = self.column_shift + column_w
        self.adc_shift = self.time_shift + time_w
        self.row_mask = ~(~UInt32(0) << row_w)
        self.column_mask = ~(~UInt32(0) << column_w)
        self.time_mask = ~(~UInt32(0) << time_w)
        self.adc_mask = ~(~UInt32(0) << adc_w)
        self.rowcol_mask = ~(~UInt32(0) << (column_w + row_w))
        self.max_row = self.row_mask
        self.max_column = self.column_mask
        self.max_adc = self.adc_mask

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "Packing"


@always_inline
fn packing() -> Packing:
    return Packing(11, 11, 0, 10)


@always_inline
fn pack(owned row: UInt32, owned col: UInt32, owned adc: UInt32) -> UInt32:
    alias thePacking = packing()
    adc = min(adc, thePacking.max_adc)

    return (
        (row << thePacking.row_shift)
        | (col << thePacking.column_shift)
        | (adc << thePacking.adc_shift)
    )


@always_inline
fn pixelToChannel(row: Int, col: Int) -> UInt32:
    alias thePacking = packing()
    return (row << Int(thePacking.column_width)) | col


struct WordFedAppender(Defaultable, Movable, Typeable):
    alias MAX_FED_WORDS: UInt32 = PixelGPUDetails.MAX_FED * PixelGPUDetails.MAX_WORD
    var _word: InlineArray[UInt32, Int(Self.MAX_FED_WORDS)]
    var _fedId: InlineArray[UChar, Int(Self.MAX_FED_WORDS)]

    @always_inline
    fn __init__(out self):
        self._word = InlineArray[UInt32, Int(Self.MAX_FED_WORDS)](0)
        self._fedId = InlineArray[UChar, Int(Self.MAX_FED_WORDS)](0)

    fn initializeWordFed(
        self,
        owned fedId: Int32,
        owned wordCounterGPU: UInt32,
        src: UnsafePointer[UInt32],
        length: UInt32,
    ):
        memcpy(self._word.unsafe_ptr() + wordCounterGPU, src, Int(length))
        memset(
            self._fedId.unsafe_ptr() + wordCounterGPU / 2,
            UChar(fedId - 1200),
            Int(length / 2),
        )

    @always_inline
    fn word(self) -> UnsafePointer[UInt32, mut=False]:
        return self._word.unsafe_ptr()

    @always_inline
    fn fedId(self) -> UnsafePointer[UChar, mut=False]:
        return self._fedId.unsafe_ptr()

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "WordFedAppender"


struct SiPixelRawToClusterGPUKernel(Defaultable, Typeable):
    var digis_d: UnsafePointer[SiPixelDigisSoA]
    var clusters_d: UnsafePointer[SiPixelClustersSoA]
    var digiErrors_d: UnsafePointer[SiPixelDigiErrorsSoA]

    @always_inline
    fn __init__(out self):
        self.digis_d = UnsafePointer[SiPixelDigisSoA].alloc(1)
        self.digis_d.init_pointee_move(SiPixelDigisSoA())
        self.clusters_d = UnsafePointer[SiPixelClustersSoA].alloc(1)
        self.clusters_d.init_pointee_move(SiPixelClustersSoA())
        self.digiErrors_d = UnsafePointer[SiPixelDigiErrorsSoA].alloc(1)
        self.digiErrors_d.init_pointee_move(SiPixelDigiErrorsSoA())

    @always_inline
    fn __del__(owned self):
        self.digis_d.free()
        self.clusters_d.free()
        self.digiErrors_d.free()

    fn getResultsDigis(mut self) -> SiPixelDigisSoA:
        return self.digis_d.take_pointee()

    fn getResultsClusters(mut self) -> SiPixelClustersSoA:
        return self.clusters_d.take_pointee()

    fn getErrors(mut self) -> SiPixelDigiErrorsSoA:
        return self.digiErrors_d.take_pointee()

    # void makeClusters...

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelRawToClusterGPUKernel"


@nonmaterializable(NoneType)
struct ADCThreshold:
    # default Pixel threshold in electrons
    alias thePixelThreshold: Int = 1000
    # seed threshold in electrons not used in our algo
    alias theSeedThreshold: Int = 1000
    # cluster threshold in electron
    alias theClusterThreshold: Float = 4000
    # adc to electron conversion factor
    alias ConversionFactor: Int = 65
    # the maximum adc count for stack layer
    alias _theStackADC: Int = 255
    # the index of the fits stack layer
    alias _theFirstStack: Int = 5
    # ADC to electron
    alias _theElectronPerADCGain: Double = 600


fn getLink(ww: UInt32) -> UInt32:
    return (ww >> PixelGPUDetails.LINK_shift) & PixelGPUDetails.LINK_mask


fn getRoc(ww: UInt32) -> UInt32:
    return (ww >> PixelGPUDetails.ROC_shift) & PixelGPUDetails.ROC_mask


fn getADC(ww: UInt32) -> UInt32:
    return (ww >> PixelGPUDetails.ADC_shift) & PixelGPUDetails.ADC_mask


fn isBarrel(rawId: UInt32) -> Bool:
    return UInt32(1) == ((rawId >> 25) & 0x7)


fn getRawId(
    ref cablingMap: SiPixelFedCablingMapGPU,
    fed: UInt8,
    link: UInt32,
    roc: UInt32,
) -> DetIdGPU:
    var index: UInt32 = (
        fed.cast[DType.uint32]()
        * PixelGPUDetails.MAX_LINK
        * PixelGPUDetails.MAX_ROC
        + (link - 1) * PixelGPUDetails.MAX_ROC
        + roc
    )
    var detId: DetIdGPU = DetIdGPU(
        cablingMap.RawId[index],
        cablingMap.rocInDet[index],
        cablingMap.moduleId[index],
    )
    return detId


fn frameConversion(
    bpix: Bool, side: Int, layer: UInt32, rocIdInDetUnit: UInt32, local: Pixel
) -> Pixel:
    var slopeRow: Int32
    var slopeCol: Int32
    var rowOffset: Int32
    var colOffset: Int32

    if bpix:
        if (
            side == -1 and layer != 1
        ):  # -Z side: 4 non-flipped modules oriented like 'dddd', except Layer 1
            if rocIdInDetUnit < 8:
                slopeRow = 1
                slopeCol = -1
                rowOffset = 0
                colOffset = (
                    8 - rocIdInDetUnit.cast[DType.int32]()
                ) * PixelGPUDetails.numColsInRoc.cast[DType.int32]() - 1
            else:
                slopeRow = -1
                slopeCol = 1
                rowOffset = (
                    2 * PixelGPUDetails.numRowsInRoc.cast[DType.int32]() - 1
                )
                colOffset = (
                    rocIdInDetUnit.cast[DType.int32]() - 8
                ) * PixelGPUDetails.numColsInRoc.cast[DType.int32]()
        # if roc
        else:  # +Z side: 4 non-flipped modules oriented like 'pppp', but all 8 in layer1
            if rocIdInDetUnit < 8:
                slopeRow = -1
                slopeCol = 1
                rowOffset = (
                    2 * PixelGPUDetails.numRowsInRoc.cast[DType.int32]() - 1
                )
                colOffset = (
                    rocIdInDetUnit.cast[DType.int32]()
                    * PixelGPUDetails.numColsInRoc.cast[DType.int32]()
                )
            else:
                slopeRow = 1
                slopeCol = -1
                rowOffset = 0
                colOffset = (
                    16 - rocIdInDetUnit.cast[DType.int32]()
                ) * PixelGPUDetails.numColsInRoc.cast[DType.int32]() - 1
    else:  # fpix
        if side == -1:  # panel 1
            if rocIdInDetUnit < 8:
                slopeRow = 1
                slopeCol = -1
                rowOffset = 0
                colOffset = (
                    8 - rocIdInDetUnit.cast[DType.int32]()
                ) * PixelGPUDetails.numColsInRoc.cast[DType.int32]() - 1
            else:
                slopeRow = -1
                slopeCol = 1
                rowOffset = (
                    2 * PixelGPUDetails.numRowsInRoc.cast[DType.int32]() - 1
                )
                colOffset = (
                    rocIdInDetUnit.cast[DType.int32]() - 8
                ) * PixelGPUDetails.numColsInRoc.cast[DType.int32]()
        else:  # panel 2
            if rocIdInDetUnit < 8:
                slopeRow = 1
                slopeCol = -1
                rowOffset = 0
                colOffset = (
                    8 - rocIdInDetUnit.cast[DType.int32]()
                ) * PixelGPUDetails.numColsInRoc.cast[DType.int32]() - 1
            else:
                slopeRow = -1
                slopeCol = 1
                rowOffset = (
                    2 * PixelGPUDetails.numRowsInRoc.cast[DType.int32]() - 1
                )
                colOffset = (
                    rocIdInDetUnit.cast[DType.int32]() - 8
                ) * PixelGPUDetails.numColsInRoc.cast[DType.int32]()
    # side
    var gRow: UInt32 = (
        rowOffset.cast[DType.uint32]()
        + slopeRow.cast[DType.uint32]() * local.row
    )
    var gCol: UInt32 = (
        colOffset.cast[DType.uint32]()
        + slopeCol.cast[DType.uint32]() * local.col
    )
    # print("Inside frameConversion row:", gRow, " column:", gCol)
    var gl = Pixel(gRow, gCol)
    return gl
