from pathlib import Path

from MojoSerial.Framework.ESProducer import ESProducer
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.MojoBridge.DTypes import Typeable, TypeableInt


struct IntESProducer(Defaultable, ESProducer, Movable, Typeable):
    fn __init__(out self):
        pass

    fn __moveinit__(out self, owned other: Self):
        pass

    fn __init__(out self, owned path: Path):
        pass

    fn produce(mut self, mut eventSetup: EventSetup):
        try:
            eventSetup.put[TypeableInt](TypeableInt(42))
        except e:
            print("Error occurred in PluginTest1/IntESProducer.mojo, ", e)

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "IntESProducer"
