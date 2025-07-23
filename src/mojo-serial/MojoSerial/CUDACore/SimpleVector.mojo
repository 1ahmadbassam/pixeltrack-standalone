from memory import UnsafePointer

from MojoSerial.CUDACore.CudaCompat import CudaCompat
from MojoSerial.MojoBridge.DTypes import Typeable


@fieldwise_init
struct SimpleVector[T: Movable & Copyable, DT: StaticString](
    Copyable, Defaultable, Movable, Typeable
):
    var m_size: Int64
    var m_capacity: Int64
    var m_data: UnsafePointer[T]

    @always_inline
    fn __init__(out self):
        self.m_size = 0
        self.m_capacity = 0
        self.m_data = UnsafePointer[T]()

    @always_inline
    fn construct(mut self, capacity: Int64, data: UnsafePointer[T]):
        self.m_size = 0
        self.m_capacity = capacity
        self.m_data = data

    @always_inline
    fn push_back_unsafe(mut self, element: T) -> Int64:
        var previousSize = self.m_size
        self.m_size += 1

        if previousSize < self.m_capacity:
            self.m_data[previousSize] = element
            return previousSize
        else:
            self.m_size -= 1
            return -1

    @always_inline
    fn back(self) -> ref [self.m_data] T:
        if self.m_size > 0:
            return self.m_data[self.m_size - 1]
        return self.m_data[]

    fn push_back(self, element: T) -> Int64:
        var previousSize = CudaCompat.atomicAdd(
            UnsafePointer(to=self.m_size), 1
        )

        if previousSize < self.m_capacity:
            self.m_data[previousSize] = element
            return previousSize
        else:
            _ = CudaCompat.atomicSub(UnsafePointer(to=self.m_size), 1)
            return -1

    fn extend(self, size: Int64 = 1) -> Int64:
        var previousSize = CudaCompat.atomicAdd(
            UnsafePointer(to=self.m_size), size
        )
        if previousSize < self.m_capacity:
            return previousSize
        else:
            _ = CudaCompat.atomicSub(UnsafePointer(to=self.m_size), size)
            return -1

    fn shrink(self, size: Int64 = 1) -> Int64:
        var previousSize = CudaCompat.atomicSub(
            UnsafePointer(to=self.m_size), size
        )
        if previousSize >= size:
            return previousSize - size
        else:
            _ = CudaCompat.atomicAdd(UnsafePointer(to=self.m_size), size)
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
    fn reset(mut self):
        self.m_size = 0

    @always_inline
    fn size(self) -> Int64:
        return self.m_size

    @always_inline
    fn capacity(self) -> Int64:
        return self.m_capacity

    @always_inline
    fn data(self) -> UnsafePointer[T]:
        return self.m_data

    @always_inline
    fn resize(mut self, size: Int64):
        self.m_size = size

    @always_inline
    fn set_data(mut self, data: UnsafePointer[T]):
        self.m_data = data

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
