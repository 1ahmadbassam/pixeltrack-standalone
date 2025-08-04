from MojoSerial.Framework.ESPluginFactory import fwkEventSetupModule
from MojoSerial.Framework.PluginFactory import fwkModule

from MojoSerial.PluginTest1.IntESProducer import IntESProducer
from MojoSerial.PluginTest1.TestProducer import TestProducer


fn init():
    fwkEventSetupModule[IntESProducer]()
    fwkModule[TestProducer]()
