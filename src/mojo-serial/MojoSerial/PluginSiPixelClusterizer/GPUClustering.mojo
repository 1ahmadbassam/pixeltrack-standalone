from memory import UnsafePointer
from MojoSerial.Geometry.Phase1PixelTopology import Phase1PixelTopology
from MojoSerial.CUDACore.HistoContainer import HistoContainer
from MojoSerial.CUDACore.CUDACompat import CUDACompat
from MojoSerial.CUDADataFormats.GPUClusteringConstants import (
    GPUClusteringConstants,
)

@nonmaterializable(NoneType)
struct GPUClustering:
    alias InvId: UInt16 = 9999 

    @staticmethod
    fn countModules(
        id: UnsafePointer[UInt16],
        moduleStart: UnsafePointer[UInt32, mut=True],
        clusterId: UnsafePointer[Int32, mut=True],
        numElements: UInt32,
    ):
        for i in range(Int32(numElements)):
            clusterId[i] = i
            if id[i] == Self.InvId:
                continue
            var j = i - 1
            while (j >= 0 and id[j] == Self.InvId):
                j -= 1
            if j < 0 or id[j] != id[i]:
                var loc = CUDACompat.atomicInc(moduleStart, GPUClusteringConstants.MaxNumModules)
                moduleStart[loc + 1] += 1

    @staticmethod
    fn findClus(
        id: UnsafePointer[UInt16],
        x: UnsafePointer[UInt16],
        y: UnsafePointer[UInt16],
        moduleStart: UnsafePointer[UInt32],
        nClustersInModule: UnsafePointer[UInt32, mut=True],
        moduleId: UnsafePointer[UInt32, mut=True],
        clusterId: UnsafePointer[Int32, mut=True],
        numElements: UInt32,
    ):
        var msize: Int32 = 0
        #var firstModule: UInt32 = 0
        var endModule = moduleStart[0]
        for module in range(endModule):
            var firstPixel = moduleStart[module]
            var thisModuleId = id[firstPixel]
            #there is an assert here, need to check it
            #also there is a gpudebug thing
            var first = firstPixel
            msize = Int32(numElements)
            for i in range(first, numElements):
                if id[i] == Self.InvId:
                   continue
                if id[i] != thisModuleId:
                    CUDACompat.atomicMin(UnsafePointer(to = Int(msize)), Int(i))
                    break
            alias maxPixInModule: UInt32 = 4000
            alias nbins = Phase1PixelTopology.numRowsInModule + 2
            alias Hist = HistoContainer[DType.uint16, (nbins).cast[DType.uint32](), maxPixInModule, 9, DType.uint16] 
            var hist = Hist()

            for i in range(Hist.totbins()):
                hist.off[i] = 0
                #reput the assert, needed
                if (Int32(msize) - Int32(firstPixel) > Int32(maxPixInModule)):
                    print("too many pixels in module %d: %d > %d\n", thisModuleId, Int32(msize) - Int32(firstPixel), maxPixInModule)
                    msize = Int32(maxPixInModule) + Int32(firstPixel)
                    #another assert here
                    #another debug line here
            
            for i in range(first, msize):
                if (id[i] == Self.InvId):
                    continue
                hist.count(y[i])
                #those lines are in the original code, what to do with them? :
                #ifdef GPU_DEBUG
                        #atomicAdd(&totGood, 1);
                #endif
                hist.finalize()
                #ifdef GPU_DEBUG
                    #assert(hist.size() == totGood);
                    #if (thisModuleId % 100 == 1)
                        #printf("histo size %d\n", hist.size());
                #endif
            for i in range(first, msize):
                if (id[i] == Self.InvId):
                    continue
                hist.fill(y[i], UInt16(i - firstPixel))

                var maxiter = hist.size()
                alias maxNeighbors = 10
                # assert((hist.size() / 1) <= maxiter);
                
                




        

    @staticmethod
    fn clusterChargeCut(
        id: UnsafePointer[UInt16],
        adc: UnsafePointer[UInt16],
        moduleStart: UnsafePointer[UInt32],
        nClustersInModule: UnsafePointer[UInt32, mut=True],
        moduleId: UnsafePointer[UInt32],
        clusterId: UnsafePointer[Int32, mut=True],
        numElements: UInt32,
    ):
        pass

    # TODO: Finish this stub
