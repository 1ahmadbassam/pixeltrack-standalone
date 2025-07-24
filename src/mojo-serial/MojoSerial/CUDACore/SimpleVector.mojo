from memory import UnsafePointer

from MojoSerial.CUDACore.CUDACompat import CUDACompat
from MojoSerial.MojoBridge.DTypes import Typeable


@fieldwise_init
struct SimpleVector[T: Movable & Copyable, DT: StaticString](
    Copyable, Defaultable, Movable, Sized, Typeable
):
    var m_size: Int
    var m_capacity: Int
    var m_data: UnsafePointer[T]

    @always_inline
    fn __init__(out self):
        self.m_size = 0
        self.m_capacity = 0
        self.m_data = UnsafePointer[T]()

    @always_inline
    fn construct(mut self, capacity: Int, data: UnsafePointer[T]):
        self.m_size = 0
        self.m_capacity = capacity
        self.m_data = data

    @always_inline
    fn push_back_unsafe(mut self, element: T) -> Int:
        var previousSize = self.m_size
        self.m_size += 1

        if previousSize < self.m_capacity:
            self.m_data[previousSize] = element
            return previousSize
        else:
            self.m_size -= 1
            return -1

    @always_inline
    fn back(ref self) -> ref [self.m_data] T:
        if self.m_size > 0:
            return self.m_data[self.m_size - 1]
        return self.m_data[]  # undefined behavior

    fn push_back(mut self, element: T) -> Int:
        var previousSize = self.m_size
        self.m_size += 1

        if previousSize < self.m_capacity:
            self.m_data[previousSize] = element
            return previousSize
        else:
            self.m_size -= 1
            return -1

    fn extend(mut self, size: Int = 1) -> Int:
        var previousSize = self.m_size
        self.m_size += size

        if previousSize < self.m_capacity:
            return previousSize
        else:
            self.m_size -= 1
            return -1

    fn shrink(mut self, size: Int = 1) -> Int:
        var previousSize = self.m_size
        self.m_size -= size

        if previousSize >= size:
            return previousSize - size
        else:
            self.m_size += size
            return -1

    @always_inline
    fn empty(self) -> Bool:
        return self.m_size <= 0

    @always_inline
    fn full(self) -> Bool:
        return self.m_capacity <= self.m_size

    @always_inline
    fn __getitem__(ref self, i: Int) -> ref [self.m_data] T:
        return self.m_data[i]

    @always_inline
    fn __setitem__(mut self, i: Int, val: T):
        self.m_data[i] = val

    @always_inline
    fn reset(mut self):
        self.m_size = 0

    @always_inline
    fn capacity(self) -> Int:
        return self.m_capacity

    @always_inline
    fn data(self) -> UnsafePointer[T, mut=False]:
        return self.m_data

    @always_inline
    fn resize(mut self, size: Int):
        self.m_size = size

    @always_inline
    fn set_data(mut self, data: UnsafePointer[T]):
        self.m_data = data

    @always_inline
    fn __len__(self) -> Int:
        return self.m_size

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "SimpleVector[" + DT + "]"


fn make_SimpleVector[
    T: Movable & Copyable, DT: StaticString
](capacity: Int, data: UnsafePointer[T]) -> SimpleVector[T, DT]:
    var ret = SimpleVector[T, DT]()
    ret.construct(capacity, data)
    return ret


fn make_SimpleVector[
    T: Movable & Copyable, DT: StaticString, //
](
    mut mem: UnsafePointer[SimpleVector[T, DT]],
    capacity: Int,
    data: UnsafePointer[T],
) -> ref [mem[]] SimpleVector[T, DT]:
    # construct a new object where mem points, assuming it is initialized
    mem.init_pointee_move(SimpleVector[T, DT]())
    mem[].construct(capacity, data)
    return mem[]
