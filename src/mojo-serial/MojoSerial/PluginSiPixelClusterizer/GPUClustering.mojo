from memory import UnsafePointer
from MojoSerial.Geometry.Phase1PixelTopology import Phase1PixelTopology
from MojoSerial.CUDACore.HistoContainer import HistoContainer
from MojoSerial.CUDACore.CUDACompat import CUDACompat
from MojoSerial.CUDADataFormats.GPUClusteringConstants import (
    GPUClusteringConstants,
)


@nonmaterializable(NoneType)
struct GPUClustering:
    @staticmethod
    fn countModules(
        id: UnsafePointer[UInt16],
        moduleStart: UnsafePointer[UInt32, mut=True],
        clusterId: UnsafePointer[Int32, mut=True],
        numElements: UInt32,
    ):
        for i in range(Int32(numElements)):
            clusterId[i] = i
            if id[i] == GPUClusteringConstants.InvId:
                continue
            var j = i - 1
            while j >= 0 and id[j] == GPUClusteringConstants.InvId:
                j -= 1
            if j < 0 or id[j] != id[i]:
                # boundary
                var loc = moduleStart[]
                moduleStart[] += GPUClusteringConstants.MaxNumModules
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
        # var firstModule: UInt32 = 0
        var endModule = moduleStart[0]
        for module in range(endModule):
            var firstPixel = moduleStart[module]
            var thisModuleId = id[firstPixel]
            # there is an assert here, need to check it
            # also there is a gpudebug thing
            var first = firstPixel
            msize = Int32(numElements)
            for i in range(first, numElements):
                if id[i] == GPUClusteringConstants.InvId:
                    continue
                if id[i] != thisModuleId:
                    CUDACompat.atomicMin(UnsafePointer(to=Int(msize)), Int(i))
                    break
            alias maxPixInModule: UInt32 = 4000
            alias nbins = Phase1PixelTopology.numRowsInModule + 2
            alias Hist = HistoContainer[
                DType.uint16,
                (nbins).cast[DType.uint32](),
                maxPixInModule,
                9,
                DType.uint16,
            ]
            var hist = Hist()

            for i in range(Hist.totbins()):
                hist.off[i] = 0
                # reput the assert, needed
                if Int32(msize) - Int32(firstPixel) > Int32(maxPixInModule):
                    print(
                        "too many pixels in module %d: %d > %d\n",
                        thisModuleId,
                        Int32(msize) - Int32(firstPixel),
                        maxPixInModule,
                    )
                    msize = Int32(maxPixInModule) + Int32(firstPixel)
                    # another assert here
                    # another debug line here

            for i in range(first, msize):
                if id[i] == GPUClusteringConstants.InvId:
                    continue
                hist.count(y[i])
                # those lines are in the original code, what to do with them? :
                # ifdef GPU_DEBUG
                # atomicAdd(&totGood, 1);
                # endif
                hist.finalize()
                # ifdef GPU_DEBUG
                # assert(hist.size() == totGood);
                # if (thisModuleId % 100 == 1)
                # printf("histo size %d\n", hist.size());
                # endif
            for i in range(first, msize):
                if id[i] == GPUClusteringConstants.InvId:
                    continue
                hist.fill(y[i], UInt16(i - firstPixel))

            var maxiter = hist.size()
            alias maxNeighbours = 10
            # assert((hist.size() / 1) <= maxiter);
            var nn = List[List[UInt16]](capacity=Int(maxiter))
            for i in range(maxiter):
                nn.append(List[UInt16](capacity=Int(maxNeighbours)))
            var nnn = List[UInt8](capacity=Int(maxiter))
            for k in range(maxiter):
                nnn[k] = 0
            # ifdef GPU_DEBUG
            # // look for anomalous high occupancy
            # uint32_t n40, n60;
            # n40 = n60 = 0;

            # for (uint32_t j = 0; j < Hist::nbins(); j++) {
            #   if (hist.size(j) > 60)
            #   atomicAdd(&n60, 1);
            #    if (hist.size(j) > 40)
            #    atomicAdd(&n40, 1);
            # }

            # if (n60 > 0)
            #    printf("columns with more than 60 px %d in %d\n", n60, thisModuleId);
            # else if (n40 > 0)
            #   printf("columns with more than 40 px %d in %d\n", n40, thisModuleId);
            # include "gpuClusteringConstants.h"
            # endif
            var j: UInt32 = 0
            var k: UInt32 = 0
            while j < hist.size():
                # assert(k < maxiter)
                var p = hist.begin() + j
                var i = UInt32(p[]) + firstPixel
                # assert(id[i] != InvId);
                # assert(id[i] == thisModuleId);
                var be: Int32 = Hist.bin(y[i] + 1).cast[DType.int32]()
                var e = hist.end(be.cast[DType.uint32]())
                p += 1
                # assert(0 == nnn[k])
                while p < e:
                    var m = UInt32(p[]) + firstPixel
                    # assert(m != i);
                    # assert(int(y[m]) - int(y[i]) >= 0);
                    # assert(int(y[m]) - int(y[i]) <= 1);
                    if abs((x[m]) - (x[i])) > 1:
                        continue
                    var l = nnn[k]
                    nnn[k] += 1
                    # assert(l < maxNeighbours)
                    nn[k][l] = p[]
                    p += 1
                j += 1
                k += 1
            var more: Bool = True
            var nloops: Int32 = 0
            while more:
                if nloops % 2 == 1:
                    var j: UInt32 = 0
                    var k: UInt32 = 0
                    while j < hist.size():
                        var p = hist.begin() + j
                        var i = UInt32(p[]) + firstPixel
                        var m = clusterId[i]
                        while m != clusterId[m]:
                            m = clusterId[m]
                        clusterId[i] = m
                        j += 1
                        k += 1
                else:
                    var more = False
                    var j: UInt32 = 0
                    var k: UInt32 = 0
                    while j < hist.size():
                        var p = hist.begin() + j
                        var i = UInt32(p[]) + firstPixel
                        for kk in range(nnn[k]):
                            var l = nn[k][kk]
                            var m = UInt32(l) + firstPixel
                            var old = CUDACompat.atomicMin(
                                UnsafePointer(to=Int(clusterId[m])),
                                Int(clusterId[i]),
                            )
                            if old != Int(clusterId[i]):
                                more = True
                            CUDACompat.atomicMin(
                                UnsafePointer(to=Int(clusterId[i])),
                                Int(old),
                            )
                        j += 1
                        k += 1
                nloops += 1

            var foundClusters: UInt32 = 0
            for i in range(first, msize):
                if id[i] == GPUClusteringConstants.InvId:
                    continue
                if clusterId[i] == i:
                    pass
                    var old = CUDACompat.atomicInc(
                        UnsafePointer(to=Int32(foundClusters)), 0xFFFFFFFF
                    )

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
        var charge = List[Int32](
            capacity=Int(GPUClusteringConstants.MaxNumClustersPerModules)
        )
        var ok = List[UInt8](
            capacity=Int(GPUClusteringConstants.MaxNumClustersPerModules)
        )
        var newclusId = List[UInt16](
            capacity=Int(GPUClusteringConstants.MaxNumClustersPerModules)
        )
        # var firstModule: UInt32 = 0
        var endModule = moduleStart[0]
        for module in range(endModule):
            var firstPixel = moduleStart[1 + module]
            var thisModuleId = id[firstPixel]
            # there is an assert here, need to check it
            var nclus = nClustersInModule[thisModuleId]
            if nclus == 0:
                continue
            var first = firstPixel
            if nclus > UInt32(GPUClusteringConstants.MaxNumClustersPerModules):
                print(
                    (
                        "Warning too many clusters in module %d in block %d: %d"
                        " > %d\n"
                    ),
                    thisModuleId,
                    0,
                    nclus,
                    GPUClusteringConstants.MaxNumClustersPerModules,
                )
                for i in range(first, numElements):
                    if id[i] == GPUClusteringConstants.InvId:
                        continue
                    if id[i] != thisModuleId:
                        break
                    if (
                        clusterId[i]
                        >= GPUClusteringConstants.MaxNumClustersPerModules
                    ):
                        id[i] = GPUClusteringConstants.InvId
                        clusterId[i] = GPUClusteringConstants.InvId.cast[
                            DType.int32
                        ]()
                nclus = GPUClusteringConstants.MaxNumClustersPerModules.cast[
                    DType.uint32
                ]()
            for i in range(nclus):
                charge[i] = 0

            for i in range(numElements):
                if id[i] == GPUClusteringConstants.InvId:
                    continue
                if id[i] != thisModuleId:
                    break
                CUDACompat.atomicAdd(
                    UnsafePointer(to=Int32(charge[clusterId[i]])),
                    Int(adc[i]),
                )
            var chargeCut = 2000 if thisModuleId < 96 else 4000
            for i in range(nclus):
                newclusId[i] = UInt16(charge[i] > chargeCut)
                ok[i] = UInt8(charge[i] > chargeCut)
