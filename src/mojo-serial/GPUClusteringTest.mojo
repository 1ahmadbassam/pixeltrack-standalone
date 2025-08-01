from MojoSerial.PluginSiPixelClusterizer.GPUClustering import GPUClustering
from MojoSerial.MojoBridge.Array import Array
from memory import memset
from collections import Set

alias numElements : Int = 256 * 2000
alias MaxNumModules : Int = 2000
alias InvId : Int = 9999 # must be greater than MaxNumModules

@always_inline
fn generate_clusters(kn: Int, mut h_id: Array[UInt16, numElements], mut h_x: Array[UInt16, numElements],
                    mut h_y: Array[UInt16, numElements], mut h_adc: Array[UInt16, numElements],
                    mut y : List[Int], mut n: Int, mut ncl: Int):
    var add_big_noise : Bool = (kn % 2 == 1)

    if add_big_noise:
        alias MaxPixels : Int = 1000
        alias id : Int = 666

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
    if True: # Isolated
        var id = 42
        var x = 10

        ncl += 1
        h_id[n] = id
        h_x[n] = x
        h_y[n] = x
        if kn == 0:
            h_adc[n] = 100
        else:
            h_adc[n] = 5000
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
        for x in range(20, 25):
            h_id[n] = id
            h_x[n] = x
            h_y[n] = x
            h_adc[n] = 1000
            n += 1
        
        # reversed
        ncl += 1
        for x in range(45, 40, -1):
            h_id[n] = id
            h_x[n] = x
            h_y[n] = x
            h_adc[n] = 1000
            n += 1

        ncl += 1
        h_id[n] = InvId  # error
        n += 1

        var xx : List[Int] = [21, 25, 23, 24, 22]
        for k in range(5):
            h_id[n] = id
            h_x[n] = xx[k]
            h_y[n] = 20 + xx[k]
            h_adc[n] = 1000
            n += 1

        # holes
        ncl += 1
        for k in range(5):
            h_id[n] = id
            h_x[n] = xx[k]
            h_y[n] = 100
            if kn == 2:
                h_adc[n] = 100
            else:
                h_adc[n] = 1000
            n += 1

            if xx[k] % 2 == 0:
                h_id[n] = id
                h_x[n] = xx[k]
                h_y[n] = 101
                h_adc[n] = 1000
                n += 1

    var id : Int = 0
    var x : Int = 10

    ncl += 1
    h_id[n] = id
    h_x[n] = x
    h_y[n] = x
    h_adc[n] = 5000
    n += 1

    # all odd id
    for id in range(11, 1801, 2):
        if ((id // 20) % 2) == 1:
            h_id[n] = InvId  # error
            n += 1

        for x in range(0, 40, 4):
            ncl += 1
            if ((id // 10) % 2) == 1:
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
                for k in range(10):
                    h_id[n] = id
                    h_x[n] = x
                    h_y[n] = x + y[9 - k]
                    if kn == 2:
                        h_adc[n] = 10
                    else:
                        h_adc[n] = 1000
                    n += 1

                    if y[k] == 3: # hole
                        continue
                    if id == 51: # error
                        h_id[n] = InvId
                        n += 1
                        h_id[n] = InvId
                        n += 1
                        
                    h_id[n] = id
                    h_x[n] = x + 1
                    h_y[n] = x + y[k] + 2
                    if kn == 2:
                        h_adc[n] = 10
                    else:
                        h_adc[n] = 1000
                    n += 1


fn main():
    var h_id = Array[UInt16, numElements](0)
    var h_x = Array[UInt16, numElements](0)
    var h_y = Array[UInt16, numElements](0)
    var h_adc = Array[UInt16, numElements](0)
    var h_clus = Array[Int32, numElements](0)

    var h_moduleStart = Array[UInt32, MaxNumModules + 1](0)
    var h_clusInModule = Array[UInt32, MaxNumModules](0)
    var h_moduleId = Array[UInt32, MaxNumModules](0)

    var n : Int = 0
    var ncl : Int = 0
    var y : List[Int] = [5, 7, 9, 1, 3, 0, 4, 8, 2, 6]

    for kkk in range(5):
        n = 0
        ncl = 0
        generate_clusters(kkk, h_id, h_x, h_y, h_adc, y, n, ncl)

        print("created ", n, " digis in ", ncl, " clusters")
        debug_assert(n <= numElements)

        var nModules : UInt32 = 0

        h_moduleStart[0] = nModules
        GPUClustering.countModules(h_id.unsafe_ptr(), h_moduleStart.unsafe_ptr(), h_clus.unsafe_ptr(), n)
        memset(h_clusInModule.unsafe_ptr(), 0, MaxNumModules)

        GPUClustering.findClus(h_id.unsafe_ptr(), h_x.unsafe_ptr(), h_y.unsafe_ptr(), h_moduleStart.unsafe_ptr(),
                            h_clusInModule.unsafe_ptr(), h_moduleId.unsafe_ptr(), h_clus.unsafe_ptr(), n)

        nModules = h_moduleStart[0]
        var summ : UInt32 = 0
        for i in range(len(h_clusInModule)):
            summ += h_clusInModule[i]

        print("before charge cut found ", summ, " clusters")

        for i in range(MaxNumModules, 0, -1):
            if h_clusInModule[i - 1] > 0:
                print("last module is ", i - 1, ' ', h_clusInModule[i - 1])
                break

        if UInt32(ncl) != summ:
            print("ERROR! wrong number of clusters found")

        GPUClustering.clusterChargeCut(h_id.unsafe_ptr(), h_adc.unsafe_ptr(), h_moduleStart.unsafe_ptr(),
                                    h_clusInModule.unsafe_ptr(), h_moduleId.unsafe_ptr(), h_clus.unsafe_ptr(), n)

        print("found " , nModules , " Modules active")

        var clids = Set[UInt]()

        for i in range(n):
            debug_assert(h_id[i] != 666)  # only noise
            if (h_id[i] == InvId):
                continue
            debug_assert(h_clus[i] >= 0)
            debug_assert(h_clus[i] < Int(h_clusInModule[h_id[i]]))
            clids.add(UInt(h_id[i]) * 1000 + UInt(h_clus[i]))

        # verify no hole in numbering
        var p = clids.begin()
        var cmid = (*p) / 1000
        debug_assert(0 == (*p) % 1000)
        var c = p
        c+= 1

        print("first clusters " , *p , ' ' , *c , ' ' , h_clusInModule[cmid] , ' ' , h_clusInModule[(*c) // 1000])
        print("last cluster " , *clids.rbegin() , ' ' , h_clusInModule[(*clids.rbegin()) // 1000])
        
        for ( c != clids.end() ++c) {
        var cc = *c
        var pp = *p
        var mid = cc / 1000
        var pnc = pp % 1000
        var nc = cc % 1000
        if (mid != cmid) {
            assert(0 == cc % 1000)
            assert(h_clusInModule[cmid] - 1 == pp % 1000)
            // if (h_clusInModule[cmid]-1 != pp%1000) std::cout << "error size " << mid << ": "  << h_clusInModule[mid] << ' ' << pp << std::endl
            cmid = mid
            p = c
            continue
        }
        p = c
        // assert(nc==pnc+1)
        if (nc != pnc + 1)
            std::cout << "error " << mid << ": " << nc << ' ' << pnc << std::endl
        }

        std::cout << "found " << std::accumulate(h_clusInModule, h_clusInModule + MaxNumModules, 0) << ' ' << clids.size() << " clusters"
                << std::endl
        for (var i = MaxNumModules i > 0 i--)
        if (h_clusInModule[i - 1] > 0) {
            std::cout << "last module is " << i - 1 << ' ' << h_clusInModule[i - 1] << std::endl
            break
        }
        // << " and " << seeds.size() << " seeds" << std::endl
    }  /// end loop kkk