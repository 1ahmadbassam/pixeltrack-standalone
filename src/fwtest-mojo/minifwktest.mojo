from pathlib import Path

from MojoSerial.PluginSiPixelClusterizer.SiPixelFedCablingMapGPUWrapperESProducer import SiPixelFedCablingMapGPUWrapperESProducer
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.Framework.ESPluginFactory import ESPluginFactory
from MojoSerial.Framework.PluginFactory import PluginFactory
from MojoSerial.Framework.ESProducer import ESProducer
from MojoSerial.MojoBridge.DTypes import Typeable

struct MyStruct(Defaultable, ESProducer, Movable, Typeable):
    var x: Int
    fn __init__(out self):
        self.x = 3
        print("MyStruct::__init__ called")
    fn __init__(out self, owned path: Path):
        self.x = 3
        print("MyStruct::__init__(path) called")
    fn produce(mut self, mut eventSetup: EventSetup):
        print("MyStruct::produce called (self.x == 3)")
    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "MyStruct"

def main():
    MojoSerial.PluginSiPixelClusterizer.init()
    var evt = EventSetup()

    for plugin in ESPluginFactory.getAll():
        var esp = ESPluginFactory.create(plugin, "data")
        esp.produce(evt)

    for plugin in PluginFactory.getAll():
        print(plugin)
