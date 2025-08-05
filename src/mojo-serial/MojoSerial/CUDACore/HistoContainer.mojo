from sys import sizeof
from memory import UnsafePointer, memset

from MojoSerial.CUDACore.AtomicPairCounter import AtomicPairCounter
import MojoSerial.CUDACore.CUDAStdAlgorithm as CUDAStdAlgorithm
from MojoSerial.CUDACore.PrefixScan import blockPrefixScan
from MojoSerial.MojoBridge.Array import Array
from MojoSerial.MojoBridge.DTypes import Typeable, signed_to_unsigned


fn countFromVector[
    T: DType, //
](
    mut h: HistoContainer[T, *_],
    nh: UInt32,
    v: UnsafePointer[Scalar[T], mut=False],
    offsets: UnsafePointer[UInt32, mut=True],
):
    for i in range(offsets[nh]):
        var off = CUDAStdAlgorithm.upper_bound(offsets, offsets + nh + 1, i)

        debug_assert(off[] > 0)
        var ih = Int(off) - Int(offsets) - 1

        debug_assert(ih >= 0)
        debug_assert(ih < Int(nh))
        h.count(v[i], ih)


fn fillFromVector[
    T: DType, //
](
    mut h: HistoContainer[T, *_],
    nh: UInt32,
    v: UnsafePointer[Scalar[T]],
    mut offsets: UnsafePointer[UInt32],
):
    for i in range(offsets[nh]):
        var off = CUDAStdAlgorithm.upper_bound(offsets, offsets + nh + 1, i)

        debug_assert(off[] > 0)
        var ih = Int(off) - Int(offsets) - 1

        debug_assert(ih >= 0)
        debug_assert(ih < Int(nh))
        h.fill(v[i], Scalar[h.IndexType](i), ih)


@always_inline
fn launchZero(mut h: HistoContainer):
    var poff = h.off.unsafe_ptr()
    var size = Int(h.totbins())
    memset(poff, 0, size)  # memset sets by bytes in C++, but by elements here


@always_inline
fn launchFinalize(mut h: HistoContainer[*_]):
    h.finalize()


@always_inline
fn fillManyFromVector[
    T: DType
](
    mut h: HistoContainer[T, *_],
    nh: UInt32,
    v: UnsafePointer[Scalar[T]],
    mut offsets: UnsafePointer[UInt32],
    totSize: UInt32,
):
    launchZero(h)
    countFromVector(h, nh, v, offsets)
    h.finalize()
    fillFromVector(h, nh, v, offsets)


fn finalizeBulk(
    apc: UnsafePointer[AtomicPairCounter], mut assoc: HistoContainer[*_]
):
    assoc.bulkFinalizeFill(apc[])


fn forEachInBins[
    V: DType
](
    ref hist: HistoContainer[V, *_],
    value: Scalar[V],
    n: Int,
    func: fn (Scalar[hist.IndexType]),
):
    """Iterate over N bins left and right of the one containing "v"."""
    var bs = Int(hist.bin(value))
    var be = min(Int(hist.nbins()) - 1, bs + n)
    bs = max(0, bs - n)
    debug_assert(be >= bs)

    var pj = hist.begin(bs)
    while pj < hist.end(be):
        func(pj[])
        pj += 1


fn forEachInWindow[
    V: DType
](
    ref hist: HistoContainer[V, *_],
    wmin: Scalar[V],
    wmax: Scalar[V],
    func: fn (Scalar[hist.IndexType]),
):
    """Iterate over bins containing all values in window wmin, wmax."""
    var bs = Int(hist.bin(wmin))
    var be = Int(hist.bin(wmax))
    debug_assert(be >= bs)

    var pj = hist.begin(bs)
    while pj < hist.end(be):
        func(pj[])
        pj += 1


struct HistoContainer[
    T: DType,  # the type of the discretized input values
    NBINS: UInt32,  # number of bins
    SIZE: UInt32,  # max number of elements
    S: UInt32 = T.sizeof(),  # number of significant bits in T
    I: DType = DType.uint32,  # type stored in the container (usually an index in a vector of the input values)
    NHISTS: UInt32 = 1,  # number of histos stored
](Movable, Defaultable, Typeable, Sized):
    alias CountersOnly = HistoContainer[T, NBINS, 0, S, I, NHISTS]
    alias Counter = UInt32
    alias IndexType = I

    alias D = Scalar[T]
    alias UT = signed_to_unsigned[T]()
    alias UD = Scalar[Self.UT]

    var off: Array[UInt32, Int(Self.totbins())]
    var psws: UInt32
    var bins: Array[Scalar[Self.IndexType], Int(Self.capacity())]

    @always_inline
    fn __init__(out self):
        self.off = Array[UInt32, Int(Self.totbins())](0)
        self.psws = 0
        self.bins = Array[Scalar[Self.IndexType], Int(Self.capacity())](0)

    @staticmethod
    fn ilog2(v_in: UInt32) -> UInt32:
        alias b = Array[UInt32, 5](0x2, 0xC, 0xF0, 0xFF00, 0xFFFF0000)
        alias s = Array[UInt32, 5](1, 2, 4, 8, 16)

        var v = v_in

        var r: UInt32 = 0
        for i in range(4, -1, -1):
            if v & b[i]:
                v = v >> s[i]
                r = r | s[i]
        return r

    @staticmethod
    @always_inline
    fn sizeT() -> UInt32:
        return S

    @staticmethod
    @always_inline
    fn nbins() -> UInt32:
        return NBINS

    @staticmethod
    @always_inline
    fn nhists() -> UInt32:
        return NHISTS

    @staticmethod
    @always_inline
    fn totbins() -> UInt32:
        return NHISTS * NBINS + 1

    @staticmethod
    @always_inline
    fn nbits() -> UInt32:
        return Self.ilog2(NBINS - 1) + 1

    @staticmethod
    @always_inline
    fn capacity() -> UInt32:
        return SIZE

    @staticmethod
    @always_inline
    fn histOff(nh: UInt32) -> UInt32:
        return NBINS * nh

    @always_inline
    fn __len__(self) -> Int:
        return Int(self.size())

    @staticmethod
    fn bin(t: Self.D) -> Self.UD:
        var shift = Self.sizeT() - Self.nbits()
        var mask = (1 << Self.nbits()) - 1
        return (t.cast[Self.UT]() >> shift.cast[Self.UT]()) & mask.cast[
            Self.UT
        ]()

    @always_inline
    fn zero(mut self):
        for i in range(len(self.off)):
            self.off[i] = 0

    @always_inline
    fn add(mut self, ref co: Self.CountersOnly):
        for i in range(Self.totbins()):
            self.off[i] += co.off[i]

    @always_inline
    fn countDirect(mut self, b: Self.D):
        debug_assert(UInt32(b) < Self.nbins())
        self.off[b] += 1

    @always_inline
    fn fillDirect(mut self, b: Self.D, j: Scalar[Self.IndexType]):
        debug_assert(UInt32(b) < Self.nbins())
        self.off[b] -= 1
        var w = self.off[b]
        debug_assert(w > 0)
        self.bins[w - 1] = j

    @always_inline
    fn bulkFill(
        mut self,
        mut apc: AtomicPairCounter,
        v: UnsafePointer[Scalar[Self.IndexType]],
        n: UInt32,
    ) -> Int32:
        var c = apc.add(n)
        if c[1] >= Self.nbins():
            return -Int32(c[1])

        self.off[c[1]] = c[0]
        for j in range(n):
            self.bins[c[0] + j] = v[j]

        return Int32(c[1])

    @always_inline
    fn bulkFinalize(mut self, apc: AtomicPairCounter):
        self.off[apc.get()[1]] = apc.get()[0]

    @always_inline
    fn bulkFinalizeFill(mut self, apc: AtomicPairCounter):
        var m = apc.get()[1]
        var n = apc.get()[0]

        if m >= Self.nbins():  # overflow
            self.off[Self.nbins()] = self.off[Self.nbins() - 1]
            return

        for i in range(m, Self.totbins()):
            self.off[i] = n

    @always_inline
    fn count(mut self, t: Self.D):
        var b: UInt32 = Self.bin(t).cast[DType.uint32]()
        debug_assert(b < Self.nbins())
        self.off[b] += 1

    @always_inline
    fn fill(mut self, t: Self.D, j: Scalar[Self.IndexType]):
        var b: UInt32 = Self.bin(t).cast[DType.uint32]()
        debug_assert(b < Self.nbins())
        self.off[b] -= 1
        var w = self.off[b]
        debug_assert(w > 0)
        self.bins[w - 1] = j

    @always_inline
    fn count(mut self, t: Self.D, nh: UInt32):
        var b: UInt32 = Self.bin(t).cast[DType.uint32]()
        debug_assert(b < Self.nbins())
        b += Self.histOff(nh)
        debug_assert(b < Self.totbins())
        self.off[b] += 1

    @always_inline
    fn fill(mut self, t: Self.D, j: Scalar[Self.IndexType], nh: UInt32):
        var b: UInt32 = Self.bin(t).cast[DType.uint32]()
        debug_assert(b < Self.nbins())
        b += Self.histOff(nh)
        debug_assert(b < Self.totbins())
        self.off[b] -= 1
        var w = self.off[b]
        debug_assert(w > 0)
        self.bins[w - 1] = j

    @always_inline
    fn finalize(self):
        debug_assert(self.off[Self.totbins() - 1] == 0)
        blockPrefixScan(self.off.unsafe_ptr(), Int(Self.totbins()))
        debug_assert(
            self.off[Self.totbins() - 1] == self.off[Self.totbins() - 2]
        )

    @always_inline
    fn size(self) -> UInt32:
        return UInt32(self.off[Self.totbins() - 1])

    @always_inline
    fn size(self, b: UInt32) -> UInt32:
        return UInt32(self.off[b + 1] - self.off[b])

    fn begin(self) -> UnsafePointer[Scalar[Self.IndexType], mut=False]:
        return self.bins.unsafe_ptr()

    fn end(self) -> UnsafePointer[Scalar[Self.IndexType], mut=False]:
        return self.begin() + self.size()

    fn begin(
        self, b: UInt32
    ) -> UnsafePointer[Scalar[Self.IndexType], mut=False]:
        return self.bins.unsafe_ptr() + self.off[b]

    fn end(self, b: UInt32) -> UnsafePointer[Scalar[Self.IndexType], mut=False]:
        return self.bins.unsafe_ptr() + self.off[b + 1]

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return (
            "HistoContainer["
            + T.__repr__()
            + ", "
            + String(NBINS)
            + ", "
            + String(SIZE)
            + ", "
            + String(S)
            + ", "
            + I.__repr__()
            + ", "
            + String(NHISTS)
            + "]"
        )


alias OneToManyAssoc = HistoContainer[DType.uint32, _, _, I=_]