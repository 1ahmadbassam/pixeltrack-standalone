from MojoSerial.Framework.EDGetToken import EDGetTokenT
from MojoSerial.Framework.EDPutToken import EDPutTokenT
from MojoSerial.Framework.ProductRegistry import ProductRegistry
from MojoSerial.MojoBridge.DTypes import Typeable

alias StreamID = Int


struct WrapperBase(Copyable, Defaultable, Movable, Typeable):
    var _ptr: UnsafePointer[NoneType]

    @always_inline
    fn __init__(out self):
        self._ptr = UnsafePointer[NoneType]()

    @always_inline
    fn __copyinit__(out self, other: Self):
        self._ptr = other._ptr

    @always_inline
    fn __moveinit__(out self, var other: Self):
        self._ptr = other._ptr

    @always_inline
    fn product(self) -> UnsafePointer[NoneType, mut=False]:
        return self._ptr

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "WrapperBase"


struct Wrapper[T: Typeable & Movable](Movable, Typeable):
    var _ptr: UnsafePointer[T]

    @always_inline
    fn __init__(out self, var obj: T):
        self._ptr = UnsafePointer[T].alloc(1)
        self._ptr.init_pointee_move(obj^)

    @always_inline
    fn __moveinit__(out self, var other: Self):
        self._ptr = other._ptr

    @always_inline
    fn product(self) -> UnsafePointer[T, mut=False]:
        return self._ptr

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "Wrapper[" + T.dtype() + "]"


struct Event(Defaultable, Movable, Typeable):
    var _streamId: StreamID
    var _eventId: Int
    var _products: List[WrapperBase]

    @always_inline
    fn __init__(out self):
        self._streamId = 0
        self._eventId = 0
        self._products = []

    @always_inline
    fn __init__(
        out self,
        var streamId: Int,
        var eventId: Int,
        ref reg: ProductRegistry,
    ):
        self._streamId = streamId
        self._eventId = eventId
        self._products = List[WrapperBase](capacity=reg.__len__())

    @always_inline
    fn __moveinit__(out self, var other: Self):
        self._streamId = other._streamId
        self._eventId = other._eventId
        self._products = other._products

    @always_inline
    fn streamID(self) -> StreamID:
        return self._streamId

    @always_inline
    fn eventID(self) -> Int:
        return self._eventId

    fn get[
        T: Typeable & Movable
    ](self, ref token: EDGetTokenT[T]) -> ref [self._products] T:
        return rebind[Wrapper[T]](self._products[token.index()]).product()[]

    # emplace is not possible due to failure in binding the constructor at compile time, so we provide put instead

    fn put[
        T: Typeable & Movable
    ](mut self, ref token: EDPutTokenT[T], var prod: T):
        self._products[token.index()] = rebind[WrapperBase](Wrapper[T](prod^))

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "Event"
