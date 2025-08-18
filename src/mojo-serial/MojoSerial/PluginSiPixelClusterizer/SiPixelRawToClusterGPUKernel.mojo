from memory import OwnedPointer, memcpy, memset

from MojoSerial.CondFormats.SiPixelFedCablingMapGPU import (
    SiPixelFedCablingMapGPU,
)
from MojoSerial.CondFormats.SiPixelGainForHLTonGPU import SiPixelGainForHLTonGPU
from MojoSerial.CondFormats.PixelGPUDetails import PixelGPUDetails
from MojoSerial.CUDACore.SimpleVector import SimpleVector
from MojoSerial.CUDACore.PrefixScan import blockPrefixScan
from MojoSerial.CUDADataFormats.GPUClusteringConstants import (
    GPUClusteringConstants,
)
from MojoSerial.CUDADataFormats.SiPixelDigisSoA import SiPixelDigisSoA
from MojoSerial.CUDADataFormats.SiPixelDigiErrorsSoA import SiPixelDigiErrorsSoA
from MojoSerial.CUDADataFormats.SiPixelClustersSoA import SiPixelClustersSoA
from MojoSerial.DataFormats.PixelErrors import (
    PixelErrorCompact,
    PixelFormatterErrors,
)
from MojoSerial.MojoBridge.Timer import TimerManager
from MojoSerial.PluginSiPixelClusterizer.GPUClustering import GPUClustering
from MojoSerial.PluginSiPixelClusterizer.GPUCalibPixel import GPUCalibPixel
from MojoSerial.MojoBridge.DTypes import UChar, Double, Float, Typeable


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
@register_passable("trivial")
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
        var row_w: UInt32,
        var column_w: UInt32,
        var time_w: UInt32,
        var adc_w: UInt32,
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
fn pack(var row: UInt32, var col: UInt32, var adc: UInt32) -> UInt32:
    alias thePacking = packing()
    adc = min(adc, thePacking.max_adc)

    return (
        (row << thePacking.row_shift)
        | (col << thePacking.column_shift)
        | (adc << thePacking.adc_shift)
    )


@always_inline
fn pixelToChannel(row: Int32, col: Int32) -> UInt32:
    alias thePacking = packing()
    return ((row << thePacking.column_width.cast[DType.int32]()) | col).cast[
        DType.uint32
    ]()


struct WordFedAppender(Defaultable, Movable, Typeable):
    var _word: OwnedPointer[List[UInt32]]
    var _fedId: OwnedPointer[List[UChar]]

    @always_inline
    fn __init__(out self):
        self._word = OwnedPointer(
            List[UInt32](length=Int(PixelGPUDetails.MAX_FED_WORDS), fill=0)
        )
        self._fedId = OwnedPointer(
            List[UChar](length=Int(PixelGPUDetails.MAX_FED_WORDS), fill=0)
        )

    fn initializeWordFed(
        self,
        var fedId: Int32,
        var wordCounterGPU: UInt32,
        src: UnsafePointer[UInt32],
        length: UInt32,
    ):
        memcpy(self._word[].unsafe_ptr() + wordCounterGPU, src, Int(length))
        # fedId is actually a byte wide, so c++ and mojo memset counts match up
        memset(
            self._fedId[].unsafe_ptr() + wordCounterGPU / 2,
            (fedId - 1200).cast[DType.uint8](),
            Int(length / 2),
        )

    @always_inline
    fn word(self) -> UnsafePointer[UInt32, mut=False]:
        return self._word[].unsafe_ptr()

    @always_inline
    fn fedId(self) -> UnsafePointer[UChar, mut=False]:
        return self._fedId[].unsafe_ptr()

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "WordFedAppender"


struct SiPixelRawToClusterGPUKernel(Defaultable, Typeable):
    var digis_d: SiPixelDigisSoA
    var clusters_d: SiPixelClustersSoA
    var digiErrors_d: SiPixelDigiErrorsSoA

    @always_inline
    fn __init__(out self):
        self.digis_d = SiPixelDigisSoA()
        self.clusters_d = SiPixelClustersSoA()
        self.digiErrors_d = SiPixelDigiErrorsSoA()

    fn getResultsDigis(mut self) -> SiPixelDigisSoA:
        var ret = self.digis_d^
        self.digis_d = SiPixelDigisSoA()
        return ret^

    fn getResultsClusters(mut self) -> SiPixelClustersSoA:
        var ret = self.clusters_d^
        self.clusters_d = SiPixelClustersSoA()
        return ret^

    fn getErrors(mut self) -> SiPixelDigiErrorsSoA:
        var ret = self.digiErrors_d^
        self.digiErrors_d = SiPixelDigiErrorsSoA()
        return ret^

    fn makeClusters(
        mut self,
        isRun2: Bool,
        cablingMap: UnsafePointer[SiPixelFedCablingMapGPU],
        modToUnp: UnsafePointer[UChar],
        gains: UnsafePointer[SiPixelGainForHLTonGPU],
        ref wordFed: WordFedAppender,
        var errors: PixelFormatterErrors,
        wordCounter: UInt32,
        fedCounter: UInt32,
        var useQualityInfo: Bool,
        var includeErrors: Bool,
        var debug: Bool,
        ref tm: TimerManager = TimerManager()
    ):
        if debug:
            print(
                "decoding",
                wordCounter,
                "digis. Max is",
                PixelGPUDetails.MAX_FED_WORDS,
            )

        self.digis_d = SiPixelDigisSoA(PixelGPUDetails.MAX_FED_WORDS)
        if includeErrors:
            self.digiErrors_d = SiPixelDigiErrorsSoA(
                PixelGPUDetails.MAX_FED_WORDS, errors^
            )
        self.clusters_d = SiPixelClustersSoA(
            GPUClusteringConstants.MaxNumModules
        )

        if wordCounter:  # protect in case of empty event....
            debug_assert(wordCounter % 2 == 0)
            # Launch rawToDigi kernel
            tm.start("RawToDigi_kernel")
            RawToDigi_kernel(
                cablingMap,
                modToUnp,
                wordCounter,
                wordFed.word(),
                wordFed.fedId(),
                self.digis_d.xx(),
                self.digis_d.yy(),
                self.digis_d.adc(),
                self.digis_d.pdigi(),
                self.digis_d.rawIdArr(),
                self.digis_d.moduleInd(),
                self.digiErrors_d.error(),
                useQualityInfo,
                includeErrors,
                debug,
            )
            tm.stop()
        # End of Raw2Digi and passing data for clustering

        # clusterizer
        @parameter
        if True:
            tm.start("GPUCalibPixel.calibDigis")
            GPUCalibPixel.calibDigis(
                isRun2,
                self.digis_d.moduleInd(),
                self.digis_d.c_xx(),
                self.digis_d.c_yy(),
                self.digis_d.adc(),
                gains,
                wordCounter.cast[DType.int32](),
                self.clusters_d.moduleStart(),
                self.clusters_d.clusInModule(),
                self.clusters_d.clusModuleStart(),
            )
            tm.stop()

            tm.start("GPUCalibPixel.countModules")
            GPUClustering.countModules(
                self.digis_d.c_moduleInd(),
                self.clusters_d.moduleStart(),
                self.digis_d.clus(),
                wordCounter.cast[DType.int32](),
            )
            tm.stop()

            # read the number of modules into a data member, used by getProduct())
            self.digis_d.setNModulesDigis(
                self.clusters_d.moduleStart()[0], wordCounter
            )

            tm.start("GPUClustering.findClus")
            GPUClustering.findClus(
                self.digis_d.c_moduleInd(),
                self.digis_d.c_xx(),
                self.digis_d.c_yy(),
                self.clusters_d.c_moduleStart(),
                self.clusters_d.clusInModule(),
                self.clusters_d.moduleId(),
                self.digis_d.clus(),
                wordCounter.cast[DType.int32](),
            )
            tm.stop()

            # apply charge cut
            tm.start("GPUClustering.clusterChargeCut")
            GPUClustering.clusterChargeCut(
                self.digis_d.moduleInd(),
                self.digis_d.c_adc(),
                self.clusters_d.c_moduleStart(),
                self.clusters_d.clusInModule(),
                self.clusters_d.c_moduleId(),
                self.digis_d.clus(),
                wordCounter,
            )
            tm.stop()

            # count the module start indices already here (instead of
            # rechits) so that the number of clusters/hits can be made
            # available in the rechit producer without additional points of
            # synchronization/ExternalWork

            # MUST be ONE block
            fillHitsModuleStart(
                self.clusters_d.c_clusInModule(),
                self.clusters_d.clusModuleStart(),
            )

            # last element holds the number of all clusters
            self.clusters_d.setNClusters(
                self.clusters_d.clusModuleStart()[
                    GPUClusteringConstants.MaxNumModules
                ]
            )

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelRawToClusterGPUKernel"


@nonmaterializable(NoneType)
struct ADCThreshold:
    # default Pixel threshold in electrons
    alias thePixelThreshold: Int32 = 1000
    # seed threshold in electrons not used in our algo
    alias theSeedThreshold: Int32 = 1000
    # cluster threshold in electron
    alias theClusterThreshold: Float = 4000
    # adc to electron conversion factor
    alias ConversionFactor: Int32 = 65
    # the maximum adc count for stack layer
    alias _theStackADC: Int32 = 255
    # the index of the fits stack layer
    alias _theFirstStack: Int32 = 5
    # ADC to electron conversion
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
    cablingMap: UnsafePointer[SiPixelFedCablingMapGPU],
    var fed: UInt8,
    var link: UInt32,
    var roc: UInt32,
) -> DetIdGPU:
    debug_assert(link > 0)
    var index = (
        fed.cast[DType.uint32]()
        * PixelGPUDetails.MAX_LINK
        * PixelGPUDetails.MAX_ROC
        + (link - 1) * PixelGPUDetails.MAX_ROC
        + roc
    )
    var detId = DetIdGPU(
        cablingMap[].RawId[index],
        cablingMap[].rocInDet[index],
        cablingMap[].moduleId[index],
    )
    return detId


fn frameConversion(
    bpix: Bool, side: Int32, layer: UInt32, rocIdInDetUnit: UInt32, local: Pixel
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
                    rocIdInDetUnit * PixelGPUDetails.numColsInRoc
                ).cast[DType.int32]()
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


fn conversionError(
    var fedId: UInt8, var status: UInt8, var debug: Bool
) -> UInt8:
    var errorType: UInt8 = 0

    if status == 1:
        if debug:
            print(
                "Error in Fed:",
                fedId.__str__() + ", invalid channel Id (errorType = 35)",
            )
        errorType = 35
    elif status == 2:
        if debug:
            print(
                "Error in Fed:",
                fedId.__str__() + ", invalid ROC Id (errorType = 36)",
            )
        errorType = 36
    elif status == 3:
        if debug:
            print(
                "Error in Fed:",
                fedId.__str__() + ", invalid dcol/pixel value (errorType = 37)",
            )
        errorType = 37
    elif status == 4:
        if debug:
            print(
                "Error in Fed:",
                fedId.__str__()
                + ", dcol/pixel read out of order (errorType = 38)",
            )
        errorType = 38
    else:
        if debug:
            print("Cabling check returned unexpected result, status =", status)
    return errorType


fn rocRowColIsValid(var rocRow: UInt32, var rocCol: UInt32) -> Bool:
    alias numRowsInRoc: UInt32 = 80
    alias numColsInRoc: UInt32 = 52

    # row and column in ROC representation
    return (rocRow < numRowsInRoc) & (rocCol < numColsInRoc)


fn dcolIsValid(var dcol: UInt32, var pxid: UInt32) -> Bool:
    return (dcol < 26) and (pxid >= 2) and (pxid < 162)


fn checkROC(
    var errorWord: UInt32,
    var fedId: UInt8,
    var link: UInt32,
    cablingMap: UnsafePointer[SiPixelFedCablingMapGPU],
    debug: Bool = False,
) -> UInt8:
    var errorType = (
        (errorWord >> PixelGPUDetails.ROC_shift) & PixelGPUDetails.ERROR_mask
    ).cast[DType.uint8]()
    if errorType < 25:
        return 0
    var errorFound = False

    if errorType == 25:
        errorFound = True
        debug_assert(link > 0)
        var index = (
            fedId.cast[DType.uint32]()
            * PixelGPUDetails.MAX_LINK
            * PixelGPUDetails.MAX_ROC
            + (link - 1) * PixelGPUDetails.MAX_ROC
            + 1
        )
        if index > 1 and index.cast[DType.uint32]() <= cablingMap[].size:
            if not (
                link == cablingMap[].link[index]
                and cablingMap[].roc[index] == 1
            ):
                errorFound = False
        if debug and errorFound:
            print("Invalid ROC = 25 found (errorType = 25)")
    elif errorType == 26:
        if debug:
            print("Gap word found (errorType = 26)")
        errorFound = True
    elif errorType == 27:
        if debug:
            print("Dummy word found (errorType = 27)")
        errorFound = True
    elif errorType == 28:
        if debug:
            print("Error fifo nearly full (errorType = 28)")
        errorFound = True
    elif errorType == 29:
        if debug:
            print("Timeout on a channel (errorType = 29)")
        if (
            errorWord >> PixelGPUDetails.OMIT_ERR_shift
        ) & PixelGPUDetails.OMIT_ERR_mask:
            if debug:
                print("...first errorType=29 error, this gets masked out")
        errorFound = True
    elif errorType == 30:
        if debug:
            print("TBM error trailer (errorType = 30)")
        alias StateMatch_bits = 4
        alias StateMatch_shift = 8
        alias StateMatch_mask: UInt32 = ~(~UInt32(0) << StateMatch_bits)
        var StateMatch: Int32 = (
            (errorWord >> StateMatch_shift) & StateMatch_mask
        ).cast[DType.int32]()
        if StateMatch != 1 and StateMatch != 8:
            if debug:
                print(
                    "FED error 30 with unexpected State Bits (errorType = 30)\n"
                )
        if StateMatch == 1:
            errorType = 40  # 1=Overflow -> 40, 8=number of ROCs -> 30
        errorFound = True
    elif errorType == 31:
        if debug:
            print("Event number error (errorType = 31)")
        errorFound = True
    return errorType if errorFound else 0


fn getErrRawID(
    var fedId: UInt8,
    var errWord: UInt32,
    var errorType: UInt32,
    cablingMap: UnsafePointer[SiPixelFedCablingMapGPU],
    debug: Bool = False,
) -> UInt32:
    var rID: UInt32 = 0xFFFFFFFF

    if (
        errorType == 25
        or errorType == 30
        or errorType == 31
        or errorType == 36
        or errorType == 40
    ):
        var roc: UInt32 = 1
        var link = (
            errWord >> PixelGPUDetails.LINK_shift
        ) & PixelGPUDetails.LINK_mask
        var rID_temp = getRawId(cablingMap, fedId, link, roc).RawId
        if rID_temp != 9999:
            rID = rID_temp
    elif errorType == 29:
        var chanNmbr: Int32
        alias DB0_shift = 0
        alias DB1_shift = DB0_shift + 1
        alias DB2_shift = DB1_shift + 1
        alias DB3_shift = DB2_shift + 1
        alias DB4_shift = DB3_shift + 1
        alias DataBit_mask = ~(~UInt32(0) << 1)

        var CH1: Int32 = ((errWord >> DB0_shift) & DataBit_mask).cast[
            DType.int32
        ]()
        var CH2: Int32 = ((errWord >> DB1_shift) & DataBit_mask).cast[
            DType.int32
        ]()
        var CH3: Int32 = ((errWord >> DB2_shift) & DataBit_mask).cast[
            DType.int32
        ]()
        var CH4: Int32 = ((errWord >> DB3_shift) & DataBit_mask).cast[
            DType.int32
        ]()
        var CH5: Int32 = ((errWord >> DB4_shift) & DataBit_mask).cast[
            DType.int32
        ]()
        alias BLOCK_bits = 3
        alias BLOCK_shift = 8
        alias BLOCK_mask = ~(~UInt32(0) << BLOCK_bits)
        var BLOCK: Int32 = ((errWord >> BLOCK_shift) & BLOCK_mask).cast[
            DType.int32
        ]()
        var localCH: Int32 = 1 * CH1 + 2 * CH2 + 3 * CH3 + 4 * CH4 + 5 * CH5
        if BLOCK % 2 == 0:
            chanNmbr = (BLOCK / 2) * 9 + localCH
        else:
            chanNmbr = ((BLOCK - 1) / 2) * 9 + 4 + localCH
        # inverse signifies unexpected result
        if (chanNmbr >= 1) and (chanNmbr <= 36):
            var roc: UInt32 = 1
            var link: UInt32 = chanNmbr.cast[DType.uint32]()
            var rID_temp = getRawId(cablingMap, fedId, link, roc).RawId
            if rID_temp != 9999:
                rID = rID_temp
    elif errorType == 37 or errorType == 38:
        var roc = (
            errWord >> PixelGPUDetails.ROC_shift
        ) & PixelGPUDetails.ROC_mask
        var link = (
            errWord >> PixelGPUDetails.LINK_shift
        ) & PixelGPUDetails.LINK_mask
        var rID_temp = getRawId(cablingMap, fedId, link, roc).RawId
        if rID_temp != 9999:
            rID = rID_temp
    return rID


fn RawToDigi_kernel(
    cablingMap: UnsafePointer[SiPixelFedCablingMapGPU],
    modToUnp: UnsafePointer[UChar],
    wordCounter: UInt32,
    word: UnsafePointer[UInt32],
    fedIds: UnsafePointer[UInt8],
    xx: UnsafePointer[UInt16, mut=True],
    yy: UnsafePointer[UInt16, mut=True],
    adc: UnsafePointer[UInt16, mut=True],
    pdigi: UnsafePointer[UInt32, mut=True],
    rawIdArr: UnsafePointer[UInt32, mut=True],
    moduleId: UnsafePointer[UInt16, mut=True],
    err: UnsafePointer[
        SimpleVector[PixelErrorCompact, PixelErrorCompact.dtype()], mut=True
    ],
    useQualityInfo: Bool,
    includeErrors: Bool,
    debug: Bool = False,
):
    """Kernel to perform Raw to Digi conversion."""
    for gindex in range(wordCounter):
        xx[gindex] = 0
        yy[gindex] = 0
        adc[gindex] = 0
        var skipROC = False

        var fedId = fedIds[gindex / 2]  # +1200

        # initialize (too many continue below)
        pdigi[gindex] = 0
        rawIdArr[gindex] = 0
        moduleId[gindex] = 9999

        var ww = word[gindex]
        if ww == 0:
            # 0 is an indicator of a noise/dead channel, skip these pixels during clusterization
            continue

        var link = getLink(ww)  # Extract link
        var roc = getRoc(ww)  # Extract Roc in link
        var detId = getRawId(cablingMap, fedId, link, roc)

        var errorType = checkROC(ww, fedId, link, cablingMap, debug)
        skipROC = False if roc < PixelGPUDetails.maxROCIndex else Bool(
            errorType != 0
        )
        if includeErrors and skipROC:
            var rID = getErrRawID(
                fedId, ww, errorType.cast[DType.uint32](), cablingMap, debug
            )
            _ = err[].push_back(PixelErrorCompact(rID, ww, errorType, fedId))
            continue
        var rawId = detId.RawId
        var rocIdInDetUnit = detId.rocInDet
        var barrel = isBarrel(rawId)

        debug_assert(link > 0)
        var index = (
            fedId.cast[DType.uint32]()
            * PixelGPUDetails.MAX_LINK
            * PixelGPUDetails.MAX_ROC
            + (link - 1) * PixelGPUDetails.MAX_ROC
            + roc
        )
        if useQualityInfo:
            skipROC = cablingMap[].badRocs[index].cast[DType.bool]()
            if skipROC:
                continue

        skipROC = modToUnp[index].cast[DType.bool]()
        if skipROC:
            continue

        var layer: UInt32  # ladder =0
        var side: Int32  # disk = 0, blade = 0
        var panel: Int32 = 0
        var module: Int32 = 0

        if barrel:
            layer = (
                rawId >> PixelGPUDetails.layerStartBit
            ) & PixelGPUDetails.layerMask
            module = (
                (rawId >> PixelGPUDetails.moduleStartBit)
                & PixelGPUDetails.moduleMask
            ).cast[DType.int32]()
            side = -1 if module < 5 else 1
        else:
            # endcap ids
            layer = 0
            panel = (
                (rawId >> PixelGPUDetails.panelStartBit)
                & PixelGPUDetails.panelMask
            ).cast[DType.int32]()
            side = -1 if panel == 1 else 1

        # ***special case of layer to 1 be handled here
        var localPix: Pixel
        if layer == 1:
            var col = (
                ww >> PixelGPUDetails.COL_shift
            ) & PixelGPUDetails.COL_mask
            var row = (
                ww >> PixelGPUDetails.ROW_shift
            ) & PixelGPUDetails.ROW_mask
            localPix = Pixel(row, col)
            if includeErrors:
                if not rocRowColIsValid(row, col):
                    var error = conversionError(
                        fedId, 3, debug
                    )  # use the device function and fill the arrays
                    _ = err[].push_back(
                        PixelErrorCompact(rawId, ww, error, fedId)
                    )
                    if debug:
                        print("BPIX1  Error status:", error)
                    continue
        else:
            # ***conversion rules for dcol and pxid
            var dcol = (
                ww >> PixelGPUDetails.DCOL_shift
            ) & PixelGPUDetails.DCOL_mask
            var pxid = (
                ww >> PixelGPUDetails.PXID_shift
            ) & PixelGPUDetails.PXID_mask
            var row = PixelGPUDetails.numRowsInRoc - pxid // 2
            var col = dcol * 2 + pxid % 2
            localPix = Pixel(row, col)
            if includeErrors and not dcolIsValid(dcol, pxid):
                var error = conversionError(fedId, 3, debug)
                _ = err[].push_back(PixelErrorCompact(rawId, ww, error, fedId))

                if debug:
                    print("Error status:", error, dcol, pxid, fedId, roc)
                continue
        var globalPix = frameConversion(
            barrel, side, layer, rocIdInDetUnit, localPix
        )
        xx[gindex] = globalPix.row.cast[
            DType.uint16
        ]()  # origin shifting by 1 0-159
        yy[gindex] = globalPix.col.cast[
            DType.uint16
        ]()  # origin shifting by 1 0-415
        adc[gindex] = getADC(ww).cast[DType.uint16]()
        pdigi[gindex] = pack(
            globalPix.row, globalPix.col, adc[gindex].cast[DType.uint32]()
        )
        moduleId[gindex] = detId.moduleId.cast[DType.uint16]()
        rawIdArr[gindex] = rawId


fn fillHitsModuleStart(
    cluStart: UnsafePointer[UInt32],
    moduleStart: UnsafePointer[UInt32, mut=True],
    debug: Bool = False,
):
    debug_assert(
        GPUClusteringConstants.MaxNumModules < 2048
    )  # easy to extend at least till 32*1024

    for i in range(0, GPUClusteringConstants.MaxNumModules):
        moduleStart[i + 1] = min(
            GPUClusteringConstants.maxHitsInModule(), cluStart[i]
        )

    blockPrefixScan(moduleStart + 1, moduleStart + 1, 1024)
    blockPrefixScan(
        moduleStart + 1025,
        moduleStart + 1025,
        GPUClusteringConstants.MaxNumModules - 1024,
    )

    for i in range(1025, GPUClusteringConstants.MaxNumModules + 1):
        moduleStart[i] += moduleStart[1024]

    if debug:
        debug_assert(moduleStart[0] == 0)
        var c0 = min(GPUClusteringConstants.maxHitsInModule(), cluStart[0])
        debug_assert(c0 == moduleStart[1])
        debug_assert(moduleStart[1024] >= moduleStart[1023])
        debug_assert(moduleStart[1025] >= moduleStart[1024])
        debug_assert(
            moduleStart[GPUClusteringConstants.MaxNumModules]
            >= moduleStart[1025]
        )

        for i in range(1, GPUClusteringConstants.MaxNumModules + 1):
            debug_assert(moduleStart[i] >= moduleStart[i - i])
            # [BPX1, BPX2, BPX3, BPX4,  FP1,  FP2,  FP3,  FN1,  FN2,  FN3, LAST_VALID]
            # [   0,   96,  320,  672, 1184, 1296, 1408, 1520, 1632, 1744,       1856]
            if (
                i == 96
                or i == 1184
                or i == 1744
                or i == Int(GPUClusteringConstants.MaxNumModules)
            ):
                print("moduleStart", i, moduleStart[i])
    alias MAX_HITS: UInt32 = GPUClusteringConstants.MaxNumClusters

    for i in range(0, GPUClusteringConstants.MaxNumModules + 1):
        if moduleStart[i] > GPUClusteringConstants.MaxNumClusters:
            moduleStart[i] = MAX_HITS
