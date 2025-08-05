from pathlib import Path

from MojoSerial.Framework.ProductRegistry import ProductRegistry
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.MojoBridge.DTypes import Typeable
from MojoSerial.Bin.Source import Source
from MojoSerial.Bin.StreamSchedule import StreamSchedule

struct EventProcessor(Typeable):
    # no pluginmanager
    var _registry: ProductRegistry
    var _source: Source
    var _eventSetup: EventSetup
    var _schedule: StreamSchedule
    var _warmupEvents: Int32
    var _maxEvents: Int32
    # no timing information

    fn __init__(out self, owned warmupEvents: Int, owned maxEvents: Int, owned path: Path, owned validation: Bool):
        self._registry = ProductRegistry()
        self._source = Source(maxEvents, self._registry, path, validation)


    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "EventProcessor"
