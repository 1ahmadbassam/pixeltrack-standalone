from memory import UnsafePointer

struct SimpleVector[T: Movable & Copyable](Movable, Copyable, Defaultable):
    var m_size: Int
    var m_capacity: Int
    
    var m_data: UnsafePointer[T]
    alias nullptr = UnsafePointer[T]()

    @always_inline
    fn __init__(out self):
        self.m_size = 0
        self.m_capacity = 0
        self.m_data = Self.nullptr

    @always_inline
    fn construct(mut self, capacity: Int, data: UnsafePointer[T]):
        self.m_size = 0
        self.m_capacity = capacity
        self.m_data = data

    @always_inline
    fn empty(self) -> Bool:
        return self.m_size <= 0

    @always_inline
    fn capacity(self) -> Int:
        return self.m_capacity

    # TODO: Replace this stub

fn make_SimpleVector[T: Movable & Copyable](capacity: Int, data: UnsafePointer[T]) -> SimpleVector[T]:
    var ret = SimpleVector[T]()
    ret.construct(capacity, data)
    return ret

fn make_SimpleVector[T: Movable & Copyable](mut mem: UnsafePointer[SimpleVector[T]], capacity: Int, data: UnsafePointer[T]) -> ref [mem[]]SimpleVector[T]:
    # construct a new object where mem points, assuming it is initialized
    mem.init_pointee_move(SimpleVector[T]())
    mem[].construct(capacity, data)
    return mem[]