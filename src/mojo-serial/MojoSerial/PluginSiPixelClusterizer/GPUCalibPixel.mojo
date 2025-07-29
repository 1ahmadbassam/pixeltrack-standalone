from memory import UnsafePointer

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
        ref ped: SiPixelGainForHLTonGPU,
        numElements: Int,
        moduleStart: UnsafePointer[UInt32, mut=True],
        nClustersInModule: UnsafePointer[UInt32, mut=True],
        clusModuleStart: UnsafePointer[UInt32, mut=True],
    ):
        clusModuleStart[0] = 0
        moduleStart[0] = 0
        for i in range(GPUClusteringConstants.MaxNumModules):
            nClustersInModule[i] = 0
        # TODO: Finish this class
