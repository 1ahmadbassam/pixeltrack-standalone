from memory import UnsafePointer

from MojoSerial.Framework.Event import Event
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.Framework.ProductRegistry import ProductRegistry
from MojoSerial.Framework.PluginFactory import PluginFactory, EDProducerConcrete
from MojoSerial.MojoBridge.DTypes import Typeable
from MojoSerial.Bin.Source import Source


struct StreamSchedule(Movable, Defaultable, Typeable):
    var _registry: UnsafePointer[ProductRegistry]
    var _source: UnsafePointer[Source]
    var _eventSetup: UnsafePointer[EventSetup]
    var _path: List[EDProducerConcrete]
    var _streamId: Int32

    @always_inline
    fn __init__(out self):
        self._registry = UnsafePointer[ProductRegistry]()
        self._source = UnsafePointer[Source]()
        self._eventSetup = UnsafePointer[EventSetup]()
        self._path = []
        self._streamId = 0

    fn __init__(
        out self,
        reg: UnsafePointer[ProductRegistry],
        source: UnsafePointer[Source],
        eventSetup: UnsafePointer[EventSetup],
        streamId: Int32 = 0,
    ):
        try:
            self._registry = reg
            self._source = source
            self._eventSetup = eventSetup
            self._path = List[EDProducerConcrete](capacity=PluginFactory.size())
            self._streamId = streamId
            for plugin in PluginFactory.getAll():
                self._path.append(
                    PluginFactory.create(plugin, self._registry[])
                )
        except e:
            print("Error in StreamSchedule.mojo,", e)
            return Self()

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self._registry = other._registry
        self._source = other._source
        self._eventSetup = other._eventSetup
        self._path = other._path^
        self._streamId = other._streamId

    fn run(mut self):
        var event: Event
        var ptr = self._source[].produce(self._streamId, self._registry[])
        while ptr != UnsafePointer[Event]():
            event = ptr.take_pointee()
            ptr.free()
            for i in range(self._path.__len__()):
                self._path[i].produce(event, self._eventSetup[])
            ptr = self._source[].produce(self._streamId, self._registry[])

    fn endJob(mut self):
        for i in range(self._path.__len__()):
            self._path[i].endJob()

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "StreamSchedule"
