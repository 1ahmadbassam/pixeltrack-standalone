from memory import memset

from MojoSerial.CondFormats.SiPixelGainForHLTonGPU import SiPixelGainForHLTonGPU
from MojoSerial.CUDADataFormats.GPUClusteringConstants import (
    GPUClusteringConstants,
)
from MojoSerial.MojoBridge.DTypes import Float


@nonmaterializable(NoneType)
struct GPUCalibPixel:
    alias InvId: UInt16 = 9999  # must be > MaxNumModules

    # valid for run2
    alias VCaltoElectronGain: Float = 47  # L2-4: 47 +- 4.7
    alias VCaltoElectronGain_L1: Float = 50  # L1:   49.6 +- 2.6
    alias VCaltoElectronOffset: Float = -60  # L2-4: -60 +- 130
    alias VCaltoElectronOffset_L1: Float = -670  # L1:   -670 +- 220

    @staticmethod
    fn calibDigis(
        isRun2: Bool,
        id: UnsafePointer[UInt16, mut=True],
        x: UnsafePointer[UInt16],
        y: UnsafePointer[UInt16],
        adc: UnsafePointer[UInt16, mut=True],
        ped: UnsafePointer[SiPixelGainForHLTonGPU],
        numElements: Int32,
        moduleStart: UnsafePointer[UInt32, mut=True],  # just to zero first
        nClustersInModule: UnsafePointer[UInt32, mut=True],  # just to zero them
        clusModuleStart: UnsafePointer[UInt32, mut=True],  # just to zero first
    ):
        clusModuleStart[0] = 0
        moduleStart[0] = 0
        memset(nClustersInModule, 0, Int(GPUClusteringConstants.MaxNumModules))
        for i in range(numElements):
            if Self.InvId == id[i]:
                continue
            var conversionFactor: Float = (
                Self.VCaltoElectronGain_L1 if id[i]
                < 96 else Self.VCaltoElectronGain
            ) if isRun2 else 1.0
            var offset: Float = (
                Self.VCaltoElectronOffset_L1 if id[i]
                < 96 else Self.VCaltoElectronOffset
            ) if isRun2 else 0.0
            var isDeadColumn = False
            var isNoisyColumn = False

            var row = x[i].cast[DType.int32]()
            var col = y[i].cast[DType.int32]()
            var ret = ped[].getPedAndGain(
                id[i].cast[DType.uint32](),
                col,
                row,
                isDeadColumn,
                isNoisyColumn,
            )
            ref pedestal = ret[0]
            ref gain = ret[1]
            if isDeadColumn or isNoisyColumn:
                id[i] = Self.InvId
                adc[i] = 0
                print("bad pixel at", i, "in", id[i])
            else:
                var vcal = adc[i].cast[DType.float32]() * gain - pedestal * gain
                adc[i] = max(
                    100, (vcal * conversionFactor + offset).cast[DType.uint16]()
                )
