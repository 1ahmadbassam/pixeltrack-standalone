import MojoSerial.CUDACore.CudaStdAlgorithm as CudaStdAlgorithm
from MojoSerial.CUDACore.AtomicPairCounter import AtomicPairCounter
from MojoSerial.CUDACore.PrefixScan import blockPrefixScan
from MojoSerial.MojoBridge.DTypes import Typeable
from sys.info import sizeof
from memory import UnsafePointer

fn countFromVector[T: DType](mut h : HistoContainer[T,*_], nh : UInt32, v : UnsafePointer[Scalar[T]], mut offsets : UnsafePointer[UInt32]):
    for i in range(offsets[nh]):
        var off = CudaStdAlgorithm.upper_bound(offsets, offsets + nh + 1, i)

        debug_assert(off[] > 0)
        var ih : UInt32 = (Int(off) - Int(offsets))//sizeof[UInt32]() - 1

        debug_assert(ih >= 0)
        debug_assert(ih < Int(nh))
        h.count(v[i], ih)

fn fillFromVector[T: DType](mut h : HistoContainer[T, *_], nh : UInt32, v : UnsafePointer[Scalar[T]], mut offsets : UnsafePointer[UInt32]):
    for i in range(offsets[nh]):
        var off = CudaStdAlgorithm.upper_bound(offsets, offsets + nh + 1, i)

        debug_assert(off[] > 0)
        var ih : UInt32 = (Int(off) - Int(offsets))//sizeof[UInt32]() - 1

        debug_assert(ih >= 0)
        debug_assert(ih < Int(nh))
        h.fill(v[i], Scalar[h.index_type](i), ih)

@always_inline
fn launchZero(mut h : HistoContainer):
    var poff = UnsafePointer[mut = True](to = h.off)

    for i in range(len(h.off)):
      poff[][i] = 0
    h.psws = 0

@always_inline
fn launchFinalize(mut h : HistoContainer[*_]):
    h.finalize()

@always_inline
fn fillManyFromVector[T : DType](mut h : HistoContainer[T, *_], nh : UInt32, v : UnsafePointer[Scalar[T]],
                                 mut offsets : UnsafePointer[UInt32], totSize : UInt32):
  launchZero(h)
  countFromVector(h, nh, v, offsets)
  h.finalize()
  fillFromVector(h, nh, v, offsets)

fn finalizeBulk(apc : UnsafePointer[AtomicPairCounter], mut assoc : HistoContainer[*_]):
  assoc.bulkFinalizeFill(apc[])

fn forEachInBins[V : DType](ref hist : HistoContainer[V, *_], value : Scalar[V], n : Int, func : fn(Scalar[hist.index_type])):
  var bs : Int = Int(hist.bin(value))
  var be : Int = min(Int(hist.nbins()) - 1, bs + n)
  bs = max(0, bs - n)
  debug_assert(be >= bs)

  pj = hist.begin(bs)
  while pj < hist.end(be):
    func(pj[])
    pj += 1

fn forEachInWindow[V : DType](ref hist : HistoContainer[V, *_], wmin : Scalar[V], wmax : Scalar[V], func : fn(Scalar[hist.index_type])):
  bs : Int = Int(hist.bin(wmin))
  be : Int = Int(hist.bin(wmax))
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
    alias CountersOnly = HistoContainer[T, NBINS, 0, S, I, NHISTS]
    alias index_type = I

    var off : InlineArray[UInt32, Int(Self.totbins())]
    var psws : UInt32
    var bins : InlineArray[Scalar[Self.index_type], Int(Self.capacity())]

    fn __init__(out self):
      self.off = InlineArray[UInt32, Int(Self.totbins())](0)
      self.psws = 0
      self.bins = InlineArray[Scalar[Self.index_type], Int(Self.capacity())](0)

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "HistoContainer[" + T.__repr__() + ", " + String(NBINS) + ", " + String(SIZE) + ", " + String(S) + ", " + I.__repr__() + ", " + String(NHISTS) + "]"

    @staticmethod
    fn ilog2(v_in : UInt32) -> UInt32:
      var v = v_in
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
    fn nbits() -> UInt32:
      return Self.ilog2(NBINS - 1) + 1

    @staticmethod
    fn capacity() -> UInt32:
      return SIZE

    @staticmethod
    fn histOff(nh : UInt32) -> UInt32:
      return NBINS * nh

    @staticmethod
    fn bin(t : Scalar[T]) -> UInt32:
      var shift : UInt32 = Self.sizeT() - Self.nbits()
      var mask : UInt32 = (1 << Self.nbits()) - 1
      return (UInt32(t) >> shift) & mask

    fn zero(mut self):
      for i in range(len(self.off)):
        self.off[i] = 0

    @always_inline
    fn add(mut self, ref co : Self.CountersOnly):
      for i in range(Self.totbins()):
        self.off[i] += co.off[i]

    @always_inline
    @staticmethod
    fn atomicIncrement(mut x : UInt32) -> UInt32:
      x += 1
      return x

    @always_inline
    @staticmethod
    fn atomicDecrement(mut x : UInt32) -> UInt32:
      x -= 1
      return x

    @always_inline
    fn countDirect(mut self, b : Scalar[T]):
      debug_assert(UInt32(b) < Self.nbins())
      self.off[b] = Self.atomicIncrement(self.off[b])

    @always_inline
    fn fillDirect(mut self, b : Scalar[T], j : Scalar[Self.index_type]):
      debug_assert(UInt32(b) < Self.nbins())
      var w = Self.atomicDecrement(self.off[b])
      debug_assert(w > 0)
      self.bins[w - 1] = j

    @always_inline
    fn bulkFill(mut self, mut apc : AtomicPairCounter, v : UnsafePointer[Scalar[Self.index_type]], n : UInt32) -> Int32:
      var c = apc.add(n)
      if (c[1] >= Self.nbins()):
        return -Int32(c[1])

      self.off[c[1]] = c[0]
      for i in range(n):
        self.bins[c[0] + i] = v[i]

      return Int32(c[1])

    @always_inline
    fn bulkFinalize(mut self, mut apc : AtomicPairCounter):
      self.off[apc.get()[1]] = apc.get()[0]

    @always_inline
    fn bulkFinalizeFill(mut self, mut apc : AtomicPairCounter):
      var m = apc.get()[1]
      var n = apc.get()[0]

      if (m >= Self.nbins()):
        self.off[Self.nbins()] = UInt32(self.off[Self.nbins() - 1])
        return

      for i in range(m, Self.totbins()):
        self.off[i] = n

    @always_inline
    fn count(mut self, t : Scalar[T]):
      var b : UInt32 = Self.bin(t)
      debug_assert(b < Self.nbins())
      self.off[b] = Self.atomicIncrement(self.off[b])

    @always_inline
    fn fill(mut self, t : Scalar[T], j : Scalar[Self.index_type]):
      var b : UInt32 = Self.bin(t)
      debug_assert(b < Self.nbins())
      var w = Self.atomicDecrement(self.off[b])

      debug_assert(w > 0)
      self.bins[w - 1] = j

    @always_inline
    fn count(mut self, t : Scalar[T], nh : UInt32):
      var b : UInt32 = Self.bin(t)
      debug_assert(b < Self.nbins())
      b += Self.histOff(nh)

      debug_assert(b < Self.totbins())
      self.off[b] = Self.atomicIncrement(self.off[b])

    @always_inline
    fn fill(mut self, t : Scalar[T], j : Scalar[Self.index_type], nh : UInt32):
      var b : UInt32 = Self.bin(t)
      debug_assert(b < Self.nbins())
      b += Self.histOff(nh)

      debug_assert(b < Self.totbins())
      var w = Self.atomicIncrement(self.off[b])

      debug_assert(w > 0)
      self.bins[w - 1] = j

    @always_inline
    fn finalize(self):
      debug_assert(self.off[Self.totbins() - 1] == 0)
      blockPrefixScan(self.off.unsafe_ptr(), Int(Self.totbins()))
      debug_assert(self.off[Self.totbins() - 1] == self.off[Self.totbins() - 2])

    fn size(self) -> UInt32:
      return UInt32(self.off[Self.totbins() - 1])

    fn size(self, b : UInt32) -> UInt32:
      return UInt32(self.off[b + 1] - self.off[b])

    fn begin(self) -> UnsafePointer[Scalar[Self.index_type]]:
      return UnsafePointer(to = self.bins[0])

    fn end(self) -> UnsafePointer[Scalar[Self.index_type]]:
      return UnsafePointer(to = self.bins[Self.size(self)])

    fn begin(self, b : UInt32) -> UnsafePointer[Scalar[Self.index_type]]:
      return UnsafePointer(to = self.bins[self.off[b]])

    fn end(self, b : UInt32) -> UnsafePointer[Scalar[Self.index_type]]:
      return UnsafePointer(to = self.bins[self.off[b + 1]])

alias OneToManyAssoc = HistoContainer[DType.uint32, _, _, I=_]