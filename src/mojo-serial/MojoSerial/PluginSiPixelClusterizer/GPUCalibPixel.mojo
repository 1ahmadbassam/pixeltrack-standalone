from MojoSerial.CondFormats.SiPixelGainForHLTonGPU import *
from MojoSerial.CUDADataFormats.GPUClusteringConstants import GPUClustering

struct GPUCalibPixel:
    alias InvId: UInt16 = 9999
    alias VCaltoElectronGain: Float = 47         # L2-4: 47 +- 4.7
    alias VCaltoElectronGain_L1: Float = 50      # L1:   49.6 +- 2.6
    alias VCaltoElectronOffset: Float = -60      # L2-4: -60 +- 130
    alias VCaltoElectronOffset_L1: Float = -670  # L1:   -670 +- 220

    def calibDigis(self, isRun2: Bool, id: UnsafePointer[UInt16, mut = True], x: UnsafePointer[UInt16, mut = False],
                   y: UnsafePointer[UInt16, mut = False], adc: UnsafePointer[UInt16, mut = True],
                   ped: UnsafePointer[SiPixelGainForHLTonGPU, mut = False], numElements: Int, moduleStart: UnsafePointer[UInt32, mut = True],
                   nClustersInModule: UnsafePointer[UInt32, mut = True], clusModuleStart: UnsafePointer[UInt32, mut = True]):

        var first = 0
        if first == 0:
            clusModuleStart[0] = 0 
            moduleStart[0] = 0
        for i in range(first, GPUClustering.MaxNumModules):
            nClustersInModule[i] = 0
        #for i in range(first,  ) to be continued...
         