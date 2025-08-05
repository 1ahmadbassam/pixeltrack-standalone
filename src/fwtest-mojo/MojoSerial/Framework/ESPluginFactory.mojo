from collections.dict import _DictKeyIter
from pathlib import Path
from memory import UnsafePointer

from MojoSerial.Framework.ESProducer import ESProducer
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.MojoBridge.DTypes import Typeable


@fieldwise_init
struct ESProducerWrapper(Copyable, Defaultable, Movable, Typeable):
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
        return "ESProducerWrapper"


struct ESProducerWrapperT[T: Typeable & ESProducer](Movable, Typeable):
    var _ptr: UnsafePointer[T]

    @always_inline
    fn __init__(out self, owned path: Path):
        self._ptr = UnsafePointer[T].alloc(1)
        __get_address_as_uninit_lvalue(self._ptr.address) = T.__init__(path)

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self._ptr = other._ptr

    @always_inline
    fn delete(self):
        self._ptr.destroy_pointee()
        self._ptr.free()

    @always_inline
    fn producer(self) -> UnsafePointer[T]:
        return self._ptr

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "ESProducerWrapperT[" + T.dtype() + "]"


struct ESProducerConcrete(Copyable, Movable, Typeable):
    alias _C = fn (owned Path) -> ESProducerWrapper
    alias _P = fn (mut ESProducerWrapper, mut EventSetup)
    alias _D = fn (ESProducerWrapper)
    var _producer: ESProducerWrapper
    var _create: Self._C
    var _produce: Self._P
    var _det: Self._D

    @always_inline
    fn __init__(out self, create: Self._C, produce: Self._P, det: Self._D):
        self._producer = ESProducerWrapper()
        self._create = create
        self._produce = produce
        self._det = det

    @always_inline
    fn __copyinit__(out self, other: Self):
        self._producer = other._producer
        self._create = other._create
        self._produce = other._produce
        self._det = other._det

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self._producer = other._producer^
        self._create = other._create
        self._produce = other._produce
        self._det = other._det

    @always_inline
    fn delete(self):
        self._det(self._producer)

    @always_inline
    fn create(mut self, owned path: Path):
        self._producer = self._create(path^)

    @always_inline
    fn produce(mut self, mut eventSetup: EventSetup):
        self._produce(self._producer, eventSetup)

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "ESProducerConcrete"


struct Registry(Typeable):
    alias _pluginRegistryType = Dict[String, ESProducerConcrete]
    var _pluginRegistry: Self._pluginRegistryType

    @always_inline
    fn __init__(out self):
        self._pluginRegistry = {}

    @always_inline
    fn __del__(owned self):
        self.delete()

    @always_inline
    fn __getitem__(self, owned name: String) raises -> ESProducerConcrete:
        return self._pluginRegistry[name^]

    @always_inline
    fn __setitem__(
        mut self, owned name: String, owned esproducer: ESProducerConcrete
    ) raises:
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
struct ESPluginFactory:
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
    fn size() -> Int:
        return __registry._pluginRegistry.__len__()

    @staticmethod
    @always_inline
    fn create(
        owned name: String, owned path: Path
    ) raises -> ref [__registry] ESProducerConcrete:
        __registry[name].create(path^)
        return __registry[name^]


@always_inline
fn fwkEventSetupModule[T: Typeable & ESProducer]():
    @always_inline
    fn create_templ[
        T: Typeable & ESProducer
    ](owned path: Path) -> ESProducerWrapper:
        return rebind[ESProducerWrapper](ESProducerWrapperT[T](path^))

    @always_inline
    fn produce_templ[
        T: Typeable & ESProducer
    ](mut esproducer: ESProducerWrapper, mut eventSetup: EventSetup):
        rebind[ESProducerWrapperT[T]](esproducer).producer()[].produce(
            eventSetup
        )

    @always_inline
    fn det_templ[T: Typeable & ESProducer](esproducer: ESProducerWrapper):
        rebind[ESProducerWrapperT[T]](esproducer).delete()

    var crp = ESProducerConcrete(
        create_templ[T], produce_templ[T], det_templ[T]
    )
    try:
        __registry[T.dtype()] = crp^
    except e:
        print(
            "Framework/ESPluginFactory.mojo, failed to register plugin ",
            T.dtype(),
            ", got error: ",
            e,
            sep="",
        )
