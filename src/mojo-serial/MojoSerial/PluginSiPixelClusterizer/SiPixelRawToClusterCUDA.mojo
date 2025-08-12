from MojoSerial.CondFormats.SiPixelFedCablingMapGPUWrapper import (
    SiPixelFedCablingMapGPUWrapper,
)
from MojoSerial.CondFormats.SiPixelGainCalibrationForHLTGPU import (
    SiPixelGainCalibrationForHLTGPU,
)
from MojoSerial.CondFormats.SiPixelFedIds import SiPixelFedIds
from MojoSerial.CUDADataFormats.SiPixelDigisSoA import SiPixelDigisSoA
from MojoSerial.CUDADataFormats.SiPixelDigiErrorsSoA import SiPixelDigiErrorsSoA
from MojoSerial.CUDADataFormats.SiPixelClustersSoA import SiPixelClustersSoA
from MojoSerial.DataFormats.PixelErrors import PixelFormatterErrors
from MojoSerial.DataFormats.FEDRawDataCollection import FEDRawDataCollection
from MojoSerial.DataFormats.FEDRawData import FEDRawData
from MojoSerial.Framework.EDProducer import EDProducer
from MojoSerial.Framework.Event import Event
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.Framework.EDGetToken import EDGetTokenT
from MojoSerial.Framework.EDPutToken import EDPutTokenT
from MojoSerial.Framework.ProductRegistry import ProductRegistry
from MojoSerial.MojoBridge.DTypes import Typeable
from MojoSerial.PluginSiPixelClusterizer.SiPixelRawToClusterGPUKernel import (
    SiPixelRawToClusterGPUKernel,
    WordFedAppender,
)
from MojoSerial.PluginSiPixelClusterizer.ErrorChecker import ErrorChecker


struct SiPixelRawToClusterCUDA(Defaultable, EDProducer, Typeable):
    var _rawGetToken: EDGetTokenT[FEDRawDataCollection]
    var _digiPutToken: EDPutTokenT[SiPixelDigisSoA]
    var _digiErrorPutToken: EDPutTokenT[SiPixelDigiErrorsSoA]
    var _clusterPutToken: EDPutTokenT[SiPixelClustersSoA]

    var _gpuAlgo: SiPixelRawToClusterGPUKernel
    var _wordFedAppender: WordFedAppender
    var _errors: PixelFormatterErrors

    var _isRun2: Bool
    var _includeErrors: Bool
    var _useQuality: Bool

    @always_inline
    fn __init__(out self):
        self._rawGetToken = EDGetTokenT[FEDRawDataCollection]()
        self._digiPutToken = EDPutTokenT[SiPixelDigisSoA]()
        self._digiErrorPutToken = EDPutTokenT[SiPixelDigiErrorsSoA]()
        self._clusterPutToken = EDPutTokenT[SiPixelClustersSoA]()

        self._gpuAlgo = SiPixelRawToClusterGPUKernel()
        self._wordFedAppender = WordFedAppender()
        self._errors = PixelFormatterErrors()

        self._isRun2 = False
        self._includeErrors = False
        self._useQuality = False

    @always_inline
    fn __init__(out self, mut reg: ProductRegistry):
        try:
            self._rawGetToken = reg.consumes[FEDRawDataCollection]()
            self._digiPutToken = reg.produces[SiPixelDigisSoA]()
            self._clusterPutToken = reg.produces[SiPixelClustersSoA]()

            self._gpuAlgo = SiPixelRawToClusterGPUKernel()
            self._wordFedAppender = WordFedAppender()
            self._errors = PixelFormatterErrors()

            self._isRun2 = True
            self._includeErrors = True
            self._useQuality = True

            if self._includeErrors:
                self._digiErrorPutToken = reg.produces[SiPixelDigiErrorsSoA]()
            else:
                self._digiErrorPutToken = EDPutTokenT[SiPixelDigiErrorsSoA]()
        except e:
            print("Handled exception in SiPixelRawToClusterCUDA, ", e)
            return Self.__init__()

    fn produce(mut self, mut iEvent: Event, iSetup: EventSetup):
        try:
            if (
                iSetup.get[SiPixelFedCablingMapGPUWrapper]().hasQuality()
                != self._useQuality
            ):
                raise "UseQuality of the module (" + self._useQuality.__str__() + ") differs the one from SiPixelFedCablingMapGPUWrapper. Please fix your configuration."
            var gpuMap = iSetup.get[
                SiPixelFedCablingMapGPUWrapper
            ]().getCPUProduct()
            var gpuModulesToUnpack = iSetup.get[
                SiPixelFedCablingMapGPUWrapper
            ]().getModToUnpAll()
            ref hgains = iSetup.get[SiPixelGainCalibrationForHLTGPU]()
            var gpuGains = hgains.getCPUProduct()
            var _fedIds = iSetup.get[SiPixelFedIds]().fedIds()
            var buffers = iEvent.get[FEDRawDataCollection](self._rawGetToken)

            self._errors.clear()
            var wordCounterGPU: UInt32 = 0
            var fedCounter: UInt32 = 0
            var errorsInEvent = False
            var errorcheck = ErrorChecker()
            # In CPU algorithm this loop is part of PixelDataFormatter::interpretRawData()
            for fedId in _fedIds:
                if fedId == 40:
                    continue  # skip pilot blade data

                # for GPU
                # first 150 index stores the fedId and next 150 will store the
                # start index of word in that fed
                debug_assert(fedId >= 1200)
                fedCounter += 1

                # get event data for this fed
                var rawData: FEDRawData = buffers.FEDData(Int(fedId))

                # GPU specific
                var nWords: Int32 = (
                    rawData.size().cast[DType.int32]() / DType.uint64.sizeof()
                )
                if nWords == 0:
                    continue

                # check CRC bit
                var trailer = rawData.data().bitcast[UInt64]() + (nWords - 1)
                if not errorcheck.checkCRC(
                    errorsInEvent,
                    fedId.cast[DType.int32](),
                    trailer,
                    self._errors,
                ):
                    continue

                # check headers
                var header = rawData.data().bitcast[UInt64]()
                header -= 1
                var moreHeaders = True
                while moreHeaders:
                    header += 1
                    moreHeaders = errorcheck.checkHeader(
                        errorsInEvent,
                        fedId.cast[DType.int32](),
                        header,
                        self._errors,
                    )

                # check trailers
                trailer += 1
                var moreTrailers = True
                while moreTrailers:
                    trailer -= 1
                    moreTrailers = errorcheck.checkTrailer(
                        errorsInEvent,
                        fedId.cast[DType.int32](),
                        nWords.cast[DType.uint32](),
                        trailer,
                        self._errors,
                    )

                var bw = (header + 1).bitcast[UInt32]()
                var ew = trailer.bitcast[UInt32]()
                debug_assert((Int(ew) - Int(bw)) % 2 == 0)
                self._wordFedAppender.initializeWordFed(
                    fedId.cast[DType.int32](),
                    wordCounterGPU,
                    bw,
                    Int(ew) - Int(bw),
                )
                wordCounterGPU += Int(ew) - Int(bw)
            self._gpuAlgo.makeClusters(
                self._isRun2,
                gpuMap[],
                gpuModulesToUnpack,
                gpuGains[],
                self._wordFedAppender,
                self._errors^,
                wordCounterGPU,
                fedCounter,
                self._useQuality,
                self._includeErrors,
            )
            iEvent.put[SiPixelDigisSoA](
                self._digiPutToken, self._gpuAlgo.getResultsDigis()
            )
            iEvent.put[SiPixelClustersSoA](
                self._clusterPutToken, self._gpuAlgo.getResultsClusters()
            )
            if self._includeErrors:
                iEvent.put[SiPixelDigiErrorsSoA](
                    self._digiErrorPutToken, self._gpuAlgo.getErrors()
                )
            self._errors = PixelFormatterErrors()
        except e:
            print("Error during produce in SiPixelRawToClusterCUDA, ", e)

    fn endJob(mut self):
        pass

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SiPixelRawToClusterCUDA"
