from collections.dict import _DictKeyIter
from memory import UnsafePointer

from MojoSerial.Framework.EDProducer import EDProducer
from MojoSerial.Framework.Event import Event
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.Framework.ProductRegistry import ProductRegistry
from MojoSerial.MojoBridge.DTypes import Typeable


@fieldwise_init
struct EDProducerWrapper(Copyable, Defaultable, Movable, Typeable):
    var _ptr: UnsafePointer[NoneType]

    @always_inline
    fn __init__(out self):
        self._ptr = UnsafePointer[NoneType]()

    @always_inline
    fn producer(self) -> UnsafePointer[NoneType]:
        return self._ptr

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "EDProducerWrapper"


struct EDProducerWrapperT[T: Typeable & Movable & EDProducer](
    Movable, Typeable
):
    var _ptr: UnsafePointer[T]

    @always_inline
    fn __init__(out self, owned obj: T):
        self._ptr = UnsafePointer[T].alloc(1)
        self._ptr.init_pointee_move(obj^)

    @always_inline
    fn delete(self):
        self._ptr.destroy_pointee()
        self._ptr.free()

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self._ptr = other._ptr

    @always_inline
    fn producer(self) -> UnsafePointer[T]:
        return self._ptr

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "EDProducerWrapperT[" + T.dtype() + "]"


struct EDProducerConcrete(Copyable, Movable, Typeable):
    alias _C = fn (mut ProductRegistry) raises -> EDProducerWrapper
    alias _P = fn (mut EDProducerWrapper, mut Event, EventSetup)
    alias _E = fn (mut EDProducerWrapper)
    alias _D = fn (EDProducerWrapper)
    var _producer: EDProducerWrapper
    var _create: Self._C
    var _produce: Self._P
    var _end: Self._E
    var _det: Self._D

    @always_inline
    fn __init__(out self, create: Self._C, produce: Self._P, end: Self._E, det: Self._D):
        self._producer = EDProducerWrapper()
        self._create = create
        self._produce = produce
        self._end = end
        self._det = det

    @always_inline
    fn __copyinit__(out self, other: Self):
        self._producer = other._producer
        self._create = other._create
        self._produce = other._produce
        self._end = other._end
        self._det = other._det

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self._producer = other._producer^
        self._create = other._create
        self._produce = other._produce
        self._end = other._end
        self._det = other._det

    @always_inline
    fn create(mut self, mut reg: ProductRegistry) raises:
        self._producer = self._create(reg)

    @always_inline
    fn produce(mut self, mut event: Event, ref eventSetup: EventSetup):
        self._produce(self._producer, event, eventSetup)

    @always_inline
    fn endJob(mut self):
        self._end(self._producer)

    @always_inline
    fn delete(self):
        self._det(self._producer)

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "EDProducerConcrete"


struct Registry(Typeable):
    alias _pluginRegistryType = Dict[String, EDProducerConcrete]
    var _pluginRegistry: Self._pluginRegistryType

    @always_inline
    fn __init__(out self):
        self._pluginRegistry = {}

    @always_inline
    fn __del__(owned self):
        self.delete()

    @always_inline
    fn __getitem__(self, owned name: String) raises -> EDProducerConcrete:
        return self._pluginRegistry[name^]

    @always_inline
    fn __setitem__(
        mut self, owned name: String, owned esproducer: EDProducerConcrete
    ) raises:
        if name in self._pluginRegistry:
            raise Error("Plugin " + name + " is already registered.")
        self._pluginRegistry[name^] = esproducer^

    @always_inline
    fn delete(self):
        for i in range(self._pluginRegistry._entries.__len__()):
            if self._pluginRegistry._entries[i]:
                self._pluginRegistry._entries[i].unsafe_value().value.delete()

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "Registry"


var __registry: Registry = Registry()


@nonmaterializable(NoneType)
struct PluginFactory:
    @staticmethod
    @always_inline
    fn getAll() -> (
        _DictKeyIter[
            Registry._pluginRegistryType.K,
            Registry._pluginRegistryType.V,
            __origin_of(__registry._pluginRegistry),
        ]
    ):
        return __registry._pluginRegistry.keys()
    @staticmethod
    @always_inline
    fn create(
        owned name: String, mut reg: ProductRegistry
    ) raises -> ref [__registry] EDProducerConcrete:
        __registry[name].create(reg)
        return __registry[name^]


@always_inline
fn fwkModule[T: Typeable & Movable & EDProducer]():
    @always_inline
    fn create_templ[
        T: Typeable & Movable & EDProducer
    ](mut reg: ProductRegistry) raises -> EDProducerWrapper:
        var obj: T = T.__init__(reg)
        var wrapper = EDProducerWrapperT[T](obj^)
        return rebind[EDProducerWrapper](wrapper^)

    @always_inline
    fn produce_templ[
        T: Typeable & Movable & EDProducer
    ](
        mut edproducer: EDProducerWrapper,
        mut event: Event,
        eventSetup: EventSetup,
    ):
        rebind[EDProducerWrapperT[T]](edproducer).producer()[].produce(
            event, eventSetup
        )

    @always_inline
    fn end_templ[
        T: Typeable & Movable & EDProducer
    ](mut edproducer: EDProducerWrapper):
        rebind[EDProducerWrapperT[T]](edproducer).producer()[].endJob()

    @always_inline
    fn det_templ[
        T: Typeable & Movable & EDProducer
    ](edproducer: EDProducerWrapper):
        rebind[EDProducerWrapperT[T]](edproducer).delete()

    var crp = EDProducerConcrete(
        create_templ[T], produce_templ[T], end_templ[T], det_templ[T]
    )
    try:
        __registry[T.dtype()] = crp^
    except e:
        print(
            "Framework/EDPluginFactory.mojo, failed to register plugin ",
            T.dtype(),
            ", got error: ",
            e,
            sep="",
        )
