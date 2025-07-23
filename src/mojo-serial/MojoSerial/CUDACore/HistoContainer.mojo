import MojoSerial.CUDACore.CudaStdAlgorithm as CudaStdAlgorithm
from MojoSerial.CUDACore.AtomicPairCounter import AtomicPairCounter
from MojoSerial.CUDACore.PrefixScan import blockPrefixScan
from MojoSerial.MojoBridge.DTypes import Typeable
from sys.info import sizeof
from memory import UnsafePointer

fn countFromVector[T: DType](mut h : HistoContainer[*_], nh : UInt32, v : UnsafePointer[Scalar[T]], mut offsets : UnsafePointer[UInt32]):
    for i in range(offsets[nh]):
        var off = CudaStdAlgorithm.upper_bound(offsets, offsets + nh + 1, i)

        debug_assert(off[] > 0)
        var ih : Int32 = (Int(off) - Int(offsets))//sizeof[UInt32]() - 1

        debug_assert(ih >= 0)
        debug_assert(ih < Int(nh))
        h.count(v[i], ih)

fn fillFromVector[T: DType](mut h : HistoContainer[*_], nh : UInt32, v : UnsafePointer[Scalar[T]], mut offsets : UnsafePointer[UInt32]):
    for i in range(offsets[nh]):
        var off = CudaStdAlgorithm.upper_bound(offsets, offsets + nh + 1, i)

        debug_assert(off[] > 0)
        var ih : Int32 = (Int(off) - Int(offsets))//sizeof[UInt32]() - 1

        debug_assert(ih >= 0)
        debug_assert(ih < Int(nh))
        h.fill(v[i], i, ih)

@always_inline
fn launchZero(mut h : HistoContainer[*_]):
    var poff = UnsafePointer[mut = True](to = h.off)

    for i in range(len(h.off)):
      poff[][i] = 0
    h.psws = 0

@always_inline
fn launchFinalize(mut h : HistoContainer[*_]):
    h.finalize()

@always_inline
fn fillManyFromVector[T : DType](mut h : HistoContainer, nh : UInt32, v : UnsafePointer[Scalar[T]],
                                 mut offsets : UnsafePointer[UInt32], totSize : UInt32):
  launchZero(h)
  countFromVector(h, nh, v, offsets)
  h.finalize()
  fillFromVector(h, nh, v, offsets)

fn finalizeBulk(apc : UnsafePointer[AtomicPairCounter], mut assoc : HistoContainer[*_]):
  assoc.bulkFinalizeFill(apc[])

fn forEachInBins[V : DType, Func : AnyType](ref hist : HistoContainer, value : Scalar[V], n : Int, func : Func):
  var bs : Int = hist.bin(value)
  var be : Int = min(Int(hist.nbins()) - 1, bs + n)
  bs = max(0, bs - n)
  debug_assert(be >= bs)

  pj = hist.begin(bs)
  while pj < hist.end(be):
    func(pj[])
    pj += 1

fn forEachInWindow[V : AnyTrivialRegType, Func : AnyType](ref hist : HistoContainer, wmin : V, wmax : V, ref func : Func):
  bs : Int = HistoContainer.bin(wmin)
  be : Int = HistoContainer.bin(wmax)
  debug_assert(be >= bs)

  pj = hist.begin(bs)
  while pj < hist.end(be):
    func(pj[])
    pj += 1


struct HistoContainer[
    T: DType,
    NBINS: UInt32,
    SIZE: UInt32,
    S: UInt32 = sizeof[T](),
    I: DType = DType.uint32,
    NHISTS: UInt32 = 1,
](Movable, Defaultable, Typeable):
    
    alias Counter = UInt32

    alias CountersOnly = HistoContainer[T, NBINS, 0, S, I, NHISTS]

    alias index_type = I
    alias UT = UInt32

    var off : InlineArray[HistoContainer.Counter, HistoContainer[T, NBINS, SIZE, S, I, NHISTS].totbins()]
    var psws : UInt32
    var bins : InlineArray[I, HistoContainer.capacity()]

    fn __init__(out self):
        pass

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "HistoContainer[" + T.__repr__() + ", " + String(NBINS) + ", " + String(SIZE) + ", " + String(S) + ", " + I.__repr__() + ", " + String(NHISTS) + "]"

    @staticmethod
    fn ilog2(v : UInt32) -> UInt32:
      var b : List[UInt32] = [0x2, 0xC, 0xF0, 0xFF00, 0xFFFF0000]
      alias s : List[UInt32] = [1, 2, 4, 8, 16]

      var r : UInt32 = 0
      for i in range(4,-1,-1):
        if (v & b[i]):
          v = v >> s[i]
          r = r | s[i]
      return r

    @staticmethod
    fn sizeT() -> UInt32:
      return S

    @staticmethod
    fn nbins() -> UInt32:
      return NBINS

    @staticmethod
    fn nhists() -> UInt32:
      return NHISTS

    @staticmethod
    fn totbins() -> UInt32:
      return NHISTS * NBINS + 1

    @staticmethod
    fn nbits(self) -> UInt32:
      return HistoContainer.ilog2(NBINS - 1) + 1

    @staticmethod
    fn capacity() -> UInt32:
      return SIZE

    @staticmethod
    fn histOff(self, nh : UInt32) -> UInt32:
      return NBINS * nh

    @staticmethod
    fn bin(self, T t) -> UT:
      var shift : UInt32 = HistoContainer.sizeT() - HistoContainer.nbits()
      var mask : UInt32 = (1 << HistoContainer.nbits()) - 1
      return (t >> shift) & mask

    fn zero(mut self):
      for i in range(len(self.off))
        self.off[i] = 0

    @always_inline
    fn add(mut self, ref co : CountersOnly):
      for i in range(HistoContainer.totbins()):
        self.off[i] += co.off[i]

    @always_inline
    @staticmethod
    fn atomicIncrement(mut x : Counter) -> UInt32:
      x += 1
      return x

    @always_inline
    @staticmethod
    fn atomicDecrement(mut x : Counter) -> UInt32:
      x -= 1
      return x

    @always_inline
    fn countDirect(mut self, T b):
      debug_assert(b < HistoContainer.nbins())
      HistoContainer.atomicIncrement(self.off[b])

    @always_inline
    fn fillDirect(mut self, T b, index_type j):
      debug_assert(b < HistoContainer.nbins())
      var w = HistoContainer.atomicDecrement(self.off[b])
      debug_assert(w > 0)
      HistoContainer.bins[w - 1] = j

    @always_inline
    fn bulkFill(mut self, mut apc : AtomicPairCounter, v : UnsafePointer[index_type], n : UInt32) -> UInt32:
      var c = apc.add(n)
      if (c.m >= HistoContainer.nbins()):
        return -Int32(c.m)

      self.off[c.m] = c.n
      for i in range(n):
        self.bins[c.n + i] = v[i]

      return c.m

    @always_inline
    fn bulkFinalize(mut self, mut apc : AtomicPairCounter):
      self.off[apc.get().m] = apc.get().n

    @always_inline
    fn bulkFinalizeFill(mut self, mut apc : AtomicPairCounter):
      var m = apc.get().m
      var n = apc.get().n

      if (m >= HistoContainer.nbins()):
        self.off[HistoContainer.nbins()] = UInt32(self.off[HistoContainer.nbins() - 1])
        return

      for i in range(m, HistoContainer.totbins()):
        self.off[i] = n

    @always_inline
    fn count(mut self, T t):
      var b : UInt32 = HistoContainer.bin(t)
      debug_assert(b < HistoContainer.nbins())
      HistoContainer.atomicIncrement(self.off[b])

    @always_inline
    fn fill(mut self, T t, j : index_type):
      var b : UInt32 = HistoContainer.bin(t)
      debug_assert(b < HistoContainer.nbins())
      var w = HistoContainer.atomicDecrement(self.off[b])

      debug_assert(w > 0)
      self.bins[w - 1] = j

    @always_inline
    fn count(mut self, T t, nh : UInt32):
      var b : UInt32 = HistoContainer.bin(t)
      debug_assert(b < HistoContainer.nbins())
      b += HistoContainer.histOff(nh)

      debug_assert(b < HistoContainer.totbins())
      HistoContainer.atomicIncrement(self.off[b])

    @always_inline
    fn fill(mut self, T t, j : index_type, nh : UInt32):
      var b : UInt32 = HistoContainer.bin(t)
      debug_assert(b < HistoContainer.nbins())
      b += HistoContainer.histOff(nh)

      debug_assert(b < HistoContainer.totbins())
      HistoContainer.atomicIncrement(self.off[b])

      debug_assert(w > 0)
      self.bins[w - 1] = j

    @always_inline
    fn finalize(self):
      debug_assert(self.off[HistoContainer.totbins() - 1] == 0)
      blockPrefixScan(self.off, HistoContainer.totbins())
      debug_assert(self.off[HistoContainer.totbins() - 1] == self.off[HistoContainer.totbins() - 2])

    fn size(self) -> UInt32:
      return UInt32(self.off[HistoContainer.totbins() - 1])

    fn size(self, b : UInt32) -> UInt32:
      return UInt32(self.off[b + 1] - self.off[b])

    fn begin(self) -> UnsafePointer[index_type]
      return UnsafePointer(to = self.bins[0])

    fn end(self) -> UnsafePointer[index_type]:
      return UnsafePointer(to = self.bins[size()])

    fn begin(self, b : UInt32) -> UnsafePointer[index_type]
      return UnsafePointer(to = self.bins[self.off[b]])

    fn end(self, b : UInt32) -> UnsafePointer[index_type]
      return UnsafePointer(to = self.bins[self.off[b + 1]])

alias OneToManyAssoc = HistoContainer[DType.uint32, _, _, I=_]