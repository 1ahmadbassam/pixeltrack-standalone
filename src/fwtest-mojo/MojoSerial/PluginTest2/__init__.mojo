from MojoSerial.Framework.PluginFactory import fwkModule

from MojoSerial.PluginTest2.TestProducer2 import TestProducer2
from MojoSerial.PluginTest2.TestProducer3 import TestProducer3


fn init():
    fwkModule[TestProducer2]()
    fwkModule[TestProducer3]()
