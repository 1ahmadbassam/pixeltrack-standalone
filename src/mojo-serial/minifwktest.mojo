from pathlib import Path

#from MojoSerial.PluginSiPixelClusterizer.SiPixelFedCablingMapGPUWrapperESProducer import SiPixelFedCablingMapGPUWrapperESProducer
from MojoSerial.Framework.ESPluginFactory import Registry
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.Framework.ESPluginFactory import ESPluginFactory,  fwkEventSetupModule
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
    var list: List[String] = ["MyStruct"]
    var evt = EventSetup()
    # fwkEventSetupModule needs to happen at runtime, bad
    var __ = fwkEventSetupModule[MyStruct]()
    for plugin in list:
        var esp = ESPluginFactory.create(plugin, "data")
        esp.produce(evt)
    pass
