from collections import Set
from memory import memset

from MojoSerial.CUDADataFormats.GPUClusteringConstants import (
    GPUClusteringConstants,
)
from MojoSerial.PluginSiPixelClusterizer.GPUClustering import GPUClustering

alias numElements = 256 * 2000


fn generate_clusters(
    kn: Int,
    mut h_id: InlineArray[UInt16, numElements],
    mut h_x: InlineArray[UInt16, numElements],
    mut h_y: InlineArray[UInt16, numElements],
    mut h_adc: InlineArray[UInt16, numElements],
    mut y: InlineArray[Int, 10],
    mut n: Int,
    mut ncl: Int,
):
    var add_big_noise = kn % 2 == 1

    if add_big_noise:
        alias MaxPixels = 1000
        alias id = 666

        for x in range(0, 140, 3):
            for y in range(0, 400, 3):
                h_id[n] = id
                h_x[n] = x
                h_y[n] = y
                h_adc[n] = 1000

                n += 1
                ncl += 1

                if MaxPixels <= ncl:
                    break

            if MaxPixels <= ncl:
                break

    @parameter
    if True:  # Isolated
        var id = 42
        var x = 10

        ncl += 1
        h_id[n] = id
        h_x[n] = x
        h_y[n] = x
        h_adc[n] = 100 if kn == 0 else 5000
        n += 1

        # first column
        ncl += 1
        h_id[n] = id
        h_x[n] = x
        h_y[n] = 0
        h_adc[n] = 5000
        n += 1

        # first columns
        ncl += 1
        h_id[n] = id
        h_x[n] = x + 80
        h_y[n] = 2
        h_adc[n] = 5000
        n += 1
        h_id[n] = id
        h_x[n] = x + 80
        h_y[n] = 1
        h_adc[n] = 5000
        n += 1

        # last column
        ncl += 1
        h_id[n] = id
        h_x[n] = x
        h_y[n] = 415
        h_adc[n] = 5000
        n += 1

        # last columns
        ncl += 1
        h_id[n] = id
        h_x[n] = x + 80
        h_y[n] = 415
        h_adc[n] = 2500
        n += 1
        h_id[n] = id
        h_x[n] = x + 80
        h_y[n] = 414
        h_adc[n] = 2500
        n += 1

        # diagonal
        ncl += 1

        @parameter
        for x in range(20, 25):
            h_id[n] = id
            h_x[n] = x
            h_y[n] = x
            h_adc[n] = 1000
            n += 1

        # reversed
        ncl += 1

        @parameter
        for x in range(45, 40, -1):
            h_id[n] = id
            h_x[n] = x
            h_y[n] = x
            h_adc[n] = 1000
            n += 1

        ncl += 1
        h_id[n] = GPUClusteringConstants.InvId  # error
        n += 1

        # messy
        var xx = InlineArray[Int, 5](21, 25, 23, 24, 22)

        @parameter
        for k in range(5):
            h_id[n] = id
            h_x[n] = xx[k]
            h_y[n] = 20 + xx[k]
            h_adc[n] = 1000
            n += 1

        # holes
        ncl += 1

        @parameter
        for k in range(5):
            h_id[n] = id
            h_x[n] = xx[k]
            h_y[n] = 100
            h_adc[n] = 100 if kn == 2 else 1000
            n += 1

            if xx[k] % 2 == 0:
                h_id[n] = id
                h_x[n] = xx[k]
                h_y[n] = 101
                h_adc[n] = 1000
                n += 1

    @parameter
    if True:
        var id = 0
        var x = 10

        ncl += 1
        h_id[n] = id
        h_x[n] = x
        h_y[n] = x
        h_adc[n] = 5000
        n += 1

    # all odd id
    for id in range(11, 1801, 2):
        if (id // 20) % 2 == 1:
            h_id[n] = GPUClusteringConstants.InvId  # error
            n += 1

        @parameter
        for x in range(0, 40, 4):
            ncl += 1
            if (id // 10) % 2 == 1:

                @parameter
                for k in range(10):
                    h_id[n] = id
                    h_x[n] = x
                    h_y[n] = x + y[k]
                    h_adc[n] = 100
                    n += 1
                    h_id[n] = id
                    h_x[n] = x + 1
                    h_y[n] = x + y[k] + 2
                    h_adc[n] = 1000
                    n += 1
            else:

                @parameter
                for k in range(10):
                    h_id[n] = id
                    h_x[n] = x
                    h_y[n] = x + y[9 - k]
                    h_adc[n] = 10 if kn == 2 else 1000
                    n += 1
                    if y[k] == 3:  # hole
                        continue
                    if id == 51:  # error
                        h_id[n] = GPUClusteringConstants.InvId
                        n += 1
                        h_id[n] = GPUClusteringConstants.InvId
                        n += 1
                    h_id[n] = id
                    h_x[n] = x + 1
                    h_y[n] = x + y[k] + 2
                    h_adc[n] = 10 if kn == 2 else 1000
                    n += 1


fn main() raises:
    var h_id = InlineArray[UInt16, numElements](0)
    var h_x = InlineArray[UInt16, numElements](0)
    var h_y = InlineArray[UInt16, numElements](0)
    var h_adc = InlineArray[UInt16, numElements](0)
    var h_clus = InlineArray[Int32, numElements](0)

    var h_moduleStart = InlineArray[
        UInt32, Int(GPUClusteringConstants.MaxNumModules) + 1
    ](0)
    var h_clusInModule = InlineArray[
        UInt32, Int(GPUClusteringConstants.MaxNumModules)
    ](0)
    var h_moduleId = InlineArray[UInt32, Int(GPUClusteringConstants.MaxNumModules)](0)

    var n: Int
    var ncl: Int
    var y = InlineArray[Int, 10](5, 7, 9, 1, 3, 0, 4, 8, 2, 6)

    @parameter
    for kkk in range(5):
        n = 0
        ncl = 0
        generate_clusters(kkk, h_id, h_x, h_y, h_adc, y, n, ncl)

        print("created", n, "digis in", ncl, "clusters")
        debug_assert(n <= numElements)

        var nModules: UInt32 = 0

        h_moduleStart[0] = nModules
        GPUClustering.countModules(
            h_id.unsafe_ptr(),
            h_moduleStart.unsafe_ptr(),
            h_clus.unsafe_ptr(),
            n,
        )
        memset(
            h_clusInModule.unsafe_ptr(),
            0,
            Int(GPUClusteringConstants.MaxNumModules),
        )

        GPUClustering.findClus(
            h_id.unsafe_ptr(),
            h_x.unsafe_ptr(),
            h_y.unsafe_ptr(),
            h_moduleStart.unsafe_ptr(),
            h_clusInModule.unsafe_ptr(),
            h_moduleId.unsafe_ptr(),
            h_clus.unsafe_ptr(),
            n,
        )

        nModules = h_moduleStart[0]
        var summ: UInt32 = 0
        for i in range(h_clusInModule.__len__()):
            summ += h_clusInModule[i]

        print("before charge cut found", summ, "clusters")

        for i in range(GPUClusteringConstants.MaxNumModules, 0, -1):
            if h_clusInModule[i - 1] > 0:
                print("last module is", i - 1, h_clusInModule[i - 1])
                break

        if UInt32(ncl) != summ:
            print("ERROR!!!!! wrong number of cluster found")

        GPUClustering.clusterChargeCut(
            h_id.unsafe_ptr(),
            h_adc.unsafe_ptr(),
            h_moduleStart.unsafe_ptr(),
            h_clusInModule.unsafe_ptr(),
            h_moduleId.unsafe_ptr(),
            h_clus.unsafe_ptr(),
            n,
        )

        print("found", nModules, "Modules active")

        var clids_set = Set[UInt]()

        for i in range(n):
            debug_assert(h_id[i] != 666)  # only noise
            if h_id[i] == GPUClusteringConstants.InvId:
                continue
            debug_assert(h_clus[i] >= 0)
            debug_assert(h_clus[i] < Int(h_clusInModule[h_id[i]]))
            clids_set.add(UInt(h_id[i]) * 1000 + UInt(h_clus[i]))

        var clids = List[UInt](capacity=clids_set.__len__())
        for item in clids_set:
            clids.append(item)
        sort(clids)

        # verify no hole in numbering
        var p = clids[0]
        var cmid = p // 1000
        debug_assert(0 == p % 1000)

        print(
            "first clusters",
            p,
            clids[1],
            h_clusInModule[cmid],
            h_clusInModule[clids[1] // 1000],
        )
        print(
            "last cluster",
            clids[-1],
            h_clusInModule[clids[-1] // 1000],
        )

        for i in range(1, clids.__len__()):
            c = clids[i]
            var cc = c
            var pp = p
            var mid = cc // 1000
            var pnc = pp % 1000
            var nc = cc % 1000

            if mid != cmid:
                debug_assert(0 == cc % 1000)
                debug_assert(h_clusInModule[cmid] - 1 == pp % 1000)
                cmid = mid
                p = c
                continue

            if nc != pnc + 1:
                print("error ", mid, ": ", nc, " ", pnc)
            p = c

        summ = 0
        for i in range(len(h_clusInModule)):
            summ += h_clusInModule[i]

        print("found", summ, clids.__len__(), "clusters")

        for i in range(GPUClusteringConstants.MaxNumModules, 0, -1):
            if h_clusInModule[i - 1] > 0:
                print("last module is", i - 1, h_clusInModule[i - 1])
                break
