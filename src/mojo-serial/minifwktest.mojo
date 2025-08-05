from pathlib import Path

from MojoSerial.PluginSiPixelClusterizer.SiPixelFedCablingMapGPUWrapperESProducer import SiPixelFedCablingMapGPUWrapperESProducer
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.Framework.ESPluginFactory import ESPluginFactory
from MojoSerial.Framework.PluginFactory import PluginFactory
from MojoSerial.Framework.ESProducer import ESProducer
from MojoSerial.MojoBridge.DTypes import Typeable

fn main() raises:
    MojoSerial.PluginSiPixelClusterizer.init()
    var evt = EventSetup()

    for plugin in ESPluginFactory.getAll():
        var esp = ESPluginFactory.create(plugin, "data")
        esp.produce(evt)

    for plugin in PluginFactory.getAll():
        print(plugin)
