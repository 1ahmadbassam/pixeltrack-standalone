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
        id: UnsafePointer[UInt16],  # module id of each pixel
        x: UnsafePointer[UInt16],  # local coordinates of each pixel
        y: UnsafePointer[UInt16],  #
        moduleStart: UnsafePointer[
            UInt32
        ],  # index of the first pixel of each module
        nClustersInModule: UnsafePointer[
            UInt32, mut=True
        ],  # output: number of clusters found in each module
        moduleId: UnsafePointer[
            UInt32, mut=True
        ],  # output: module id of each module
        clusterId: UnsafePointer[
            Int32, mut=True
        ],  # output: cluster id of each pixel
        numElements: UInt32,
    ):
        var msize: UInt32

        var endModule = moduleStart[0]
        for module in range(endModule):
            var firstPixel = moduleStart[module + 1]
            var thisModuleId = id[firstPixel]
            debug_assert(
                thisModuleId.cast[DType.uint32]()
                < GPUClusteringConstants.MaxNumModules
            )

            var first = firstPixel

            # find the index of the first pixel not belonging to this module (or invalid)
            msize = numElements

            # skip threads not associated to an existing pixel
            for i in range(first, numElements):
                if id[i] == GPUClusteringConstants.InvId:  # skip invalid pixels
                    continue
                if (
                    id[i] != thisModuleId
                ):  # find the first pixel in a different module
                    msize = min(msize, i)
                    break

            # init hist  (ymax=416 < 512 : 9bits)
            alias maxPixInModule: UInt32 = 4000
            alias nbins = Phase1PixelTopology.numRowsInModule.cast[
                DType.uint32
            ]() + 2  # 2+2
            alias Hist = HistoContainer[
                DType.uint16,
                nbins,
                maxPixInModule,
                9,
                DType.uint16,
            ]
            var hist = Hist()

            @parameter
            for j in range(Hist.totbins()):
                hist.off[j] = 0

            debug_assert(
                (msize == numElements)
                or ((msize < numElements) and (id[msize] != thisModuleId))
            )

            if msize - firstPixel > maxPixInModule:
                print(
                    "too many pixels in module ",
                    thisModuleId,
                    ": ",
                    msize - firstPixel,
                    " > ",
                    maxPixInModule,
                    sep="",
                )
                msize = maxPixInModule + firstPixel

            debug_assert(msize - firstPixel <= maxPixInModule)

            for i in range(first, msize):
                if id[i] == GPUClusteringConstants.InvId:  # skip invalid pixels
                    continue
                hist.count(y[i])

            hist.finalize()

            for i in range(first, msize):
                if id[i] == GPUClusteringConstants.InvId:  # skip invalid pixels
                    continue
                hist.fill(y[i], (i - firstPixel).cast[DType.uint16]())

            var maxiter = hist.size()
            # allocate space for duplicate pixels: a pixel can appear more than once with different charge in the same event
            alias maxNeighbours = 10
            debug_assert((hist.size() / 1) <= maxiter)
            # nearest neighbour
            var nn = List[List[UInt16]](capacity=Int(maxiter))
            for i in range(maxiter):
                nn.append(List[UInt16](capacity=Int(maxNeighbours)))
            var nnn = List[UInt8](length=Int(maxiter), fill=0)  # number of nn

            var j: UInt32 = 0
            var k: UInt32 = 0
            while j < hist.size():
                debug_assert(k < maxiter)
                var p = hist.begin() + j
                var i = p[].cast[DType.uint32]() + firstPixel
                debug_assert(id[i] != GPUClusteringConstants.InvId)
                debug_assert(id[i] == thisModuleId)  # same module
                var be = Hist.bin(y[i] + 1).cast[DType.uint32]()
                var e = hist.end(be)
                p += 1
                debug_assert(nnn[k] == 0)
                while p < e:
                    var m = p[].cast[DType.uint32]() + firstPixel
                    debug_assert(m != i)
                    debug_assert(Int(y[m]) - Int(y[i]) >= 0)
                    debug_assert(Int(y[m]) - Int(y[i]) <= 1)
                    if abs(Int(x[m]) - Int(x[i])) > 1:
                        continue
                    var l = nnn[k]
                    nnn[k] += 1
                    debug_assert(l < maxNeighbours)
                    nn[k][l] = p[]
                    p += 1
                j += 1
                k += 1

            # for each pixel, look at all the pixels until the end of the module;
            # when two valid pixels within +/- 1 in x or y are found, set their id to the minimum;
            # after the loop, all the pixel in each cluster should have the id equeal to the lowest
            # pixel in the cluster ( clus[i] == i ).
            var more = True
            var nloops = 0
            while more:
                if nloops % 2 == 1:
                    var j: UInt32 = 0
                    var k: UInt32 = 0
                    while j < hist.size():
                        var p = hist.begin() + j
                        var i = p[].cast[DType.uint32]() + firstPixel
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
                        var i = p[].cast[DType.uint32]() + firstPixel
                        for kk in range(nnn[k]):
                            var l = nn[k][kk]
                            var m = l.cast[DType.uint32]() + firstPixel
                            debug_assert(m != i)
                            var old = clusterId[m]
                            clusterId[m] = min(clusterId[m], clusterId[i])
                            if old != clusterId[i]:
                                # end the loop only if no changes were applied
                                more = True
                            clusterId[i] = min(clusterId[i], old)
                        j += 1
                        k += 1
                nloops += 1

            var foundClusters: UInt32 = 0

            # find the number of different clusters, identified by a pixels with clus[i] == i;
            # mark these pixels with a negative id.
            for i in range(first, msize):
                if id[i] == GPUClusteringConstants.InvId:   # skip invalid pixels
                    continue
                if clusterId[i] == i.cast[DType.int32]():
                    var old = foundClusters
                    foundClusters = foundClusters + 1 if foundClusters <  0xFFFFFFFF else foundClusters
                    clusterId[i] = -((old + 1).cast[DType.int32]())
            
            # propagate the negative id to all the pixels in the cluster.
            for i in range(first, msize):
                if id[i] == GPUClusteringConstants.InvId:   # skip invalid pixels
                    continue
                if clusterId[i] >= 0:
                    # mark each pixel in a cluster with the same id as the first one
                    clusterId[i] = clusterId[clusterId[i]]
            
            # adjust the cluster id to be a positive value starting from 0
            for i in range(first, msize):
                if id[i] == GPUClusteringConstants.InvId:   # skip invalid pixels
                    clusterId[i] = -9999
                    continue
                clusterId[i] = -clusterId[i] - 1
            
            nClustersInModule[thisModuleId] = foundClusters
            moduleId[module] = thisModuleId.cast[DType.uint32]()


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
