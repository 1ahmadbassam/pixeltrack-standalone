from pathlib import Path

from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.Framework.ESPluginFactory import ESPluginFactory
from MojoSerial.Framework.PluginFactory import PluginFactory
from MojoSerial.Framework.ESProducer import ESProducer
from MojoSerial.MojoBridge.DTypes import Typeable


def main():
    MojoSerial.PluginTest1.init()
    MojoSerial.PluginTest2.init()
    var evt = EventSetup()

    for plugin in ESPluginFactory.getAll():
        var esp = ESPluginFactory.create(plugin, "data")
        esp.produce(evt)

    for plugin in PluginFactory.getAll():
        print(plugin)
