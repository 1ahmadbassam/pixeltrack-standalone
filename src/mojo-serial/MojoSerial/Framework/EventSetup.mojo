from memory import UnsafePointer

from MojoSerial.MojoBridge.DTypes import Typeable


struct ESWrapperBase(Copyable, Defaultable, Movable, Typeable):
    var _ptr: UnsafePointer[NoneType]

    @always_inline
    fn __init__(out self):
        self._ptr = UnsafePointer[NoneType]()

    @always_inline
    fn __del__(owned self):
        if self._ptr != UnsafePointer[NoneType]():
            self._ptr.destroy_pointee()
            self._ptr.free()

    @always_inline
    fn product(self) -> UnsafePointer[NoneType]:
        return self._ptr

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "ESWrapperBase"


struct ESWrapper[T: Typeable & Movable](Movable, Typeable):
    var _ptr: UnsafePointer[T]

    @always_inline
    fn __init__(out self, owned obj: T):
        self._ptr = UnsafePointer[T].alloc(1)
        self._ptr.init_pointee_move(obj^)

    @always_inline
    fn __del__(owned self):
        self._ptr.destroy_pointee()
        self._ptr.free()

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self._ptr = other._ptr

    @always_inline
    fn product(self) -> UnsafePointer[T]:
        return self._ptr

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "ESWrapper[" + T.dtype() + ']'


struct EventSetup(Defaultable, Movable, Typeable):
    var _typeToProduct: Dict[String, ESWrapperBase]

    @always_inline
    fn __init__(out self):
        self._typeToProduct = Dict[String, ESWrapperBase]()

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self._typeToProduct = other._typeToProduct^

    fn put[T: Typeable & Movable](mut self, owned prod: T) raises:
        if T.dtype() in self._typeToProduct:
            raise "RuntimeError: Product of type " + T.dtype() + " already exists."
        self._typeToProduct[T.dtype()] = rebind[ESWrapperBase](
            ESWrapper[T](prod^)
        )

    fn get[T: Typeable & Movable](self) raises -> ref [self._typeToProduct] T:
        if T.dtype() not in self._typeToProduct:
            raise "RuntimeError: Product of type " + T.dtype() + " is not produced."
        return rebind[ESWrapper[T]](self._typeToProduct[T.dtype()]).product()[]

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "EventSetup"
