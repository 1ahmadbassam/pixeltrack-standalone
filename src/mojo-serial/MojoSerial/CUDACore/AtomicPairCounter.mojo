from memory import bitcast

from MojoSerial.MojoBridge.DTypes import Typeable


@fieldwise_init
@register_passable("trivial")
struct Counters(Copyable, Movable, Typeable):
    var c: SIMD[DType.uint32, 2]
    # alias n: UInt32 = c[0] # in a "One to Many" association is the number of "One"
    # alias m: UInt32 = c[1] # in a "One to Many" association is the total number of associations
    # alias ac: UInt64 = bitcast[DType.uint64, 1](c)

    fn get_ac(self) -> UInt64:
        return bitcast[DType.uint64, 1](self.c)

    fn set_ac(mut self, owned ac: UInt64):
        self.c = bitcast[DType.uint32, 2](ac)

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "Counters"


@fieldwise_init
@register_passable("trivial")
struct AtomicPairCounter(Copyable, Defaultable, Movable, Typeable):
    var counter: Counters
    alias CounterType = UInt64
    alias _Z = SIMD[DType.uint32, 2](0, 0)
    alias _incr: UInt64 = 1 << 32

    fn __init__(out self):
        self.counter = Counters(Self._Z)

    fn __init__(out self, i: Self.CounterType):
        self = Self()
        self.counter.set_ac(i)

    fn get(self) -> Counters:
        return self.counter

    @always_inline
    fn add(mut self, i: UInt32) -> Counters:
        self.counter.set_ac(Self._incr + i.cast[DType.uint64]())
        return self.counter

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "AtomicPairCounter"
